// lib/presentation/widgets/home/live_stats_row.dart
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../view/soil_analysis_screen.dart';
import '../../view_model/home_viewmodel.dart';
import '../common/stat_card.dart';

class LiveStatsRow extends StatelessWidget {
  final HomeViewModel vm;
  const LiveStatsRow({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: vm.dataLoaded && vm.soilTemperature != null
                ? vm.getTempIcon(vm.soilTemperature!)
                : Icons.thermostat_rounded,
            iconColor: vm.dataLoaded && vm.soilTemperature != null
                ? vm.getTempColor(vm.soilTemperature!)
                : grayColor,
            label: 'Soil Temp',
            value: vm.dataLoaded && vm.soilTemperature != null
                ? '${vm.soilTemperature!.toStringAsFixed(1)}°C'
                : '--',
            isLoading: !vm.dataLoaded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SoilAnalysisScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF5B9BD5),
            label: 'Moisture',
            value: vm.dataLoaded && vm.soilMoisture != null
                ? '${vm.soilMoisture!.toStringAsFixed(1)}%'
                : '--',
            isLoading: !vm.dataLoaded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SoilAnalysisScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.notifications_rounded,
            iconColor: vm.criticalCount > 0
                ? redColor
                : (vm.totalAlerts > 0 ? orangeColor : primaryColor),
            label: 'Alerts',
            value: vm.dataLoaded ? '${vm.totalAlerts}' : '--',
            isLoading: !vm.dataLoaded,
            badge: vm.criticalCount > 0 ? '${vm.criticalCount}' : null,
            onTap: () => vm.setNavIndex(1),
          ),
        ),
      ],
    );
  }
}