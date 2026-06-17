import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import 'package:agriguard_project/core/core.dart';

import '../utils/utils.dart';

class AlertDetailsScreen extends StatelessWidget {
  final GeneratedAlert alert;

  const AlertDetailsScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = AlertFormatters.severityColor(alert.severity);
    final bg = AlertFormatters.severityBg(alert.severity);
    final label = AlertFormatters.severityLabel(alert.severity);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        title: Text(
          'Alert Details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            fontSize: 22,
          ),
        ),
        backgroundColor: secondaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_return_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.smart_toy_rounded, color: primaryColor, size: 30),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 20, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title card ──────────────────────────────────────
            _buildTitleCard(color, bg, label),
            SizedBox(height: 20),

            // ── Live reading chip ───────────────────────────────
            if (alert.value > 0) ...[
              _buildReadingChip(color, bg),
              SizedBox(height: 20),
            ],

            // ── Description ─────────────────────────────────────
            _buildDescriptionCard(),
            SizedBox(height: 16),

            // ── Recommendations ─────────────────────────────────
            _buildRecommendationsCard(),
            SizedBox(height: 16),

            // ── What to monitor next ────────────────────────────
            _buildNextStepsCard(),

            SizedBox(height: 24),

            // ── Bottom decoration ────────────────────────────────
            Align(
              alignment: Alignment.bottomRight,
              child: Opacity(
                opacity: 0.4,
                child: Image.asset(
                  'assets/app_images/images/plant.png',
                  height: 80,
                  errorBuilder: (ctx2, err, st) => SizedBox(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleCard(Color color, Color bg, String label) {
    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(70), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(alert.icon, size: 15, color: color),
                SizedBox(width: 6),
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
          SizedBox(height: 14),

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
          SizedBox(height: 12),

          // Timestamp + param
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 13, color: grayColor),
              SizedBox(width: 4),
              Text(
                'Detected: ${AlertFormatters.formatTime(alert.timestamp)}',
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

  Widget _buildReadingChip(Color color, Color bg) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(alert.icon, color: color, size: 28),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.paramName,
                style: TextStyle(
                  color: grayColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
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
            children: [
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

  Widget _buildDescriptionCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Diagnosis', Icons.biotech_outlined),
          SizedBox(height: 12),
          Text(
            alert.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87.withAlpha(200),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final recommendations = _parseRecommendations(alert.recommendation);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withAlpha(60),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
              'Recommendations', Icons.lightbulb_outline_rounded),
          SizedBox(height: 16),
          ...recommendations.asMap().entries.map(
                (e) => Padding(
              padding: EdgeInsets.only(
                  bottom: e.key < recommendations.length - 1 ? 14 : 0),
              child: _buildRecItem(e.key + 1, e.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepsCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Next Steps', Icons.task_alt_rounded),
          SizedBox(height: 14),
          _buildNextStep(Icons.refresh_rounded,
              'Re-scan soil in ${alert.severity == AlertSeverity.critical ? '24–48 hours' : '3–7 days'} to verify improvement.'),
          SizedBox(height: 10),
          _buildNextStep(Icons.bar_chart_rounded,
              'Monitor trend in the Soil Analysis screen.'),
          SizedBox(height: 10),
          _buildNextStep(Icons.notifications_active_rounded,
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryColor, size: 16),
        ),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildRecItem(int index, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          margin: EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$index',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextStep(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryColor, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87.withAlpha(190),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}