import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'randomtext.dart';
import 'scanbarcode.dart';

class PassesScreen extends StatefulWidget {
  final String userId;

  const PassesScreen({required this.userId, super.key});

  @override
  _PassesScreenState createState() => _PassesScreenState();
}

class _PassesScreenState extends State<PassesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, dynamic> _cachedPasses = {}; // Cache for passes
  Future<void> _addPass() async {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final tiercontroller = TextEditingController();
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
                      DropdownMenuItem(
                        value: 'Fast Lane',
                        child: Text('Fast Lane'),
                      ),
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
                'If you are going to scan the qr code on your pass, no. Scan the barcode. Please I beg you. PLEASE.',
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
                  await _firestore
                      .collection('users')
                      .doc(widget.userId)
                      .collection('passes')
                      .add({'name': name, 'id': id, 'tier': tier});

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passes')),
      body: StreamBuilder<QuerySnapshot>(
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

          // Cache the passes
          for (var pass in passes) {
            _cachedPasses[pass.id] = pass.data();
          }

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
                  case 'Fast Lane':
                    return const Color.fromARGB(
                      255,
                      209,
                      244,
                      54,
                    ); // Fast Lane tint
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
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                      ),
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
                                    await _firestore
                                        .collection('users')
                                        .doc(widget.userId)
                                        .collection('passes')
                                        .doc(passId)
                                        .delete();
                                    _cachedPasses.remove(
                                      passId,
                                    ); // Remove from cache after deletion
                                    if (context.mounted) {
                                      setState(() {}); // Refresh the UI
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
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPass,
        child: const Icon(Icons.add),
      ),
    );
  }
}
