// lib/presentation/widgets/soil/recommendation_card.dart
import 'package:flutter/material.dart';
import '../../../data/model/soil_model.dart';
import '../../view_model/soil_analysis_viewmodel.dart';

class RecommendationCard extends StatelessWidget {
  final SoilAnalysisViewModel vm;
  final SoilSnapshot snap;
  const RecommendationCard({super.key, required this.vm, required this.snap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final sc = vm.statusColor(snap.soilStatus);
    final sb = vm.statusBg(snap.soilStatus, isDark: isDark);
    final pct = (snap.confidence * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: sb,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sc.withAlpha(60), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: sc.withAlpha(isDark ? 35 : 20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sc.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.agriculture_rounded, color: sc, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended Action',
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(160),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: sc.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$pct% confidence',
                        style: TextStyle(
                          color: sc,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            snap.primaryAction,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              fontFamily: 'AbhayaLibre',
              color: colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}