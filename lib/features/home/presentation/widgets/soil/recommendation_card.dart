// lib/features/home/presentation/widgets/soil/recommendation_card.dart
import 'package:flutter/material.dart';
import '../../view_model/soil_analysis_viewmodel.dart';
import 'package:agriguard_project/core/constants/app_colors.dart';

class RecommendationCard extends StatelessWidget {
  final SoilAnalysisViewModel vm;

  const RecommendationCard({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final latest = vm.latest;
    final rec = latest?.recommendation;

    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Recommended Action',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (rec == null)
              const Text(
                'No recommendation available',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              )
            else ...[
              Text(
                rec.primaryAction,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: rec.confidence,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      color: primaryColor,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(rec.confidence * 100).toInt()}% confidence',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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