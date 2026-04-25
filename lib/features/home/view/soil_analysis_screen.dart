import 'package:flutter/material.dart';
import 'package:agriguard_project/core/core.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class SoilAnalysisScreen extends StatelessWidget {
  const SoilAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_return_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Soil Analysis',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            fontSize: 24,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.smart_toy_rounded, color: primaryColor, size: 32),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Field Health Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDCFCE7), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Field\nHealth Soil',
                           style: TextStyle(
                             color: Color(0xFF1E3A8A), // Dark blue text from screenshot
                             fontSize: 20,
                             fontWeight: FontWeight.w900,
                             fontFamily: 'AbhayaLibre',
                             height: 1.2,
                           ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Overall: 6.5/10.0',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Custom Pie Chart
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: CustomPaint(
                      painter: _PieChartPainter(primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // PH, P, N Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusKnob(title: 'PH\n6.8\nNeutral', color: Colors.grey.shade500, value: 0.5),
                _buildStatusKnob(title: 'P\n120ppm\nAttention', color: Colors.red.shade400, value: 0.7),
                _buildStatusKnob(title: 'N\n180ppm\nLOW', color: Colors.red.shade700, value: 0.2),
              ],
            ),
            const SizedBox(height: 48),

            // Report Bar Chart
            const Text(
              'Report',
              style: TextStyle(
                 color: Color(0xFF1E3A8A),
                 fontSize: 22,
                 fontWeight: FontWeight.w900,
                 fontFamily: 'AbhayaLibre',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar('Sun', 0.6, false),
                  _buildBar('Mon', 0.8, false),
                  _buildBar('Tue', 0.4, false),
                  _buildBar('Wed', 0.9, true), // Active
                  _buildBar('Thu', 0.7, false),
                  _buildBar('Fri', 0.3, false),
                  _buildBar('Sat', 0.5, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusKnob({required String title, required Color color, required double value}) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F0E7), // pale green
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: title.contains('LOW') || title.contains('Attention') ? color : Colors.black87,
              fontFamily: 'AbhayaLibre',
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
               children: [
                 Expanded(
                   flex: (value * 10).toInt(),
                   child: Container(
                     decoration: BoxDecoration(
                       color: color,
                       borderRadius: BorderRadius.circular(5),
                     ),
                   ),
                 ),
                 Expanded(
                   flex: 10 - (value * 10).toInt(),
                   child: const SizedBox(),
                 ),
               ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double height, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 20,
          height: 120 * height,
          decoration: BoxDecoration(
            color: isActive ? primaryColor : primaryColor.withAlpha(140),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final Color primaryColor;
  _PieChartPainter(this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width, height: size.height);
    
    // Light slice
    final paintLight = Paint()
      ..color = primaryColor.withAlpha(120)
      ..style = PaintingStyle.fill;
    
    // Dark slice
    final paintDark = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // Draw full light circle first
    canvas.drawArc(rect, 0, math.pi * 2, true, paintLight);
    
    // Draw dark slice over it (e.g., 65% health)
    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.3, true, paintDark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
