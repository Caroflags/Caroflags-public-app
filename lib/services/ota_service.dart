import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart'; // Change 1: Import OpenFilex
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart'; // Change 2: Import path_provider
import 'package:shared_preferences/shared_preferences.dart';

class OtaService {
  static const String _repoOwner = 'Caroflags';
  static const String _repoName = 'Caroflags-public-app';
  static const String _prefLaterKey = 'ota_later_timestamp';

  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      // 1. Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 2. Fetch latest release from GitHub
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
        ),
      );

      if (response.statusCode != 200) {
        debugPrint('OTA: Failed to fetch release info: ${response.statusCode}');
        return;
      }

      final releaseData = json.decode(response.body);
      final String tagName = releaseData['tag_name'] ?? '';
      final String latestVersion = tagName.replaceAll('v', '');
      final String body = releaseData['body'] ?? 'No release notes.';
      final List assets = releaseData['assets'] ?? [];

      if (assets.isEmpty) {
        debugPrint('OTA: No assets found in release.');
        return;
      }

      // Find APK asset
      final apkAsset = assets.firstWhere(
        (asset) => asset['name'].toString().endsWith('.apk'),
        orElse: () => null,
      );

      if (apkAsset == null) {
        debugPrint('OTA: No APK found in release assets.');
        return;
      }

      final String downloadUrl = apkAsset['browser_download_url'];

      // 3. Compare versions
      if (_isUpdateAvailable(currentVersion, latestVersion)) {
        // 4. Check "Later" preference
        if (await _shouldShowUpdateDialog()) {
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, body, downloadUrl);
          }
        } else {
          debugPrint('OTA: Update available but user postponed.');
        }
      } else {
        debugPrint('OTA: App is up to date.');
      }
    } catch (e) {
      debugPrint('OTA Error: $e');
    }
  }

  static bool _isUpdateAvailable(String current, String latest) {
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> latestParts = latest.split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length; i++) {
        if (i >= currentParts.length) return true; // Latest has more parts
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false; // Equal
    } catch (e) {
      debugPrint('OTA: Error comparing versions: $current vs $latest');
      return false;
    }
  }

  static Future<bool> _shouldShowUpdateDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final int? timestamp = prefs.getInt(_prefLaterKey);

    if (timestamp == null) return true;

    final lastLaterTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = DateTime.now().difference(lastLaterTime);

    // Show if 7 days have passed
    return difference.inDays >= 7;
  }

  static Future<void> _showUpdateDialog(
    BuildContext context,
    String version,
    String notes,
    String downloadUrl,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('New Update Available! (v$version)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('A new version of Caroflags is available.'),
                const SizedBox(height: 10),
                const Text(
                  'Release Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(notes),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // "Ehh, later"
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt(
                  _prefLaterKey,
                  DateTime.now().millisecondsSinceEpoch,
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Ehh, later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Start download and install
                _downloadAndInstall(context, downloadUrl);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _downloadAndInstall(
    BuildContext context,
    String url,
  ) async {
    try {
      // Show downloading indicator (optional, but good UX)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading update... Please wait.'),
          duration: Duration(seconds: 30), // Long enough for most downloads
        ),
      );

      // 1. Get temporary directory
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/update.apk';
      final file = File(filePath);

      // 2. Download file (Streaming)
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed with status: ${response.statusCode}');
      }

      final IOSink sink = file.openWrite();
      await response.stream.pipe(sink);
      await sink.close();

      // 3. Open file to install
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception('Could not open APK: ${result.message}');
      }
    } catch (e) {
      debugPrint('OTA Install Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }
}
