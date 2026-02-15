import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ParkStatus extends StatefulWidget {
  const ParkStatus({super.key});

  @override
  State<ParkStatus> createState() => _ParkStatusState();
}

class _ParkStatusState extends State<ParkStatus> {
  bool? isParkClosed;
  bool isLoading = true;
  String errorMessage = '';

  static final _parkStatusCache = CacheManager(
    Config(
      'park_status_cache',
      stalePeriod: const Duration(days: 1),
      maxNrOfCacheObjects: 10,
      repo: JsonCacheInfoRepository(databaseName: 'park_status_cache'),
      fileService: HttpFileService(),
    ),
  );

  @override
  void initState() {
    super.initState();
    _fetchParkStatus();
  }

  Future<void> _fetchParkStatus() async {
    const url = 'https://d18car1k0ff81h.cloudfront.net/operating-hours/park/30';
    try {
      FileInfo? fileInfo = await _parkStatusCache.getFileFromCache(url);

      // If cache is valid, use it
      if (fileInfo != null && fileInfo.validTill.isAfter(DateTime.now())) {
        if (mounted) _processData(await fileInfo.file.readAsString());
        return;
      }

      // Try fetching new data
      try {
        final file = await _parkStatusCache.getSingleFile(url);
        if (mounted) _processData(await file.readAsString());
        return;
      } catch (e) {
        // If fetch fails but we have (expired) cache, use it as fallback
        if (fileInfo != null) {
          if (mounted) _processData(await fileInfo.file.readAsString());
          return;
        }
        throw e; // Rethrow if no cache to fallback to
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: $e';
          isLoading = false;
        });
      }
    }
  }

  void _processData(String jsonString) {
    try {
      final data = json.decode(jsonString);
      final List<dynamic> dates = data['dates'];

      final now = DateTime.now();
      final formatter = DateFormat('MM/dd/yyyy');
      final todayStr = formatter.format(now);

      final todayData = dates.firstWhere(
        (d) => d['date'] == todayStr,
        orElse: () => null,
      );

      if (todayData != null) {
        setState(() {
          isParkClosed = todayData['isParkClosed'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'No data for today';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to parse status';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (errorMessage.isNotEmpty || isParkClosed == null) {
      // Optionally hide if error? Or show small error text.
      // User didn't specify error state, so I'll render nothing or a small error.
      return const SizedBox.shrink();
      // Or useful for debug: Text(errorMessage, style: TextStyle(color: Colors.red, fontSize: 10));
    }

    final isClosed = isParkClosed!;
    final text = isClosed
        ? "Park closed today, maybe tommrow?"
        : "The park is open today!";
    final color = isClosed ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Fit content
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
