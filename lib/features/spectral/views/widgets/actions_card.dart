// ============================================================
// actions_card.dart
// ============================================================
import 'package:flutter/material.dart';
import '../../data/models/spectral_prediction.dart';

class ActionsCard extends StatelessWidget {
  final SpectralPrediction prediction;
  const ActionsCard({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final actions = prediction.actions;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF66785F).withAlpha(isDark ? 50 : 30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.checklist_rounded,
                    color: Color(0xFF66785F), size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Recommended Actions',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'AbhayaLibre')),
            ],
          ),
          const SizedBox(height: 14),
          if (actions.isEmpty)
            const Text('No specific actions required.',
                style: TextStyle(color: Colors.grey, fontSize: 13))
          else
            ...actions.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final text = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFF66785F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text('$idx',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(text,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface
                                  .withAlpha(200),
                              height: 1.4)),
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
