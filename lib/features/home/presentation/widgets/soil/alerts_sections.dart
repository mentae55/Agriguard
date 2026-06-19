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

    final sortedAlerts = List<SoilAlert>.from(latest.alerts);
    sortedAlerts.sort((a, b) {
      final sA = _severityScore(a.severity);
      final sB = _severityScore(b.severity);
      return sA.compareTo(sB); // high first (lower score)
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Active Alerts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'AbhayaLibre'),
        ),
        const SizedBox(height: 12),
        ...sortedAlerts.map((alert) => _buildAlertTile(alert)),
      ],
    );
  }

  int _severityScore(String severity) {
    switch (severity.toLowerCase()) {
      case 'high': return 1;
      case 'medium': return 2;
      case 'low': return 3;
      default: return 4;
    }
  }

  Widget _buildAlertTile(SoilAlert alert) {
    Color color;
    IconData icon;
    switch (alert.severity.toLowerCase()) {
      case 'high':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case 'low':
        color = Colors.amber;
        icon = Icons.info;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          alert.parameter.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(alert.message),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}