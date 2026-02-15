// I am very shit at coding and this is for rides
// if you need to modify the restrauants, go to restaruantviewer.dart
// if you need to modify the rides, go to attractionviewer.dart

import 'package:flutter/material.dart';

class AttractionViewer extends StatelessWidget {
  const AttractionViewer({super.key, required this.response});
  final Map<String, dynamic> response;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(response['name'] ?? 'Unknown Ride'),
            centerTitle: true,
            // standard M3 app bar usually handles colors automatically based on theme
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (response['areallybiasedopinion'] != null &&
                      response['areallybiasedopinion'].isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildOpinionCard(
                      context,
                      response['areallybiasedopinion'],
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    "Details",
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatsGrid(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpinionCard(BuildContext context, String opinion) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.secondaryContainer,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.reviews_outlined,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "My very unbiased opinion",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              opinion,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    // Helper to safely get string values
    String getValue(String key) => response[key]?.toString() ?? 'N/A';

    final List<Map<String, dynamic>> stats = [
      {'label': 'Thrill', 'value': getValue('thrill'), 'icon': Icons.bolt},
      {'label': 'Speed', 'value': getValue('speed'), 'icon': Icons.speed},
      {'label': 'Height', 'value': getValue('height'), 'icon': Icons.height},
      {
        'label': 'Duration',
        'value': getValue('duration'),
        'icon': Icons.timer_outlined,
      },
      {
        'label': 'Inversions',
        'value': getValue('inversions'),
        'icon': Icons.loop,
      },
      {
        'label': 'Min Height',
        'value': getValue('minheight'),
        'icon': Icons.accessibility_new,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Two columns
        final double cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: stats.map((stat) {
            return SizedBox(
              width: cardWidth,
              child: _buildStatItem(
                context,
                stat['label'],
                stat['value'],
                stat['icon'],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      color: colorScheme.surface, // Standard surface color
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
