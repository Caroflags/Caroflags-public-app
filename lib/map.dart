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
import 'gzipped_tile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

// Data Lists
final List<Map<String, dynamic>> restrooms = [
  {'name': 'Restroom', 'lat': 35.1043619, 'lng': -80.9476792},
  {'name': 'Restroom', 'lat': 35.1035138, 'lng': -80.9391063},
  {'name': 'Restroom', 'lat': 35.1037229, 'lng': -80.9425526},
  {'name': 'Restroom', 'lat': 35.1026034, 'lng': -80.9378982},
  {'name': 'Restroom', 'lat': 35.1008116, 'lng': -80.9404345},
  {'name': 'Restroom', 'lat': 35.1017612, 'lng': -80.9450256},
  {'name': 'Restroom', 'lat': 35.1015101, 'lng': -80.9463152},
  {'name': 'Restroom', 'lat': 35.1044832, 'lng': -80.9399069},
  {'name': 'Restroom', 'lat': 35.1049591, 'lng': -80.942481},
  {'name': 'Restroom', 'lat': 35.102809, 'lng': -80.9439685},
  {'name': 'Restroom', 'lat': 35.1039144, 'lng': -80.9412182},
  {'name': 'Restroom', 'lat': 35.10278, 'lng': -80.9497437},
  {'name': 'Restroom', 'lat': 35.1006383, 'lng': -80.9432892},
  {'name': 'Restroom', 'lat': 35.1021462, 'lng': -80.9396464},
  {'name': 'Restroom', 'lat': 35.0998439, 'lng': -80.9447948},
  {'name': 'Restroom', 'lat': 35.1012155, 'lng': -80.9442865},
  {'name': 'Restroom', 'lat': 35.1009958, 'lng': -80.9412084},
];

final List<Map<String, dynamic>> restaurants = [
  {'name': "Papa Luigi's", 'lat': 35.1045189, 'lng': -80.9418155},
  {'name': 'Fair Fries', 'lat': 35.1031156, 'lng': -80.9434888},
  {'name': 'Blue Ridge Fixins', 'lat': 35.1017171, 'lng': -80.9419654},
  {'name': 'Fry Shack', 'lat': 35.1011767, 'lng': -80.9418011},
  {
    'name': "Leonardo's Hometown Italian Food",
    'lat': 35.1012808,
    'lng': -80.9411816,
  },
  {'name': 'Beach Bites', 'lat': 35.1014872, 'lng': -80.9457156},
  {
    'name': "Chickie's & Pete's Sports Grill",
    'lat': 35.1034636,
    'lng': -80.9433007,
  },
  {'name': 'Cinnabon', 'lat': 35.1040035, 'lng': -80.9400207},
  {'name': 'Harmony Hall Marketplace', 'lat': 35.1025851, 'lng': -80.9395776},
  {'name': "Auntie Anne's", 'lat': 35.1037222, 'lng': -80.9403829},
  {'name': 'Burrito Café', 'lat': 35.1038817, 'lng': -80.9407841},
  {'name': 'Panda Express', 'lat': 35.1018637, 'lng': -80.9403047},
  {'name': 'Camp Cookout', 'lat': 35.1015212, 'lng': -80.9401607},
  {'name': 'Juke Box Diner', 'lat': 35.10522, 'lng': -80.9430431},
  {'name': 'Harbour House', 'lat': 35.1004664, 'lng': -80.9464406},
  {'name': "Sharky's Grille", 'lat': 35.1014476, 'lng': -80.9442738},
  {
    'name': 'South Gate Drinks and Snack',
    'lat': 35.1016757,
    'lng': -80.9415221,
  },
  {'name': 'Blue Ridge Country Kitchen', 'lat': 35.1022744, 'lng': -80.9425301},
];

final List<Map<String, dynamic>> shops = [
  {'name': 'FunPix Photo Memories', 'lat': 35.1041313, 'lng': -80.9402249},
  {'name': 'The Hive at 325', 'lat': 35.1054081, 'lng': -80.9425336},
  {'name': 'Action Theater Gifts', 'lat': 35.1001795, 'lng': -80.9422902},
  {'name': 'North Gate Rentals', 'lat': 35.1041787, 'lng': -80.9394619},
  {'name': 'Minute Maid Smoothie', 'lat': 35.1041549, 'lng': -80.9415415},
  {'name': 'Pier 73', 'lat': 35.1036761, 'lng': -80.9428332},
  {'name': 'Carolina Candy Shoppe', 'lat': 35.1016846, 'lng': -80.9411601},
  {'name': 'Old Time Photo', 'lat': 35.1015776, 'lng': -80.9409079},
  {'name': 'Premiers', 'lat': 35.1037275, 'lng': -80.9401149},
  {'name': 'Camp Store', 'lat': 35.1019997, 'lng': -80.9400133},
  {'name': 'Coca-Cola Marketplace', 'lat': 35.1048043, 'lng': -80.9431947},
  {'name': 'Tradewinds', 'lat': 35.1001248, 'lng': -80.9444539},
  {'name': 'Victory Lane', 'lat': 35.1031193, 'lng': -80.9400822},
  {'name': 'Shop', 'lat': 35.1043743, 'lng': -80.9389627},
  {'name': 'Thrills', 'lat': 35.1048694, 'lng': -80.9426848},
  {'name': 'Stateline Designs', 'lat': 35.1043006, 'lng': -80.9408976},
  {'name': 'South Gate Rentals', 'lat': 35.099455, 'lng': -80.9407799},
  {'name': 'Trading Post', 'lat': 35.1042644, 'lng': -80.9478303},
  {'name': 'Gateway Gifts', 'lat': 35.1043035, 'lng': -80.9399351},
  {'name': 'Coca-Cola Refresh Station', 'lat': 35.1022476, 'lng': -80.9432162},
  {'name': 'Coca-Cola Refresh Station', 'lat': 35.1041431, 'lng': -80.9397872},
  {'name': 'The Rusted Rooster', 'lat': 35.1018142, 'lng': -80.9413027},
  {'name': 'Afterburn Photo', 'lat': 35.1005162, 'lng': -80.941006},
  {'name': 'Dino Store', 'lat': 35.1009957, 'lng': -80.9403363},
  {'name': 'Wilderness Run Ride Photo', 'lat': 35.1008686, 'lng': -80.9389173},
  {'name': 'Traditions', 'lat': 35.104144, 'lng': -80.9394854},
  {'name': 'Beachcombers', 'lat': 35.1011795, 'lng': -80.9440467},
  {'name': 'Seaside Supplies', 'lat': 35.101586, 'lng': -80.9435555},
  {'name': 'Coca-Cola Refresh Station', 'lat': 35.1014459, 'lng': -80.939823},
  {'name': 'Caricature Stand', 'lat': 35.1017773, 'lng': -80.9419051},
  {'name': 'Ricochet Ride Photo', 'lat': 35.1042231, 'lng': -80.9427827},
  {
    'name': 'Woodstock Express Ride Photo',
    'lat': 35.1014651,
    'lng': -80.9392483,
  },
  {'name': 'Copperhead Strike Photo', 'lat': 35.1015731, 'lng': -80.9426453},
];

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Style? _style;
  String? _styleError;

  LatLng? userLocation;
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
          action: SnackBarAction(
            label: 'Undo',
            onPressed: _removeParking,
          ),
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

  List<Map<String, dynamic>> rides = [
    {'name': 'Fury 325', 'lat': 35.10548, 'lng': -80.94246},
    {'name': 'Afterburn', 'lat': 35.100278, 'lng': -80.940833},
    {'name': 'Copperhead Strike', 'lat': 35.101111, 'lng': -80.942500},
    {'name': 'Thunder Striker', 'lat': 35.103056, 'lng': -80.939444},
    {'name': 'Carolina Cyclone', 'lat': 35.104167, 'lng': -80.943611},
    {'name': 'Carolina Goldrusher', 'lat': 35.103224, 'lng': -80.942918},
    {'name': 'Hurler', 'lat': 35.105244, 'lng': -80.943719},
    {'name': 'Vortex', 'lat': 35.103611, 'lng': -80.941667},
    {'name': 'Richochet', 'lat': 35.1042, 'lng': -80.9428},
    {'name': 'The Flying Cobras', 'lat': 35.102704, 'lng': -80.942792},
    {'name': 'Kiddy Hawk', 'lat': 35.10200, 'lng': -80.94090},
    {'name': 'Wilderness Run', 'lat': 35.101111, 'lng': -80.938889},
    {'name': 'Woodstock Express', 'lat': 35.101040, 'lng': -80.939422},
    {'name': 'Ripcord', 'lat': 35.10240, 'lng': -80.94020},
    {'name': 'Windseeker', 'lat': 35.1021, 'lng': -80.941347},
    {'name': 'Electro-Spin', 'lat': 35.1023, 'lng': -80.9435},
    {'name': 'Zephyr', 'lat': 35.102088, 'lng': -80.943108},
    {'name': "Rock 'N' Roller", 'lat': 35.102941, 'lng': -80.943800},
    {'name': 'Do-Si-Do', 'lat': 35.102483, 'lng': -80.943146},
    {'name': 'Mountain Gliders', 'lat': 35.101300, 'lng': -80.942400},
    {'name': 'Kaleidoscope', 'lat': 35.104600, 'lng': -80.942961},
    {'name': "Snoopy’s Racing Railway", 'lat': 35.101916, 'lng': -80.939302},
    {
      'name': "Charlie Brown’s River Raft Blast",
      'lat': 35.101546,
      'lng': -80.938632,
    },
    {'name': 'The Grand Carousel', 'lat': 35.104179, 'lng': -80.942049},
    {'name': 'Slingshot', 'lat': 35.103893, 'lng': -80.942077},
    {'name': 'Boo Blasters on Boo Hill', 'lat': 35.1014747, 'lng': -80.9415680},
    {'name': 'Hover & Dodge', 'lat': 35.101003, 'lng': -80.942198},
    {'name': 'Flying Ace Balloon Race', 'lat': 35.101754, 'lng': -80.939895},
    {'name': "Snoopy vs. Red Baron", 'lat': 35.101351, 'lng': -80.940088},
    {'name': "Pig Pen's Mud Buggies", 'lat': 35.101275, 'lng': -80.939611},
    {'name': 'PEANUTS Pirates', 'lat': 35.1017591, 'lng': -80.9390428},
    {'name': 'Woodstock Whirlybirds', 'lat': 35.1017883, 'lng': -80.9387942},
    {'name': 'Air racers', 'lat': 35.099838, 'lng': -80.941735},
    {'name': 'Wind star', 'lat': 35.100966290491336, 'lng': -80.94158331712126},
    {'name': 'Gear Spin', 'lat': 35.10073497987552, 'lng': -80.94195569566024},
    {'name': 'Gyro Force', 'lat': 35.10038704333868, 'lng': -80.94227356716658},
    {
      'name': 'The airwalker',
      'lat': 35.10024387616424,
      'lng': -80.94160983927625,
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadFilters();
    _loadStyle();
    _loadParking();
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
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(() {
              userLocation = LatLng(position.latitude, position.longitude);
            });
          }
        });
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
                                    String displayTime = 'Parked at $parkingTime';
                                    if (parkingTime != null) {
                                      try {
                                        final parsedTime = DateTime.parse(parkingTime!);
                                        displayTime = 'Parked ${timeago.format(parsedTime, locale: 'en_short')} ago';
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
                                  }
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
