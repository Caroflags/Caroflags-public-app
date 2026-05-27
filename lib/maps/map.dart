import 'package:caroflags/attractionviewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart'
    hide TileLayer, Theme;

import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../gzipped_tile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../locations/restrooms.dart';
import '../locations/resturants.dart';
import '../locations/shops.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  Style? _style;
  String? _styleError;

  LatLng? userLocation;
  AnimationController? _locationAnimController;
  Animation<double>? _latAnimation;
  Animation<double>? _lngAnimation;
  final MapController mapController = MapController();

  // Filter settings
  bool _showRides = true;
  bool _showRestrooms = false;
  bool _showFood = false;
  bool _showShops = false;

  int? selectedRideIndex;
  StreamSubscription<Position>? _positionStreamSubscription;

  LatLng? parkingLocation;
  String? parkingTime;
  bool _showParkingBubble = false;

  Future<void> _loadParking() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('parking_lat');
    final lng = prefs.getDouble('parking_lng');
    final time = prefs.getString('parking_time');

    if (lat != null && lng != null && time != null) {
      setState(() {
        parkingLocation = LatLng(lat, lng);
        parkingTime = time;
      });
    }
  }

  void _saveParking() async {
    if (userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot find your location. Make sure location services are enabled.',
          ),
        ),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final timeString = DateTime.now().toIso8601String();
    await prefs.setDouble('parking_lat', userLocation!.latitude);
    await prefs.setDouble('parking_lng', userLocation!.longitude);
    await prefs.setString('parking_time', timeString);
    setState(() {
      parkingLocation = userLocation;
      parkingTime = timeString;
      _showParkingBubble = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Parking spot saved'),
          action: SnackBarAction(label: 'Undo', onPressed: _removeParking),
        ),
      );
    }
  }

  void _removeParking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('parking_lat');
    await prefs.remove('parking_lng');
    await prefs.remove('parking_time');
    setState(() {
      parkingLocation = null;
      parkingTime = null;
      _showParkingBubble = false;
    });
  }

  List<Map<String, dynamic>> rides = [];

  Future<void> _loadRides() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedRidesStr = prefs.getString('cached_rides');
    final cacheDateStr = prefs.getString('cached_rides_date');

    if (cachedRidesStr != null && cacheDateStr != null) {
      final cacheDate = DateTime.tryParse(cacheDateStr);
      if (cacheDate != null &&
          DateTime.now().difference(cacheDate).inDays < 30) {
        try {
          final List<dynamic> decodedCache = json.decode(cachedRidesStr);
          final List<Map<String, dynamic>> cachedRides = decodedCache
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          if (mounted) {
            setState(() {
              rides = cachedRides;
            });
          }
          return;
        } catch (e) {
          // ignore: avoid_print
          print('Error parsing cached rides: $e');
        }
      }
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.caroflags.xyz/allrides'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        final List<Map<String, dynamic>> fetchedRides = jsonResponse.map((
          ride,
        ) {
          final coords = ride['coordinates'] as Map<String, dynamic>? ?? {};
          return {
            'name': ride['name'] ?? 'Unknown Ride',
            'lat': coords['lat'] ?? 0.0,
            'lng': coords['lng'] ?? 0.0,
          };
        }).toList();

        if (mounted) {
          setState(() {
            rides = fetchedRides;
          });
        }

        await prefs.setString('cached_rides', json.encode(fetchedRides));
        await prefs.setString(
          'cached_rides_date',
          DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching rides: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadFilters();
    _loadStyle();
    _loadParking();
    _loadRides();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location is turned off, so you wont be able to see where you are.',
              ),
            ),
          );
        }
        return;
      }
    } else if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location is permanently turned off, so you wont be able to see where you are.',
            ),
          ),
        );
      }
      return;
    }

    _startLocationTracking();
  }

  void _startLocationTracking() {
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 1,
          ),
        ).listen((Position position) {
          if (mounted) {
            _animateToNewLocation(
              LatLng(position.latitude, position.longitude),
            );
          }
        });
  }

  void _animateToNewLocation(LatLng newLocation) {
    if (userLocation == null) {
      setState(() {
        userLocation = newLocation;
      });
      return;
    }

    _locationAnimController?.dispose();
    _locationAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _latAnimation =
        Tween<double>(
          begin: userLocation!.latitude,
          end: newLocation.latitude,
        ).animate(
          CurvedAnimation(
            parent: _locationAnimController!,
            curve: Curves.linear,
          ),
        );

    _lngAnimation =
        Tween<double>(
          begin: userLocation!.longitude,
          end: newLocation.longitude,
        ).animate(
          CurvedAnimation(
            parent: _locationAnimController!,
            curve: Curves.linear,
          ),
        );

    _locationAnimController!.addListener(() {
      if (mounted) {
        setState(() {
          userLocation = LatLng(_latAnimation!.value, _lngAnimation!.value);
        });
      }
    });

    _locationAnimController!.forward();
  }

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showRides = prefs.getBool('showRides') ?? true;
      _showRestrooms = prefs.getBool('showRestrooms') ?? false;
      _showFood = prefs.getBool('showFood') ?? false;
      _showShops = prefs.getBool('showShops') ?? false;
    });
  }

  Future<void> _toggleFilter(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == 'showRides') _showRides = value;
      if (key == 'showRestrooms') _showRestrooms = value;
      if (key == 'showFood') _showFood = value;
      if (key == 'showShops') _showShops = value;
    });
  }

  void _loadStyle() async {
    const styleUrl = 'https://api.caroflags.xyz/style.json';
    try {
      // Fetch style manually to modify it
      final response = await http.get(Uri.parse(styleUrl));
      if (response.statusCode != 200) throw Exception('Failed to load style');

      final styleJson = json.decode(response.body);

      // Remove symbol layers to avoid fetching missing glyphs
      // (The style.json is missing the "glyphs" property)
      if (styleJson['layers'] != null) {
        styleJson['layers'] = (styleJson['layers'] as List).where((layer) {
          return layer['type'] != 'symbol';
        }).toList();
      }

      // Read the modified style
      // We use ThemeReader directly
      final theme = ThemeReader(logger: const Logger.console()).read(styleJson);

      // Create Style object manually
      _style = Style(
        theme: theme,
        providers: TileProviders({
          'osm': GzipNetworkVectorTileProvider(
            urlTemplate: 'https://api.caroflags.xyz/tiles/{z}/{x}/{y}.pbf',
            maximumZoom: 14,
          ),
        }),
      );
    } catch (e) {
      _styleError = e.toString();
      // ignore: avoid_print
      print('Error loading style: $e');
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _locationAnimController?.dispose();
    super.dispose();
  }

  // Fixed _updateRidePosition to directly update lat/lng without originalLat/lng or offsets
  void _updateRidePosition(int index, LatLng newPos) {
    setState(() {
      rides[index]['lat'] = newPos.latitude;
      rides[index]['lng'] = newPos.longitude;
    });

    // ignore: avoid_print
    print(
      '✅ ${rides[index]['name']} moved to: ${newPos.latitude}, ${newPos.longitude}',
    );
  }

  Future<void> _showRideDetails(
    BuildContext context,
    Map<String, dynamic> ride,
  ) async {
    final url = 'https://api.caroflags.xyz/ride/${ride['name']}';

    if (!context.mounted) return;

    Map<String, dynamic> rideData;
    try {
      final file = await DefaultCacheManager().getSingleFile(url);
      final jsonString = await file.readAsString();
      rideData = json.decode(jsonString);
    } catch (e) {
      rideData = {'name': 'Failed to load details: $e'};
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttractionViewer(response: rideData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If style is loading or failed
    if (_style == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carowinds Map')),
        body: Center(
          child: _styleError != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading map style:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_styleError!, textAlign: TextAlign.center),
                    ),
                    const Text('Please check your API key/URL in map.dart'),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Carowinds Map')),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: LatLng(35.1028, -80.9424),
          initialZoom: 16,
          minZoom: 5.0,
          maxZoom: 22.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          onTap: (tapPosition, latlng) {
            if (selectedRideIndex != null) {
              _updateRidePosition(selectedRideIndex!, latlng);
              selectedRideIndex = null;
            }
          },
        ),
        children: [
          // Vector Map Layer
          // Vector Map Layer
          VectorTileLayer(
            // Use custom provider mapping for 'osm' source
            tileProviders: TileProviders({
              'osm': GzipNetworkVectorTileProvider(
                urlTemplate:
                    'https://api.caroflags.xyz/tiles/{z}/{x}/{y}.pbf?t=${DateTime.now().millisecondsSinceEpoch}',
                maximumZoom: 14,
              ),
            }),
            theme: _style!.theme,
            sprites: _style!.sprites,
            maximumZoom: 22,
            tileOffset: TileOffset.mapbox,
            layerMode: VectorTileLayerMode.vector,
          ),
          // Existing Ride Markers
          MarkerLayer(
            markers: [
              if (parkingLocation != null)
                Marker(
                  point: parkingLocation!,
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      if (_showParkingBubble)
                        Positioned(
                          bottom: 110,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Builder(
                                  builder: (context) {
                                    String displayTime =
                                        'Parked at $parkingTime';
                                    if (parkingTime != null) {
                                      try {
                                        final parsedTime = DateTime.parse(
                                          parkingTime!,
                                        );
                                        displayTime =
                                            'Parked ${timeago.format(parsedTime, locale: 'en_short')} ago';
                                      } catch (e) {
                                        // Fallback if not an ISO string
                                      }
                                    }
                                    return Text(
                                      displayTime,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                ElevatedButton(
                                  onPressed: _removeParking,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    minimumSize: const Size(60, 30),
                                  ),
                                  child: const Text(
                                    'Remove',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showParkingBubble = !_showParkingBubble;
                          });
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.directions_car,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (userLocation != null)
                Marker(
                  point: userLocation!,
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 2),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_showRides)
                ...rides.asMap().entries.map((entry) {
                  var ride = entry.value;

                  return Marker(
                    point: LatLng(ride['lat'], ride['lng']),
                    width: 90,
                    height: 90,
                    child: GestureDetector(
                      onTap: () => _showRideDetails(context, ride),
                      child: SizedBox(
                        width: 90,
                        height: 90,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.attractions,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  ride['name'],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              if (_showRestrooms)
                ...restrooms.map((restroom) {
                  return Marker(
                    point: LatLng(restroom['lat'], restroom['lng']),
                    width: 90,
                    height: 90,
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.wc,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                restroom['name'],
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              if (_showFood)
                ...restaurants.map((place) {
                  return Marker(
                    point: LatLng(place['lat'], place['lng']),
                    width: 90,
                    height: 90,
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.yellow,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.restaurant,
                                color: Colors
                                    .black, // Dark icon for yellow background
                                size: 20,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                place['name'],
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              if (_showShops)
                ...shops.map((shop) {
                  return Marker(
                    point: LatLng(shop['lat'], shop['lng']),
                    width: 90,
                    height: 90,
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.shopping_bag,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                shop['name'],
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'parking_fab',
            onPressed: () => _saveParking(),
            child: const Icon(Icons.local_parking),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'filter_fab',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        title: const Text('Filter Map'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SwitchListTile(
                              title: const Text('Rides'),
                              value: _showRides,
                              onChanged: (val) {
                                setState(() => _showRides = val);
                                // Outer state update
                                this.setState(() => this._showRides = val);
                                _toggleFilter('showRides', val);
                              },
                            ),
                            SwitchListTile(
                              title: const Text('Restrooms'),
                              value: _showRestrooms,
                              onChanged: (val) {
                                setState(() => _showRestrooms = val);
                                // Outer state update
                                this.setState(() => this._showRestrooms = val);
                                _toggleFilter('showRestrooms', val);
                              },
                            ),
                            SwitchListTile(
                              title: const Text('Food'),
                              value: _showFood,
                              onChanged: (val) {
                                setState(() => _showFood = val);
                                // Outer state update
                                this.setState(() => this._showFood = val);
                                _toggleFilter('showFood', val);
                              },
                            ),
                            SwitchListTile(
                              title: const Text('Shops'),
                              value: _showShops,
                              onChanged: (val) {
                                setState(() => _showShops = val);
                                // Outer state update
                                this.setState(() => this._showShops = val);
                                _toggleFilter('showShops', val);
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
            child: const Icon(Icons.filter_list),
          ),
        ],
      ),
    );
  }
}
