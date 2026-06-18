// ============================================================
// group_probability_chart.dart
// ============================================================
import 'package:flutter/material.dart';
import '../../data/models/spectral_prediction.dart';

class GroupProbabilityChart extends StatelessWidget {
  final SpectralPrediction prediction;
  const GroupProbabilityChart({super.key, required this.prediction});

  Color _groupColor(String key) {
    switch (key.toLowerCase()) {
      case 'fungal':         return const Color(0xFFFF7043);
      case 'viral':          return const Color(0xFF7E57C2);
      case 'pest_bacterial': return const Color(0xFFEF5350);
      default:               return const Color(0xFF66785F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final probs = prediction.allGroupProbs;

    // Fallback: use predictedGroup if map empty
    final entries = probs.isNotEmpty
        ? probs.entries.toList()
        : [MapEntry(prediction.predictedGroup, prediction.groupConfidence)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 8),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Group Probability',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'AbhayaLibre')),
          const SizedBox(height: 16),
          ...entries.map((e) {
            final color = _groupColor(e.key);
            final pct = (e.value * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface)),
                      Text('$pct%',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: color,
                              fontFamily: 'AbhayaLibre')),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: e.value.clamp(0.0, 1.0)),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, __) => LinearProgressIndicator(
                        value: val,
                        minHeight: 10,
                        backgroundColor: color.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
