import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import 'package:agriguard_project/core/core.dart';

import '../utils/utils.dart';

class AlertDetailsScreen extends StatelessWidget {
  final GeneratedAlert alert;

  const AlertDetailsScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = AlertFormatters.severityColor(alert.severity);
    final bg = AlertFormatters.severityBg(alert.severity, isDark: isDark);
    final label = AlertFormatters.severityLabel(alert.severity);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Alert Details',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            fontSize: 22,
          ),
        ),
        backgroundColor: colorScheme.secondary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_return_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.smart_toy_rounded, color: primaryColor, size: 30),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title card ──────────────────────────────────────
            _buildTitleCard(context, color, bg, label),
            const SizedBox(height: 20),

            // ── Live reading chip ───────────────────────────────
            if (alert.value > 0) ...[
              _buildReadingChip(context, color, bg),
              const SizedBox(height: 20),
            ],

            // ── Description ─────────────────────────────────────
            _buildDescriptionCard(context),
            const SizedBox(height: 16),

            // ── Recommendations ─────────────────────────────────
            _buildRecommendationsCard(context),
            const SizedBox(height: 16),

            // ── What to monitor next ────────────────────────────
            _buildNextStepsCard(context),

            const SizedBox(height: 24),

            // ── Bottom decoration ────────────────────────────────
            Align(
              alignment: Alignment.bottomRight,
              child: Opacity(
                opacity: 0.4,
                child: Image.asset(
                  'assets/app_images/images/plant.png',
                  height: 80,
                  errorBuilder: (ctx2, err, st) => const SizedBox(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleCard(BuildContext context, Color color, Color bg, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(isDark ? 90 : 70), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(40) : color.withAlpha(20),
            blurRadius: isDark ? 8 : 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(alert.icon, size: 15, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'AbhayaLibre',
                    letterSpacing: 0.8,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            alert.title,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontFamily: 'AbhayaLibre',
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Timestamp + param
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 13, color: grayColor),
              const SizedBox(width: 4),
              Text(
                'Detected: ${AlertFormatters.formatTime(alert.timestamp)}',
                style: const TextStyle(
                  color: grayColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadingChip(BuildContext context, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(alert.icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.paramName,
                style: const TextStyle(
                  color: grayColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${alert.value.toStringAsFixed(alert.value < 10 ? 2 : 1)} ${alert.unit}',
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'AbhayaLibre',
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                'Current',
                style: TextStyle(
                  color: grayColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Reading',
                style: TextStyle(
                  color: grayColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? colorScheme.onSurface.withAlpha(30) : Colors.grey.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 5),
            blurRadius: isDark ? 8 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Diagnosis', Icons.biotech_outlined),
          const SizedBox(height: 12),
          Text(
            alert.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: colorScheme.onSurface.withAlpha(200),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(BuildContext context) {
    final recommendations = _parseRecommendations(alert.recommendation);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A3A1A) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withAlpha(isDark ? 90 : 60),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(isDark ? 20 : 10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context,
              'Recommendations', Icons.lightbulb_outline_rounded),
          const SizedBox(height: 16),
          ...recommendations.asMap().entries.map(
                (e) => Padding(
              padding: EdgeInsets.only(
                  bottom: e.key < recommendations.length - 1 ? 14 : 0),
              child: _buildRecItem(context, e.key + 1, e.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepsCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? colorScheme.onSurface.withAlpha(30) : Colors.grey.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 5),
            blurRadius: isDark ? 8 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Next Steps', Icons.task_alt_rounded),
          const SizedBox(height: 14),
          _buildNextStep(context, Icons.refresh_rounded,
              'Re-scan soil in ${alert.severity == AlertSeverity.critical ? '24–48 hours' : '3–7 days'} to verify improvement.'),
          const SizedBox(height: 10),
          _buildNextStep(context, Icons.bar_chart_rounded,
              'Monitor trend in the Soil Analysis screen.'),
          const SizedBox(height: 10),
          _buildNextStep(context, Icons.notifications_active_rounded,
              'This alert auto-resolves when the condition returns to normal.'),
        ],
      ),
    );
  }

  List<String> _parseRecommendations(String rec) {
    final parts = rec
        .split(RegExp(r'\.\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.map((s) => s.endsWith('.') ? s : '$s.').toList();
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryColor, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildRecItem(BuildContext context, int index, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 1),
          decoration: const BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$index',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextStep(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withAlpha(190),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}