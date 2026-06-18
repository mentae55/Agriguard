// ============================================================
// plant_info_card.dart
// ============================================================
import 'package:flutter/material.dart';
import '../../data/models/spectral_prediction.dart';

class PlantInfoCard extends StatelessWidget {
  final SpectralPrediction prediction;
  const PlantInfoCard({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = prediction;
    final formattedTime =
        '${p.timestamp.day.toString().padLeft(2, '0')}/'
        '${p.timestamp.month.toString().padLeft(2, '0')}/'
        '${p.timestamp.year}  '
        '${p.timestamp.hour.toString().padLeft(2, '0')}:'
        '${p.timestamp.minute.toString().padLeft(2, '0')}';

    return _SpectralCard(
      isDark: isDark,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF66785F).withAlpha(isDark ? 60 : 30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.eco_rounded,
                color: Color(0xFF66785F), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plant Information',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                _InfoRow(
                    icon: Icons.tag_rounded,
                    label: 'Plant ID',
                    value: p.plantId),
                const SizedBox(height: 4),
                _InfoRow(
                    icon: Icons.access_time_rounded,
                    label: 'Last Scan',
                    value: formattedTime),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'AbhayaLibre',
                  color: theme.colorScheme.onSurface),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ============================================================
// predicted_group_card.dart
// ============================================================
class PredictedGroupCard extends StatelessWidget {
  final SpectralPrediction prediction;
  const PredictedGroupCard({super.key, required this.prediction});

  Color _groupColor(String group) {
    switch (group.toLowerCase()) {
      case 'fungal':        return const Color(0xFFFF7043);
      case 'viral':         return const Color(0xFF7E57C2);
      case 'pest_bacterial': return const Color(0xFFEF5350);
      default:              return const Color(0xFF66785F);
    }
  }

  IconData _groupIcon(String group) {
    switch (group.toLowerCase()) {
      case 'fungal':        return Icons.grain_rounded;
      case 'viral':         return Icons.coronavirus_rounded;
      case 'pest_bacterial': return Icons.bug_report_rounded;
      default:              return Icons.science_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = prediction;
    final color = _groupColor(p.predictedGroup);

    return _SpectralCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Predicted Group',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 50 : 30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_groupIcon(p.predictedGroup),
                    color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withAlpha(isDark ? 50 : 30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(p.predictedGroup,
                          style: TextStyle(
                              color: color,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'AbhayaLibre')),
                    ),
                    const SizedBox(height: 6),
                    Text('Confidence: ${p.groupPercent}',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withAlpha(150))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: p.groupConfidence),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 8,
                backgroundColor: color.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// likely_disease_card.dart
// ============================================================
class LikelyDiseaseCard extends StatelessWidget {
  final SpectralPrediction prediction;
  const LikelyDiseaseCard({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = prediction;

    return _SpectralCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Likely Disease',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey)),
          const SizedBox(height: 12),
          Text(p.likelyDisease,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'AbhayaLibre',
                  color: theme.colorScheme.onSurface)),
          const SizedBox(height: 6),
          Text('Confidence: ${p.diseasePercent}',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withAlpha(150))),
          if (p.likelyDiseaseMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(p.likelyDiseaseMessage,
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withAlpha(170))),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(isDark ? 35 : 20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withAlpha(80)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.amber, size: 15),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Indicative Only — Not a Confirmed Diagnosis',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Shared card container
// ============================================================
class _SpectralCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _SpectralCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
      child: child,
    );
  }
}
