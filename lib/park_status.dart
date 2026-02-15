import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ParkStatus extends StatefulWidget {
  const ParkStatus({super.key});

  @override
  State<ParkStatus> createState() => _ParkStatusState();
}

class _ParkStatusState extends State<ParkStatus> {
  bool? isParkClosed;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchParkStatus();
  }

  Future<void> _fetchParkStatus() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://d18car1k0ff81h.cloudfront.net/operating-hours/park/30',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> dates = data['dates'];

        final now = DateTime.now();
        final formatter = DateFormat('MM/dd/yyyy');
        final todayStr = formatter.format(now);

        final todayData = dates.firstWhere(
          (d) => d['date'] == todayStr,
          orElse: () => null,
        );

        if (todayData != null) {
          if (mounted) {
            setState(() {
              isParkClosed = todayData['isParkClosed'];
              isLoading = false;
            });
          }
        } else {
          // If today is not found in the list, assume closed or handle error?
          // The API might not return today if it's past operating hours?
          // Let's assume unavailable means we can't say for sure, but for now let's say "Unknown" or set closed.
          // User prompt: "focus on the isParkClosed status if it is true... else if it is false"
          // I'll assume closed if no data for today is safer.
          if (mounted) {
            setState(() {
              // Fallback: if we can't find today, maybe we shouldn't show anything or show closed?
              // I'll show error.
              errorMessage = 'No data for today';
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to load status';
            isLoading = false;
          });
        }
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
