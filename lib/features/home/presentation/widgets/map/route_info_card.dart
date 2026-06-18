// lib/presentation/widgets/map/route_info_card.dart
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';

class RouteInfoCard extends StatelessWidget {
  final double distance;
  final double duration;
  final VoidCallback? onClose;

  const RouteInfoCard({
    super.key,
    required this.distance,
    required this.duration,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final distanceInKm = distance / 1000;
    final durationInMinutes = (duration / 60).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(240),
        borderRadius: BorderRadius.circular(radius16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withAlpha(isDark ? 15 : 10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
            color: primaryColor.withAlpha(isDark ? 120 : 60), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoItem(icon: Icons.route, value: '${distanceInKm.toStringAsFixed(1)} km'),
              _InfoItem(icon: Icons.access_time, value: '$durationInMinutes min'),
              _InfoItem(
                icon: Icons.directions_car,
                value: '${_calculateAverageSpeed(distanceInKm, durationInMinutes)} km/h',
              ),
            ],
          ),
          if (onClose != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Close Route',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  static String _calculateAverageSpeed(double distanceInKm, int durationInMinutes) {
    if (durationInMinutes == 0) return '0';
    final hours = durationInMinutes / 60;
    final averageSpeed = distanceInKm / hours;
    return averageSpeed.toStringAsFixed(1);
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoItem({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: primaryColor, size: 40),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    );
  }
}