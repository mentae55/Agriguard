// lib/presentation/widgets/soil/alerts_section.dart
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../data/model/soil_model.dart';
import '../../view_model/soil_analysis_viewmodel.dart';

class AlertsSection extends StatelessWidget {
  final SoilAnalysisViewModel vm;
  final SoilSnapshot snap;
  const AlertsSection({super.key, required this.vm, required this.snap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (snap.nAlerts == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A3A1A) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark
                  ? Colors.green.withAlpha(90)
                  : Colors.green.shade300.withAlpha(100),
              width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.green, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '✅ Soil is healthy — no active alerts.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'AbhayaLibre',
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: snap.alerts
          .map((a) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _AlertCard(vm: vm, alert: a),
      ))
          .toList(),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final SoilAnalysisViewModel vm;
  final SoilAlert alert;

  const _AlertCard({required this.vm, required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isCritical = alert.severity.toLowerCase() == 'critical';
    final sevColor = isCritical ? redColor : orangeColor;
    final sevBg = isCritical
        ? (isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFFEBEE))
        : (isDark ? const Color(0xFF3A2F1A) : const Color(0xFFFFF8E1));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: sevColor.withAlpha(isDark ? 90 : 60), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 5),
            blurRadius: isDark ? 8 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCritical
                    ? Icons.error_outline_rounded
                    : Icons.warning_amber_rounded,
                color: sevColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vm.formatParamName(alert.param),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'AbhayaLibre',
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sevBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sevColor.withAlpha(80)),
                ),
                child: Text(
                  alert.severity.toUpperCase(),
                  style: TextStyle(
                    color: sevColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.onSurface.withAlpha(15)
                      : const Color(0xFFF5F8F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${alert.value} ${alert.unit}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'AbhayaLibre',
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sevColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  alert.status.toUpperCase(),
                  style: TextStyle(
                    color: sevColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alert.recommendation,
            style: TextStyle(
              color: colorScheme.onSurface.withAlpha(180),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}