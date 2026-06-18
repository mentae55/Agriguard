// lib/presentation/widgets/soil/status_bar.dart
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../data/model/soil_model.dart';
import '../../view_model/soil_analysis_viewmodel.dart';

class SoilStatusBar extends StatelessWidget {
  final SoilAnalysisViewModel vm;
  final SoilSnapshot snap;
  const SoilStatusBar({super.key, required this.vm, required this.snap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final sc = vm.statusColor(snap.soilStatus);
    final sb = vm.statusBg(snap.soilStatus, isDark: isDark);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sc.withAlpha(60), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 5),
            blurRadius: isDark ? 8 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: sb,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sc.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                      BoxDecoration(color: sc, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      snap.soilStatus.toUpperCase(),
                      style: TextStyle(
                        color: sc,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        fontFamily: 'AbhayaLibre',
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: grayColor),
                  const SizedBox(width: 4),
                  Text(
                    vm.formatTimestamp(snap.timestamp),
                    style: const TextStyle(
                      color: grayColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoChip(Icons.location_on_outlined, 'Field',
                    snap.reading.locationId),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoChip(Icons.memory_rounded, 'Device',
                    snap.reading.deviceId),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.onSurface.withAlpha(15)
            : const Color(0xFFF5F8F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: grayColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
                Text(value,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'AbhayaLibre',
                    ),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}