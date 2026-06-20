// lib/presentation/widgets/home/device_status_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../view_model/home_viewmodel.dart';

class DeviceStatusCard extends StatelessWidget {
  final HomeViewModel vm;
  const DeviceStatusCard({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final statusLabel = vm.soilStatus != null
        ? vm.soilStatus![0].toUpperCase() + vm.soilStatus!.substring(1)
        : 'Loading…';
    final statusColor = vm.soilStatus != null
        ? grayColor
        : vm.soilStatus == 'healthy'
        ? theme.primaryColor
        : vm.soilStatus == 'warning'
        ? orangeColor
        : redColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark
                ? colorScheme.onSurface.withAlpha(30)
                : Colors.grey.withAlpha(40),
            width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 6),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SvgPicture.asset(
                  'assets/app_images/icons/logo.svg',
                  height: 38,),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AgriGuard Robot',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'AbhayaLibre',
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Active & Transmitting',
                      style: TextStyle(
                        fontSize: 11,
                        color: grayColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withAlpha(60)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'AbhayaLibre',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatusChip(
                  Icons.battery_charging_full_rounded, '70%', 'Battery', theme.primaryColor),
              _StatusChip(
                  Icons.sensors_rounded, 'ON', 'Sensors', const Color(0xFF4ADE80)),
              _StatusChip(
                  Icons.wifi_rounded, 'Live', 'Signal', const Color(0xFF5B9BD5)),
              _StatusChip(
                  Icons.thermostat_rounded,
                  vm.soilTemperature != null
                      ? '${vm.soilTemperature!.toStringAsFixed(0)}°'
                      : '--',
                  'Temp',
                  vm.soilTemperature != null
                      ? vm.getTempColor(vm.soilTemperature!)
                      : grayColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatusChip(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: grayColor,
          ),
        ),
      ],
    );
  }
}