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
    super.initState();
    _loadPrefs();
    _initWearConnectivity();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settingsbox = Hive.box('settings');
      bool _brightsetting = settingsbox.get("change_screen_brightness") ?? true;

      if (_brightsetting) {
        // Wait for route transition to finish to prevent Android window layout glitches
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        try {
          await ScreenBrightness().setApplicationScreenBrightness(1.00);
        } catch (e) {
          debugPrint("Lol didnt work: $e");
        }
      }
    });
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
                        value: 'Prestiege',
                        child: Text('Prestiege'),
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

                if (name.isNotEmpty && id.isNotEmpty && tier != null) {
                  showSnackbar(context, 'Your pass $id has been added!');
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
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection('passes')
                        .add({'name': name, 'id': id, 'tier': tier});
                  }

                  _cachedPasses.clear(); // Clear cache after adding a new pass
                  if (context.mounted) {
                    setState(() {}); // Refresh the UI
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                } else {
                  showSnackbar(
                    context,
                    'Please fill all fields and select a tier!',
                  );
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

  void _addPerk(
    BuildContext context,
    String passId,
    Map<String, dynamic> passData,
  ) {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Pass Perk'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: idController,
                          decoration: const InputDecoration(
                            labelText: 'Perk ID',
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
                                    const BarcodeScannerScreen(
                                      returnResult: true,
                                    ),
                              ),
                            );
                            if (result != null && result is String) {
                              idController.text = result;
                            }
                          } else {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Camera permission required.'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'No Date Selected'
                              : 'Expires: ${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                        child: const Text('Select Date'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty ||
                        idController.text.trim().isEmpty ||
                        selectedDate == null) {
                      showSnackbar(
                        context,
                        'Please fill all fields and select a date.',
                      );
                      return;
                    }

                    final newPerk = {
                      'name': nameController.text.trim(),
                      'id': idController.text.trim(),
                      'expiration': selectedDate!.toIso8601String(),
                    };

                    List<dynamic> currentPerks = List.from(
                      passData['perks'] ?? [],
                    );
                    currentPerks.add(newPerk);
                    passData['perks'] =
                        currentPerks; // Update the cache immediately so it's consistent

                    if (_useLocalPasses) {
                      await Hive.box('local_passes').put(passId, passData);
                    } else {
                      await _firestore
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('passes')
                          .doc(passId)
                          .update({'perks': currentPerks});
                    }

                    _cachedPasses[passId] = passData;

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      setState(() {}); // refresh PassesScreen
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    try {
      ScreenBrightness().resetApplicationScreenBrightness();
    } catch (e) {
      debugPrint("Reset brightness failed: $e");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPrefs) {
      return Scaffold(
        appBar: AppBar(title: const Text('Passes'), toolbarHeight: 48.0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Passes'), toolbarHeight: 48.0),
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
          final passMap = Map<String, dynamic>.from(box.get(key) as Map);
          _cachedPasses[key.toString()] = passMap;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncPassesToWatch();
        });

        return _buildPassesCarousel();
      },
    );
  }

  Widget _buildCloudPasses() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('You must be logged in to view passes.'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(user.uid)
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
        final String name = pass['name']?.toString() ?? 'Unknown Pass';
        final String id = pass['id']?.toString() ?? '';
        final String? tier = pass['tier']?.toString();

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
            case 'Prestiege':
              return const Color.fromARGB(
                101,
                255,
                255,
                255,
              ); // Platinum/Purple tint
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
              return const Color.fromARGB(
                255,
                255,
                255,
                255,
              ); // Default if null or unknown
          }
        }

        bool isDark(Color color) {
          return color.computeLuminance() < 0.173;
        }

        return Card(
          color: getTierColor(tier),
          margin: const EdgeInsets.all(8.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 64),
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
                              child: id.isNotEmpty
                                  ? QrImageView(
                                      data: id,
                                      version: QrVersions.auto,
                                      size: 300.0,
                                      backgroundColor: Colors.white,
                                    )
                                  : Container(
                                      width: 300.0,
                                      height: 300.0,
                                      color: Colors.white,
                                      child: const Center(
                                        child: Text(
                                          'Invalid ID',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                    ),
                            ),
                            const Padding(padding: EdgeInsets.all(16)),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const TimersScreen(),
                                  ),
                                );
                              },
                              child: const Text('Set Timer'),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Pass Perks',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.add,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                        onPressed: () =>
                                            _addPerk(context, passId, pass),
                                      ),
                                    ],
                                  ),
                                  Divider(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                                  if (pass['perks'] != null &&
                                      (pass['perks'] as List).isNotEmpty)
                                    ...((pass['perks'] as List).map((perk) {
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          perk['name'] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Expires: ${DateTime.parse(perk['expiration']).month}/${DateTime.parse(perk['expiration']).day}/${DateTime.parse(perk['expiration']).year}',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        trailing: Icon(
                                          Icons.qr_code,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(
                                                  perk['name'] ?? 'Perk',
                                                  textAlign: TextAlign.center,
                                                ),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      width: 250,
                                                      height: 250,
                                                      child: QrImageView(
                                                        data: perk['id'] ?? '',
                                                        version: QrVersions.auto,
                                                        backgroundColor:
                                                            Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Expires: ${DateTime.parse(perk['expiration']).month}/${DateTime.parse(perk['expiration']).day}/${DateTime.parse(perk['expiration']).year}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () async {
                                                      final confirm = await showDialog<bool>(
                                                        context: context,
                                                        builder: (context) {
                                                          return AlertDialog(
                                                            title: const Text('Delete Perk'),
                                                            content: const Text('Do you wanna delete this pass perk?'),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () => Navigator.of(context).pop(false),
                                                                child: const Text('Cancel'),
                                                              ),
                                                              TextButton(
                                                                onPressed: () => Navigator.of(context).pop(true),
                                                                child: const Text(
                                                                  'Delete',
                                                                  style: TextStyle(color: Colors.red),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );

                                                      if (confirm == true) {
                                                        final List<dynamic> currentPerks = List.from(pass['perks'] ?? []);
                                                        final int deletedIndex = currentPerks.indexOf(perk);
                                                        if (deletedIndex != -1) {
                                                          currentPerks.removeAt(deletedIndex);
                                                        }
                                                        pass['perks'] = currentPerks;

                                                        if (_useLocalPasses) {
                                                          await Hive.box('local_passes').put(passId, pass);
                                                        } else {
                                                          await _firestore
                                                              .collection('users')
                                                              .doc(FirebaseAuth.instance.currentUser!.uid)
                                                              .collection('passes')
                                                              .doc(passId)
                                                              .update({'perks': currentPerks});
                                                        }

                                                        _cachedPasses[passId] = pass;

                                                        if (context.mounted) {
                                                          // Pop the main perk QR dialog
                                                          Navigator.of(context).pop();
                                                          // Refresh the screen state
                                                          setState(() {});
                                                          
                                                          // Show success SnackBar with Undo
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Perk "${perk['name']}" deleted'),
                                                              action: SnackBarAction(
                                                                label: 'Undo',
                                                                onPressed: () async {
                                                                  // Undo deletion logic
                                                                  List<dynamic> restoredPerks = List.from(pass['perks'] ?? []);
                                                                  if (deletedIndex != -1 && deletedIndex <= restoredPerks.length) {
                                                                    restoredPerks.insert(deletedIndex, perk);
                                                                  } else {
                                                                    restoredPerks.add(perk);
                                                                  }
                                                                  pass['perks'] = restoredPerks;

                                                                  if (_useLocalPasses) {
                                                                    await Hive.box('local_passes').put(passId, pass);
                                                                  } else {
                                                                    await _firestore
                                                                        .collection('users')
                                                                        .doc(FirebaseAuth.instance.currentUser!.uid)
                                                                        .collection('passes')
                                                                        .doc(passId)
                                                                        .update({'perks': restoredPerks});
                                                                  }

                                                                  _cachedPasses[passId] = pass;
                                                                  setState(() {});
                                                                  if (context.mounted) {
                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                      SnackBar(
                                                                        content: Text('Restored "${perk['name']}"!'),
                                                                      ),
                                                                    );
                                                                  }
                                                                },
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    },
                                                    child: const Text(
                                                      'Delete',
                                                      style: TextStyle(color: Colors.red),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(),
                                                    child: const Text('Close'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    }).toList())
                                  else
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16.0,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No perks added yet.',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: isDark(getTierColor(tier))
                                ? Colors.white
                                : Colors.black,
                          ),
                          onPressed: () {
                            final nameController = TextEditingController(
                              text: name,
                            );
                            String? selectedTier = tier;
                            final idController = TextEditingController(
                              text: id,
                            );

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

                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 16.0),
                                      ),

                                      StatefulBuilder(
                                        builder:
                                            (context, unfuckDropdownButton) {
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
                                                    value: 'Prestiege',
                                                    child: Text('Prestiege'),
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

                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 16.0),
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
                                            icon: const Icon(
                                              Icons.qr_code_scanner,
                                            ),
                                            onPressed: () async {
                                              var status = await Permission
                                                  .camera
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
                                        pass['name'] = nameController.text;
                                        pass['tier'] = selectedTier;
                                        pass['id'] = idController.text;

                                        if (_useLocalPasses) {
                                          await Hive.box(
                                            'local_passes',
                                          ).put(passId, pass);
                                        } else {
                                          await _firestore
                                              .collection('users')
                                              .doc(
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser!
                                                    .uid,
                                              )
                                              .collection('passes')
                                              .doc(passId)
                                              .update({
                                                'name': nameController.text,
                                                'tier': selectedTier,
                                                'id': idController.text,
                                                // keep perks the same since we update the whole object
                                                'perks': pass['perks'],
                                              });
                                        }
                                        _cachedPasses[passId] = pass;
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
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: isDark(getTierColor(tier))
                                ? Colors.white
                                : Colors.black,
                          ),
                          onPressed: () async {
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
                                              .doc(
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser!
                                                    .uid,
                                              )
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
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
