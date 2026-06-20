// lib/features/home/presentation/widgets/soil/alerts_sections.dart
import 'package:flutter/material.dart';
import '../../view_model/soil_analysis_viewmodel.dart';
import 'package:agriguard_project/features/home/data/model/soil_analysis_model.dart';

class AlertsSection extends StatelessWidget {
  final SoilAnalysisViewModel vm;

  const AlertsSection({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final latest = vm.latest;
    if (latest == null) {
      return const Center(child: Text('No data available'));
    }

    if (latest.nAlerts == 0 || latest.alerts.isEmpty) {
      return Card(
        color: Colors.green.shade50,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.green.shade300),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text(
                'Soil conditions are healthy ✓',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort: critical first, then warning
    final sortedAlerts = List<SoilAlert>.from(latest.alerts)
      ..sort((a, b) => _severityScore(a.severity).compareTo(_severityScore(b.severity)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Active Alerts',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'AbhayaLibre'),
        ),
        const SizedBox(height: 12),
        ...sortedAlerts.map((alert) => _buildAlertTile(alert)),
      ],
    );
  }

  int _severityScore(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return 1;
      case 'warning':  return 2;
      default:         return 3;
    }
  }

  Widget _buildAlertTile(SoilAlert alert) {
    Color color;
    IconData icon;

    switch (alert.severity.toLowerCase()) {
      case 'critical':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'warning':
      default:
        color = Colors.amber;
        icon = Icons.warning_amber_rounded;
        break;
    }

    // Human-readable parameter label: "moisture_pct" → "Moisture"
    final label = alert.param
        .replaceAll('_pct', '')
        .replaceAll('_ppm', '')
        .replaceAll('_c', '')
        .replaceAll('_ds_m', '')
        .replaceAll('_', ' ')
        .toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                // Severity badge
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    alert.severity.toUpperCase(),
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Current value + status
            Row(
              children: [
                Text(
                  '${alert.value} ${alert.unit}',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    alert.status.toUpperCase(),
                    style: TextStyle(
                        color: color, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Recommendation text
            Text(
              alert.recommendation,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}