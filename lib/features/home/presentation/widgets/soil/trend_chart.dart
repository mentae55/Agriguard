// lib/presentation/widgets/soil/trends_section.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../data/model/soil_model.dart';
import '../../view_model/soil_analysis_viewmodel.dart';

class TrendsSection extends StatelessWidget {
  final SoilAnalysisViewModel vm;
  const TrendsSection({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (vm.history.length < 2) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 5),
              blurRadius: isDark ? 8 : 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: primaryColor, strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              const Text(
                'Collecting data for trends...',
                style: TextStyle(
                  color: grayColor,
                  fontFamily: 'AbhayaLibre',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _LineChart(
          title: 'Moisture (%)',
          color: Colors.blue.shade400,
          values: vm.history.map((s) => s.reading.moisturePct).toList(),
          safeMin: 15,
          safeMax: 50,
        ),
        const SizedBox(height: 16),
        _LineChart(
          title: 'pH',
          color: Colors.purple.shade400,
          values: vm.history.map((s) => s.reading.ph).toList(),
          safeMin: 5.5,
          safeMax: 7.8,
        ),
        const SizedBox(height: 16),
        _NpkChart(history: vm.history),
        const SizedBox(height: 16),
        _LineChart(
          title: 'Temperature (°C)',
          color: Colors.orange.shade400,
          values: vm.history.map((s) => s.reading.temperatureC).toList(),
          safeMin: 8,
          safeMax: 38,
        ),
        const SizedBox(height: 16),
        _LineChart(
          title: 'EC (dS/m)',
          color: Colors.teal.shade400,
          values: vm.history.map((s) => s.reading.ecDsM).toList(),
          safeMin: 0.3,
          safeMax: 3.0,
        ),
      ],
    );
  }
}

class _LineChart extends StatelessWidget {
  final String title;
  final Color color;
  final List<double> values;
  final double safeMin;
  final double safeMax;

  const _LineChart({
    required this.title,
    required this.color,
    required this.values,
    required this.safeMin,
    required this.safeMax,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'AbhayaLibre',
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                values.last.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'AbhayaLibre',
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 80,
            child: CustomPaint(
              size: const Size(double.infinity, 80),
              painter: _LinePainter(
                values: values,
                color: color,
                safeMin: safeMin,
                safeMax: safeMax,
                surfaceColor: colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NpkChart extends StatelessWidget {
  final List<SoilSnapshot> history;
  const _NpkChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            'NPK (ppm)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontFamily: 'AbhayaLibre',
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Legend('N', Colors.green.shade600),
              const SizedBox(width: 12),
              _Legend('P', Colors.blue.shade400),
              const SizedBox(width: 12),
              _Legend('K', Colors.orange.shade400),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: CustomPaint(
              size: const Size(double.infinity, 80),
              painter: _NPKPainter(history: history),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: grayColor, fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double safeMin;
  final double safeMax;
  final Color surfaceColor;

  _LinePainter({
    required this.values,
    required this.color,
    required this.safeMin,
    required this.safeMax,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    double dataMin = values.reduce(math.min);
    double dataMax = values.reduce(math.max);
    final rangeMin = math.min(dataMin, safeMin) - 1;
    final rangeMax = math.max(dataMax, safeMax) + 1;
    final range = (rangeMax - rangeMin).clamp(0.001, double.infinity);

    double toY(double v) =>
        size.height - ((v - rangeMin) / range * size.height);

    final bandPaint = Paint()
      ..color = color.withAlpha(18)
      ..style = PaintingStyle.fill;
    final bandTop = toY(safeMax);
    final bandBottom = toY(safeMin);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, bandTop, size.width, bandBottom),
        const Radius.circular(4),
      ),
      bandPaint,
    );

    final dashPaint = Paint()
      ..color = color.withAlpha(40)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(0, bandTop), Offset(size.width, bandTop), dashPaint);
    canvas.drawLine(
        Offset(0, bandBottom), Offset(size.width, bandBottom), dashPaint);

    final step = size.width / (values.length - 1);
    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    for (int i = 0; i < values.length; i++) {
      fillPath.lineTo(i * step, toY(values[i]));
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withAlpha(40), color.withAlpha(5)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * step;
      final y = toY(values[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    for (int i = 0; i < values.length; i++) {
      final offset = Offset(i * step, toY(values[i]));
      canvas.drawCircle(offset, 3.5, dotBorderPaint);
      canvas.drawCircle(offset, 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.values.length != values.length ||
          (values.isNotEmpty && old.values.last != values.last);
}

class _NPKPainter extends CustomPainter {
  final List<SoilSnapshot> history;

  _NPKPainter({required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;

    final nValues = history.map((s) => s.reading.nitrogenPpm).toList();
    final pValues = history.map((s) => s.reading.phosphorusPpm).toList();
    final kValues = history.map((s) => s.reading.potassiumPpm).toList();

    final allValues = [...nValues, ...pValues, ...kValues];
    final dataMin = allValues.reduce(math.min);
    final dataMax = allValues.reduce(math.max);
    final rangeMin = dataMin - 5;
    final rangeMax = dataMax + 5;
    final range = (rangeMax - rangeMin).clamp(0.001, double.infinity);

    double toY(double v) =>
        size.height - ((v - rangeMin) / range * size.height);

    final step = size.width / (history.length - 1);

    void drawLine(List<double> vals, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final path = Path();
      for (int i = 0; i < vals.length; i++) {
        final x = i * step;
        final y = toY(vals[i]);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);

      if (vals.isNotEmpty) {
        final lastX = (vals.length - 1) * step;
        canvas.drawCircle(Offset(lastX, toY(vals.last)), 3, dotPaint);
      }
    }

    drawLine(nValues, Colors.green.shade600);
    drawLine(pValues, Colors.blue.shade400);
    drawLine(kValues, Colors.orange.shade400);
  }

  @override
  bool shouldRepaint(covariant _NPKPainter old) =>
      old.history.length != history.length;
}