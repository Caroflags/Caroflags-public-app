import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wearable_rotary/wearable_rotary.dart';
import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WearApp extends StatelessWidget {
  const WearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caroflags Wear',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: const WearPassesScreen(),
    );
  }
}

class WearPassesScreen extends StatefulWidget {
  const WearPassesScreen({super.key});

  @override
  State<WearPassesScreen> createState() => _WearPassesScreenState();
}

class _WearPassesScreenState extends State<WearPassesScreen> {
  final PageController _pageController = PageController();
  final FlutterWearOsConnectivity _wearOsConnectivity =
      FlutterWearOsConnectivity();
  List<Map<String, dynamic>> _passes = [];

  @override
  void initState() {
    super.initState();
    _loadCachedPasses();
    _initWearConnectivity();
    _pageController.addListener(_handleRotaryScroll);
    // Listen for rotary events
    rotaryEvents.listen((RotaryEvent event) {
      if (!_pageController.hasClients) return;
      if (event.direction == RotaryDirection.clockwise) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (event.direction == RotaryDirection.counterClockwise) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _handleRotaryScroll() {
    // We can also use rotaryScrollController, but handling rotaryEvents directly might be better for PageView
  }

  Future<void> _initWearConnectivity() async {
    await _wearOsConnectivity.configureWearableAPI();

    _wearOsConnectivity.dataChanged().listen((List<DataEvent> events) {
      for (var event in events) {
        if (event.type == DataEventType.changed &&
            event.dataItem.pathURI.path == '/passes') {
          final dataMap = event.dataItem.mapData;
          if (dataMap.containsKey('passes_json')) {
            final passesJson = dataMap['passes_json'] as String;
            _updatePasses(passesJson);
          }
        }
      }
    });

    // We can also fetch the initial data item
    try {
      final uri = Uri(scheme: 'wear', path: '/passes');
      final dataItem = await _wearOsConnectivity.findDataItemOnURIPath(
        pathURI: uri,
      );
      if (dataItem != null) {
        final dataMap = dataItem.mapData;
        if (dataMap.containsKey('passes_json')) {
          _updatePasses(dataMap['passes_json'] as String);
        }
      }
    } catch (e) {
      debugPrint("Error fetching initial passes: \$e");
    }
  }

  Future<void> _loadCachedPasses() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedPassesJson = prefs.getString('cached_passes_json');
    if (cachedPassesJson != null) {
      _updatePasses(cachedPassesJson, saveToCache: false);
    }
  }

  Future<void> _updatePasses(
    String passesJson, {
    bool saveToCache = true,
  }) async {
    try {
      if (saveToCache) {
        final prefs = await SharedPreferences.getInstance();
        final currentCached = prefs.getString('cached_passes_json');
        if (currentCached == passesJson) {
          return; // No difference, do not update state or save
        }
        await prefs.setString('cached_passes_json', passesJson);
      }
      final List<dynamic> decodedList = jsonDecode(passesJson);
      setState(() {
        _passes = decodedList.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint("Failed to decode passes: $e");
    }
  }

  Color _getTierColor(String tierName) {
    // Match colors from lib/passes.dart
    switch (tierName) {
      case 'Gold':
        return const Color.fromARGB(255, 0, 0, 0); // Light Gold tint
      case 'Silver':
        return const Color.fromARGB(255, 0, 0, 0); // Silver/Grey tint
      case 'Platinum':
        return const Color.fromARGB(255, 0, 0, 0); // Platinum/Purple tint
      case 'Pre-K':
        return const Color.fromARGB(255, 0, 0, 0); // Pre-K tint
      default:
        return const Color.fromARGB(255, 0, 0, 0); // Default if null or unknown
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_passes.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.watch_outlined, size: 40, color: Colors.white54),
              SizedBox(height: 8),
              Text(
                "No passes synced.",
                style: TextStyle(color: Colors.white54),
              ),
              Text(
                "Open wallet page on phone.",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: _passes.length,
        itemBuilder: (context, index) {
          final pass = _passes[index];
          final barcode = pass['barcode'] ?? '';
          final tier = pass['tier'] ?? 'Unknown';
          final bgColor = _getTierColor(tier);

          return Container(
            color: bgColor,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pass['name'] ?? 'Unknown Pass',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: barcode,
                      version: QrVersions.auto,
                      size: 120.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
