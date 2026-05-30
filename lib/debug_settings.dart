import 'package:flutter/material.dart';
import 'api_config.dart';

class DebugSettingsPage extends StatefulWidget {
  const DebugSettingsPage({super.key});

  @override
  State<DebugSettingsPage> createState() => _DebugSettingsPageState();
}

class _DebugSettingsPageState extends State<DebugSettingsPage> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'http://10.0.2.2:8080',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ApiConfig.baseUrl = _urlController.text.trim();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('API URL updated to: ${ApiConfig.baseUrl}')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
