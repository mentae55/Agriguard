// lib/features/home/presentation/widgets/soil/gauge_card.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../view_model/soil_analysis_viewmodel.dart';
import 'package:agriguard_project/features/home/data/model/soil_analysis_model.dart';

class GaugesGrid extends StatelessWidget {
  final SoilAnalysisViewModel vm;

  const GaugesGrid({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final params = [
      'moisture', 'ph', 'nitrogen', 'phosphorus',
      'potassium', 'temperature', 'ec', 'organic_matter'
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
      itemBuilder: (context, index) {
        return GaugeCard(param: params[index], vm: vm);
      },
    );
  }
}

class GaugeCard extends StatelessWidget {
  final String param;
  final SoilAnalysisViewModel vm;

  const GaugeCard({super.key, required this.param, required this.vm});

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

    String label = param.replaceAll('_', ' ').toUpperCase();
    
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
          )
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
              painter: _ArcGaugePainter(color: color, value: value),
              child: Center(
                child: Text(
                  value != null ? value.toStringAsFixed(1) : '--',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
  final double? value;

  _ArcGaugePainter({required this.color, this.value});

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

    if (value != null) {
      // Dummy visual fill proportion just for the UI
      // In a real app we'd map value min-max to 0-1
      final fillProportion = 0.6; // hardcoded for visual or map to 0.1-0.9 based on safe ranges
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * fillProportion,
        false,
        valuePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.value != value;
  }
}