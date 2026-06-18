// ============================================================
// risk_status_card.dart
// ============================================================
import 'package:flutter/material.dart';
import '../../data/models/spectral_prediction.dart';

class RiskStatusCard extends StatefulWidget {
  final SpectralPrediction prediction;
  const RiskStatusCard({super.key, required this.prediction});

  @override
  State<RiskStatusCard> createState() => _RiskStatusCardState();
}

class _RiskStatusCardState extends State<RiskStatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _riskColor {
    switch (widget.prediction.riskLevel.toUpperCase()) {
      case 'HIGH':   return const Color(0xFFEF5350);
      case 'MEDIUM': return const Color(0xFFFFA726);
      default:       return const Color(0xFF66BB6A);
    }
  }

  IconData get _riskIcon {
    switch (widget.prediction.riskLevel.toUpperCase()) {
      case 'HIGH':   return Icons.warning_rounded;
      case 'MEDIUM': return Icons.warning_amber_rounded;
      default:       return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = widget.prediction;
    final color = _riskColor;

    return Container(
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
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => Transform.scale(
                  scale: 0.85 + _controller.value * 0.15,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withAlpha(isDark ? 40 : 25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_riskIcon, color: color, size: 28),
                  ),
                ),
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
                      p.riskLevel.toUpperCase(),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 40 : 25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  p.riskPercent,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: p.riskProbability),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 10,
                backgroundColor: color.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          if (p.alertMessage.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color.withAlpha(isDark ? 25 : 15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(p.alertMessage,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface
                                .withAlpha(200))),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
