
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
                decoration: const InputDecoration(labelText: 'Name of person'),
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
                    },
                  ),
                ],
              ),
              Padding(padding: const EdgeInsets.only(bottom: 16.0)),
              Text(
                'If you are going to scan a barcode, please scan the barcode and not the qr code. The qr code is worse than the barcode.',
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
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final id = idController.text.trim();

                if (name.isNotEmpty && id.isNotEmpty) {
                  await _firestore
                      .collection('users')
                      .doc(widget.userId)
                      .collection('passes')
                      .add({'name': name, 'id': id});
                  _cachedPasses.clear(); // Clear cache after adding a new pass
                }

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
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

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ID: $id',
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: id,
                      version: QrVersions.auto,
                      size: 300.0,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        showSnackbar(context, 'PassID: $passId deleted.');
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
