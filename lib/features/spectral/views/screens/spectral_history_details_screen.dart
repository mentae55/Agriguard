// ============================================================
// spectral_history_details_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import '../../data/models/spectral_history_entry.dart';

class SpectralHistoryDetailsScreen extends StatelessWidget {
  final SpectralHistoryEntry entry;

  const SpectralHistoryDetailsScreen({super.key, required this.entry});

  Color get _riskColor {
    switch (entry.riskLevel.toUpperCase()) {
      case 'HIGH':   return const Color(0xFFEF5350);
      case 'MEDIUM': return const Color(0xFFFFA726);
      default:       return const Color(0xFF66BB6A);
    }
  }

  IconData get _riskIcon {
    switch (entry.riskLevel.toUpperCase()) {
      case 'HIGH':   return Icons.warning_rounded;
      case 'MEDIUM': return Icons.warning_amber_rounded;
      default:       return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _riskColor;
    final formattedTime =
        '${entry.timestamp.day.toString().padLeft(2, '0')}/'
        '${entry.timestamp.month.toString().padLeft(2, '0')}/'
        '${entry.timestamp.year}  '
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Analysis Details',
            style: TextStyle(fontFamily: 'AbhayaLibre', fontWeight: FontWeight.w900)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF66785F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Risk Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withAlpha(80), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: color.withAlpha(isDark ? 40 : 25),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
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
                          color: color.withAlpha(isDark ? 40 : 25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_riskIcon, color: color, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Risk Level',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                              entry.riskLevel.toUpperCase(),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'AbhayaLibre',
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: color.withAlpha(isDark ? 40 : 25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.riskPercent,
                          style: TextStyle(
                              color: color,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'AbhayaLibre'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (entry.alertMessage.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withAlpha(isDark ? 25 : 15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: color, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(entry.alertMessage,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface.withAlpha(200))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Info block
            Container(
              padding: const EdgeInsets.all(20),
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
                  const Text('Details',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'AbhayaLibre')),
                  const SizedBox(height: 16),
                  _buildDetailRow('Plant ID', entry.plantId, theme),
                  const Divider(height: 24),
                  _buildDetailRow('Predicted Group', entry.predictedGroup, theme),
                  const Divider(height: 24),
                  _buildDetailRow('Likely Disease', entry.likelyDisease, theme),
                  const Divider(height: 24),
                  _buildDetailRow('Timestamp', formattedTime, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface)),
        ),
      ],
    );
  }
}
