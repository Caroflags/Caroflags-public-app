import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'dart:convert';
import 'randomtext.dart';
import 'scanbarcode.dart';
import 'timers.dart';
import 'package:screen_brightness/screen_brightness.dart';

class PassesScreen extends StatefulWidget {
  final String userId;

  const PassesScreen({required this.userId, super.key});

  @override
  _PassesScreenState createState() => _PassesScreenState();
}

class _PassesScreenState extends State<PassesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, dynamic> _cachedPasses = {}; // Cache for passes

  final FlutterWearOsConnectivity _wearOsConnectivity =
      FlutterWearOsConnectivity();
  bool _wearConnectivityInitialized = false;

  bool _useLocalPasses = false;
  bool _isLoadingPrefs = true;

  @override
  void initState() {
    final settingsbox = Hive.box('settings');
    super.initState();
    _loadPrefs();
    _initWearConnectivity();

    bool _brightsetting = settingsbox.get("change_screen_brightness") ?? false;

    if (_brightsetting) {
      try {
        ScreenBrightness().setApplicationScreenBrightness(1.00);
      } catch (e) {
        debugPrint("Lol didnt work: $e");
      }
    }
  }

  Future<void> _initWearConnectivity() async {
    try {
      await _wearOsConnectivity.configureWearableAPI();
      if (mounted) {
        setState(() {
          _wearConnectivityInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Failed to configure wearable API: $e");
    }
  }

  void _syncPassesToWatch() async {
    if (!_wearConnectivityInitialized) return;

    final passesList = _cachedPasses.values.map((p) {
      return {'name': p['name'], 'barcode': p['id'], 'tier': p['tier']};
    }).toList();

    final passesJson = jsonEncode(passesList);

    try {
      await _wearOsConnectivity.syncData(
        path: '/passes',
        data: {
          'passes_json': passesJson,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint("Successfully synced passes to watch!");
    } catch (e) {
      debugPrint("Failed to sync passes to watch: $e");
    }
  }

  Future<void> _loadPrefs() async {
    final user = FirebaseAuth.instance.currentUser;
    final isAnonymous = user?.isAnonymous ?? false;
    final prefs = await SharedPreferences.getInstance();

    if (isAnonymous) {
      _useLocalPasses = true;
    } else {
      _useLocalPasses = prefs.getBool('use_local_passes') ?? false;
    }

    if (mounted) {
      setState(() {
        _isLoadingPrefs = false;
      });
    }
  }

  Future<void> _addPass() async {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    String? selectedTier;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Pass'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),

              Padding(padding: const EdgeInsets.only(bottom: 16.0)),

              StatefulBuilder(
                builder: (context, unfuckDropdownButton) {
                  return DropdownButton(
                    value: selectedTier,
                    isExpanded: true,
                    hint: const Text('Select Tier'),
                    items: const [
                      DropdownMenuItem(value: 'Silver', child: Text('Silver')),
                      DropdownMenuItem(value: 'Gold', child: Text('Gold')),
                      DropdownMenuItem(
                        value: 'Platinum',
                        child: Text('Platinum'),
                      ),
                      DropdownMenuItem(value: 'Pre-K', child: Text('Pre-K')),
                    ],
                    onChanged: (value) {
                      selectedTier = value;
                      unfuckDropdownButton(() {});
                    },
                  );
                },
              ),

              Padding(padding: const EdgeInsets.only(bottom: 16.0)),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: idController,
                      decoration: const InputDecoration(
                        labelText: 'Pass Number',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      var status = await Permission.camera.request();
                      if (status.isGranted) {
                        if (!context.mounted) return;
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const BarcodeScannerScreen(returnResult: true),
                          ),
                        );
                        if (result != null && result is String) {
                          idController.text = result;
                        }
                      } else {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Camera permission is required to scan your pass.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              Padding(padding: const EdgeInsets.only(bottom: 16.0)),
              Text(
                'You can only scan the barcode on the pass, not the qr code. The barcode is better anyways.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            // Uhh the fuckin uhh code for adding a pass
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final id = idController.text.trim();
                final tier = selectedTier;
                showSnackbar(context, 'Your pass $id has been added!');

                if (name.isNotEmpty && id.isNotEmpty && tier != null) {
                  if (_useLocalPasses) {
                    final box = Hive.box('local_passes');
                    final newKey = DateTime.now().millisecondsSinceEpoch
                        .toString();
                    await box.put(newKey, {
                      'name': name,
                      'id': id,
                      'tier': tier,
                    });
                  } else {
                    await _firestore
                        .collection('users')
                        .doc(widget.userId)
                        .collection('passes')
                        .add({'name': name, 'id': id, 'tier': tier});
                  }

                  _cachedPasses.clear(); // Clear cache after adding a new pass
                  if (context.mounted) {
                    setState(() {}); // Refresh the UI
                  }
                }

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
            // end of code for adding pass
          ],
        );
      },
    );
  }

  void showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    ScreenBrightness().resetApplicationScreenBrightness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPrefs) {
      return Scaffold(
        appBar: AppBar(title: const Text('Passes')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Passes')),
      body: _useLocalPasses ? _buildLocalPasses() : _buildCloudPasses(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPass,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLocalPasses() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('local_passes').listenable(),
      builder: (context, Box box, _) {
        if (box.isEmpty) {
          final nopassesText = nopasses;
          return Center(child: Text(nopassesText));
        }

        _cachedPasses.clear();
        for (var key in box.keys) {
          final passMap = box.get(key) as Map;
          _cachedPasses[key.toString()] = {
            'name': passMap['name'],
            'id': passMap['id'],
            'tier': passMap['tier'],
          };
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncPassesToWatch();
        });

        return _buildPassesCarousel();
      },
    );
  }

  Widget _buildCloudPasses() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('passes')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          final nopassesText = nopasses;
          return Center(child: Text(nopassesText));
        }

        final passes = snapshot.data!.docs;

        _cachedPasses.clear();

        // Cache the passes
        for (var pass in passes) {
          _cachedPasses[pass.id] = pass.data();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncPassesToWatch();
        });

        return _buildPassesCarousel();
      },
    );
  }

  Widget _buildPassesCarousel() {
    return PageView.builder(
      itemCount: _cachedPasses.length,
      itemBuilder: (context, index) {
        final passId = _cachedPasses.keys.elementAt(index);
        final pass = _cachedPasses[passId];
        final name = pass['name'];
        final id = pass['id'];
        final tier = pass['tier'];

        Color getTierColor(String? tier) {
          switch (tier) {
            case 'Gold':
              return const Color.fromARGB(
                255,
                241,
                222,
                164,
              ); // Light Gold tint
            case 'Silver':
              return const Color.fromARGB(
                255,
                144,
                152,
                156,
              ); // Silver/Grey tint
            case 'Platinum':
              return const Color.fromARGB(
                101,
                255,
                255,
                255,
              ); // Platinum/Purple tint
            case 'Pre-K':
              return const Color.fromARGB(255, 20, 216, 151); // Pre-K tint
            default:
              return Colors.white; // Default if null or unknown
          }
        }

        bool isDark(Color color) {
          return color.computeLuminance() < 0.173;
        }

        return Card(
          color: getTierColor(tier),
          margin: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark(getTierColor(tier))
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ID: $id',
                style: TextStyle(
                  fontSize: 18,
                  color: isDark(getTierColor(tier))
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Type: $tier',
                style: TextStyle(
                  fontSize: 18,
                  color: isDark(getTierColor(tier))
                      ? Colors.white
                      : Colors.black,
                ),
              ),

              const SizedBox(height: 16),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: QrImageView(
                  data: id,
                  version: QrVersions.auto,
                  size: 300.0,
                  backgroundColor: Colors.white,
                ),
              ),
              Padding(padding: EdgeInsets.all(16)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      // Show popup for confirmation
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Delete Pass'),
                            content: const Text(
                              'Are you sure you want to delete this pass?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  showSnackbar(
                                    context,
                                    'PassID: $passId deleted.',
                                  );
                                  if (_useLocalPasses) {
                                    await Hive.box(
                                      'local_passes',
                                    ).delete(passId);
                                  } else {
                                    await _firestore
                                        .collection('users')
                                        .doc(widget.userId)
                                        .collection('passes')
                                        .doc(passId)
                                        .delete();
                                  }
                                  _cachedPasses.remove(passId);
                                  if (context.mounted) {
                                    setState(() {});
                                  }
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('Delete Pass'),
                  ),

                  // EOL
                  Padding(padding: const EdgeInsets.only(right: 16.0)),

                  ElevatedButton(
                    onPressed: () {
                      final nameController = TextEditingController(text: name);
                      String? selectedTier = tier;
                      final idController = TextEditingController(text: id);

                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Edit Pass'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                ),

                                StatefulBuilder(
                                  builder: (context, unfuckDropdownButton) {
                                    return DropdownButton(
                                      value: selectedTier,
                                      isExpanded: true,
                                      hint: const Text('Select Tier'),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Silver',
                                          child: Text('Silver'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Gold',
                                          child: Text('Gold'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Platinum',
                                          child: Text('Platinum'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Fast Lane',
                                          child: Text('Fast Lane'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Pre-K',
                                          child: Text('Pre-K'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        selectedTier = value;
                                        unfuckDropdownButton(() {});
                                      },
                                    );
                                  },
                                ),

                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                ),

                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: idController,
                                        decoration: const InputDecoration(
                                          labelText: 'Pass Number',
                                        ),
                                      ),
                                    ),

                                    IconButton(
                                      icon: const Icon(Icons.qr_code_scanner),
                                      onPressed: () async {
                                        var status = await Permission.camera
                                            .request();
                                        if (status.isGranted) {
                                          if (!context.mounted) return;
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const BarcodeScannerScreen(
                                                    returnResult: true,
                                                  ),
                                            ),
                                          );
                                          if (result != null &&
                                              result is String) {
                                            idController.text = result;
                                          }
                                        } else {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Camera permission is required to scan your pass.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  showSnackbar(
                                    context,
                                    'Changes Saved for $passId',
                                  );
                                  if (_useLocalPasses) {
                                    await Hive.box('local_passes').put(passId, {
                                      'name': nameController.text,
                                      'tier': selectedTier,
                                      'id': idController.text,
                                    });
                                  } else {
                                    await _firestore
                                        .collection('users')
                                        .doc(widget.userId)
                                        .collection('passes')
                                        .doc(passId)
                                        .update({
                                          'name': nameController.text,
                                          'tier': selectedTier,
                                          'id': idController.text,
                                        });
                                  }
                                  _cachedPasses.remove(passId);
                                  if (context.mounted) {
                                    setState(() {});
                                  }
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: const Text('Save Changes'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('Edit Pass'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TimersScreen()),
                  );
                },
                child: const Text('Set Timer'),
              ),
            ],
          ),
        );
      },
    );
  }
}
