// ============================================================
// disease_probability_section.dart
// ============================================================
import 'package:flutter/material.dart';
import '../../data/models/spectral_prediction.dart';

class DiseaseProbabilitySection extends StatelessWidget {
  final SpectralPrediction prediction;
  const DiseaseProbabilitySection({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final probs = prediction.allDiseaseProbs;

    if (probs.isEmpty) return const SizedBox.shrink();

    final sorted = probs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
          const Text('Estimated Disease Probabilities',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'AbhayaLibre')),
          const SizedBox(height: 4),
          const Text(
            'Confirm diagnosis when symptoms appear',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ...sorted.map((e) {
            final pct = (e.value * 100).toStringAsFixed(1);
            final isTop = e.key == prediction.likelyDisease;
            final barColor = isTop
                ? const Color(0xFF66785F)
                : theme.colorScheme.onSurface.withAlpha(80);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(e.key,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: isTop
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: isTop
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurface
                                        .withAlpha(160)),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Text('$pct%',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isTop
                                  ? const Color(0xFF66785F)
                                  : Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: e.value.clamp(0.0, 1.0)),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, __) => LinearProgressIndicator(
                        value: val,
                        minHeight: 7,
                        backgroundColor:
                            theme.colorScheme.onSurface.withAlpha(15),
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
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
