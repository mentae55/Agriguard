// lib/features/home/presentation/widgets/soil/gauge_card.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../view_model/soil_analysis_viewmodel.dart';

class GaugesGrid extends StatelessWidget {
  final SoilAnalysisViewModel vm;

  const GaugesGrid({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    const params = [
      'moisture', 'ph', 'nitrogen', 'phosphorus',
      'potassium', 'temperature', 'ec', 'organic_matter',
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: params.length,
      itemBuilder: (context, index) => GaugeCard(param: params[index], vm: vm),
    );
  }
}

class GaugeCard extends StatelessWidget {
  final String param;
  final SoilAnalysisViewModel vm;

  const GaugeCard({super.key, required this.param, required this.vm});

  /// Maps a sensor value to a 0–1 fill proportion using a display range that is
  /// slightly wider than the safe range so the arc can show both under- and
  /// over-range visually.
  double _fillProportion(double value) {
    final range = SoilAnalysisViewModel.safeRanges[param];
    if (range == null) return 0.5;

    final safeMin = range[0];
    final safeMax = range[1];
    final span = safeMax - safeMin;

    // Display window: safe range ± 30 % of the span
    final displayMin = safeMin - span * 0.3;
    final displayMax = safeMax + span * 0.3;
    final displaySpan = displayMax - displayMin;

    return ((value - displayMin) / displaySpan).clamp(0.05, 0.95);
  }

  @override
  Widget build(BuildContext context) {
    final latest = vm.latest;
    double? value;
    String unit = '';

    if (latest != null && latest.readings.containsKey(param)) {
      value = latest.readings[param]!.value;
      unit = latest.readings[param]!.unit;
    }

    final color = value != null ? vm.getGaugeColor(param, value) : Colors.grey;
    final fill = value != null ? _fillProportion(value) : 0.0;

    final label = param.replaceAll('_', ' ').toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            width: 80,
            child: CustomPaint(
              painter: _ArcGaugePainter(color: color, fillProportion: fill),
              child: Center(
                child: Text(
                  value != null ? value.toStringAsFixed(1) : '--',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            unit,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final Color color;
  final double fillProportion; // 0.0 – 1.0

  _ArcGaugePainter({required this.color, required this.fillProportion});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    const startAngle = 3 * pi / 4;
    const sweepAngle = 3 * pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * fillProportion,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter old) =>
      old.color != color || old.fillProportion != fillProportion;
}