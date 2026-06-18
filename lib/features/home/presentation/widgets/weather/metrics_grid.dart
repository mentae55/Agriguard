// lib/presentation/widgets/weather/metrics_grid.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../view_model/weather_viewmodel.dart';

class MetricsGrid extends StatelessWidget {
  final WeatherViewModel vm;

  const MetricsGrid({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final data = vm.weatherData!;
    final uvDetails = vm.getUvDetails(data.uvIndex);
    final dewPoint = vm.calculateDewPoint(data.temp, data.humidity);

    double dayProgress = 0.0;
    bool isDaytime = false;
    try {
      if (data.sunrise.isNotEmpty && data.sunset.isNotEmpty) {
        final now = DateTime.now();
        final rise = DateTime.parse(data.sunrise);
        final set = DateTime.parse(data.sunset);
        isDaytime = now.isAfter(rise) && now.isBefore(set);
        if (isDaytime) {
          final totalSec = set.difference(rise).inSeconds;
          final currentSec = now.difference(rise).inSeconds;
          dayProgress = (currentSec / totalSec).clamp(0.0, 1.0);
        }
      }
    } catch (_) {}

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _MetricCard(
          title: 'UV INDEX',
          icon: Icons.wb_sunny_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    data.uvIndex.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    uvDetails['desc'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: uvDetails['color'] as Color,
                    ),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (data.uvIndex / 12).clamp(0.0, 1.0),
                  backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                  color: uvDetails['color'] as Color,
                  minHeight: 6,
                ),
              ),
              Text(
                'Max for today is ${data.uvIndex.toStringAsFixed(1)}.',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withAlpha(160),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _MetricCard(
          title: 'SUNRISE',
          icon: Icons.wb_twilight_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                vm.formatTimeOnly(data.sunrise),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 30,
                child: CustomPaint(
                  painter: _SunriseSunsetPainter(dayProgress, isDaytime, isDark: isDark),
                ),
              ),
              const Spacer(),
              Text(
                'Sunset: ${vm.formatTimeOnly(data.sunset)}',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withAlpha(160),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _MetricCard(
          title: 'WIND',
          icon: Icons.air_rounded,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.windSpeed.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'km/h',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                height: 64,
                child: CustomPaint(
                  painter: _CompassPainter(data.windDir, isDark: isDark, surfaceColor: colorScheme.surface),
                ),
              ),
            ],
          ),
        ),
        _MetricCard(
          title: 'HUMIDITY',
          icon: Icons.water_drop_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${data.humidity}%',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                'The dew point is\n${dewPoint.toStringAsFixed(1)}°C right now.',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withAlpha(160),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        _MetricCard(
          title: 'FEELS LIKE',
          icon: Icons.thermostat_auto_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${data.feelsLike.toStringAsFixed(0)}°C',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                data.feelsLike == data.temp
                    ? 'Similar to actual temp.'
                    : data.feelsLike > data.temp
                    ? 'Feels warmer than actual.'
                    : 'Feels cooler than actual.',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withAlpha(160),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        _MetricCard(
          title: 'RAINFALL',
          icon: Icons.umbrella_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${data.precipitation.toStringAsFixed(1)} mm',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              const Text(
                'current volume',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: grayColor,
                ),
              ),
              const Spacer(),
              Text(
                data.precipitation > 0
                    ? 'Light to moderate rain is falling.'
                    : 'No rain expected in next 2h.',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withAlpha(160),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _MetricCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(radius20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 4),
            blurRadius: isDark ? 6 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: grayColor),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: grayColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SunriseSunsetPainter extends CustomPainter {
  final double dayProgress;
  final bool isDaytime;
  final bool isDark;

  _SunriseSunsetPainter(this.dayProgress, this.isDaytime, {this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.8;

    final horizonPaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.grey.shade300
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), horizonPaint);

    final pathPaint = Paint()
      ..color = const Color(0xFF66785F).withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    path.moveTo(0, horizonY);
    path.quadraticBezierTo(size.width / 2, -size.height * 0.1, size.width, horizonY);
    canvas.drawPath(path, pathPaint);

    if (isDaytime) {
      final t = dayProgress.clamp(0.0, 1.0);
      final p0 = Offset(0, horizonY);
      final p1 = Offset(size.width / 2, -size.height * 0.1);
      final p2 = Offset(size.width, horizonY);

      final sunX = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
      final sunY = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;

      final sunPaint = Paint()
        ..color = Colors.yellow.shade700
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(sunX, sunY), 5, sunPaint);
      canvas.drawCircle(
        Offset(sunX, sunY),
        8,
        Paint()..color = Colors.yellow.shade700.withAlpha(50),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SunriseSunsetPainter oldDelegate) =>
      oldDelegate.dayProgress != dayProgress ||
          oldDelegate.isDaytime != isDaytime ||
          oldDelegate.isDark != isDark;
}

class _CompassPainter extends CustomPainter {
  final double directionDegrees;
  final bool isDark;
  final Color surfaceColor;

  _CompassPainter(this.directionDegrees, {this.isDark = false, required this.surfaceColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final circlePaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, circlePaint);

    final textStyle = TextStyle(
      fontSize: 8,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white38 : Colors.black45,
    );

    void drawText(String text, Offset pos) {
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    drawText('N', Offset(center.dx, center.dy - radius + 6));
    drawText('S', Offset(center.dx, center.dy + radius - 6));
    drawText('W', Offset(center.dx - radius + 6, center.dy));
    drawText('E', Offset(center.dx + radius - 6, center.dy));

    final needlePaint = Paint()
      ..color = const Color(0xFF66785F)
      ..style = PaintingStyle.fill;

    final angle = (directionDegrees - 90) * math.pi / 180;
    final needleLength = radius - 10;
    final needleWidth = 4.0;

    final tip = Offset(
      center.dx + needleLength * math.cos(angle),
      center.dy + needleLength * math.sin(angle),
    );
    final leftCorner = Offset(
      center.dx + needleWidth * math.cos(angle + math.pi / 2),
      center.dy + needleWidth * math.sin(angle + math.pi / 2),
    );
    final rightCorner = Offset(
      center.dx + needleWidth * math.cos(angle - math.pi / 2),
      center.dy + needleWidth * math.sin(angle - math.pi / 2),
    );

    final needlePath = Path();
    needlePath.moveTo(tip.dx, tip.dy);
    needlePath.lineTo(leftCorner.dx, leftCorner.dy);
    needlePath.lineTo(rightCorner.dx, rightCorner.dy);
    needlePath.close();

    canvas.drawPath(needlePath, needlePaint);
    canvas.drawCircle(center, 3, Paint()..color = surfaceColor);
    canvas.drawCircle(center, 1.5, Paint()..color = const Color(0xFF66785F));
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.directionDegrees != directionDegrees ||
          oldDelegate.isDark != isDark ||
          oldDelegate.surfaceColor != surfaceColor;
}