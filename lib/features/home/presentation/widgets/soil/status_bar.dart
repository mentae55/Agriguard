// lib/features/home/presentation/widgets/soil/status_bar.dart
import 'package:flutter/material.dart';
import 'package:agriguard_project/core/constants/app_colors.dart';
import '../../view_model/soil_analysis_viewmodel.dart';
import 'package:intl/intl.dart';

class SoilStatusBar extends StatelessWidget {
  final SoilAnalysisViewModel vm;

  const SoilStatusBar({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = vm.latest;
    
    final bool isConnected = latest != null && (vm.state == SoilState.loaded || vm.state == SoilState.refreshing);
    final dotColor = isConnected ? Colors.green : Colors.grey;

    String lastUpdatedStr = '--';
    if (latest != null) {
      lastUpdatedStr = DateFormat('MMM dd, hh:mm a').format(latest.timestamp);
    }
    
    int nextUpdateMin = vm.secondsUntilNextUpdate ~/ 60;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last updated: $lastUpdatedStr',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (vm.state == SoilState.refreshing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: vm.refreshNow,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            if (latest != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        maxLines: 3,
                        'Field: ${latest.fieldId}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        maxLines: 3,
                        'Device: ${latest.deviceId}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        maxLines:3 ,
                        'Next update in $nextUpdateMin min',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}