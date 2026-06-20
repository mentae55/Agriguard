// lib/presentation/widgets/home/alert_banner.dart
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../alerts/view/alert_details_screen.dart';
import '../../../../alerts/models/alert_model.dart';
import '../../view_model/home_viewmodel.dart';
import '../common/scale_on_tap.dart';

class AlertBanner extends StatelessWidget {
  final HomeViewModel vm;

  const AlertBanner({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    if (!vm.dataLoaded) return const _AlertBannerSkeleton();

    final top = vm.topAlert;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (top == null) {
      return ScaleOnTap(
        onTap: () {
          vm.markAlertAsViewed(top!);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AlertDetailsScreen(alert: top)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A3A1A) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.primaryColor.withAlpha(60)),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withAlpha(isDark ? 25 : 12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_rounded,
                  color: theme.primaryColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Systems Healthy',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'AbhayaLibre',
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Soil parameters are within optimal ranges.',
                      style: TextStyle(
                        color: grayColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isCritical = top.severity == AlertSeverity.critical;
    final color = isCritical ? redColor : orangeColor;
    final bg = isCritical
        ? (isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFFEBEE))
        : (isDark ? const Color(0xFF3A2F1A) : const Color(0xFFFFF8E1));

    return ScaleOnTap(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlertDetailsScreen(
            alert: GeneratedAlert(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: '${top.paramName} Alert',
              description: top.description,
              severity: isCritical
                  ? AlertSeverity.critical
                  : AlertSeverity.warning,
              paramName: top.paramName,
              value: top.value,
              unit: top.unit,
              recommendation: top.recommendation,
              icon: Icons.warning_amber_rounded,
              timestamp: DateTime.now(),
            ),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(70), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(isDark ? 35 : 20),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isCritical ? 'CRITICAL' : 'WARNING',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      if (vm.totalAlerts > 1) ...[
                        const SizedBox(width: 6),
                        Text(
                          '+${vm.totalAlerts - 1} more',
                          style: const TextStyle(
                            color: grayColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    top.paramName,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${top.value.toStringAsFixed(top.value < 10 ? 2 : 1)} ${top.unit}',
                    style: const TextStyle(
                      color: grayColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: grayColor, size: 22),
          ],
        ),
      ),
    );
  }
}

class _AlertBannerSkeleton extends StatelessWidget {
  const _AlertBannerSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 80,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.onSurface.withAlpha(30)
              : Colors.grey.withAlpha(40),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 14,
                  width: 140,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 200,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2E2E2E)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
