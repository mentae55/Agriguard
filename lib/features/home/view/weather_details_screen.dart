import 'package:flutter/material.dart';
import 'package:agriguard_project/core/core.dart';
import 'dart:math' as math;

class WeatherDetailsScreen extends StatelessWidget {
  const WeatherDetailsScreen({super.key});

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
          'Weather',
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
      body: Stack(
        children: [
          // Background plant decoration at bottom right
          Align(
            alignment: Alignment.bottomRight,
            child: Opacity(
               opacity: 0.6,
               child: Image.asset(
                 'assets/app_images/images/plant.png',
                 height: 140,
                 errorBuilder: (_, __, ___) => const SizedBox(),
               ),
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Weather Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Seongnam-si',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'AbhayaLibre',
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '21° | Partly Cloudy',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.wb_sunny_rounded, color: Colors.yellow.shade600, size: 48),
                  ],
                ),
                const SizedBox(height: 24),

                // Temperature Range placeholder text
                Row(
                  children: [
                    Icon(Icons.device_thermostat_rounded, size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text(
                      'TEMPERATURE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 1.5),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  height: 2,
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),

                // Neumorphic Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildGridCard(
                        title: 'UV INDEX',
                        icon: Icons.wb_sunny_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             const Text(
                               '0',
                               style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black87),
                             ),
                             const Text(
                               'Low',
                               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
                             ),
                             const Spacer(),
                             Container(
                               height: 6,
                               decoration: BoxDecoration(
                                 borderRadius: BorderRadius.circular(3),
                                 gradient: LinearGradient(
                                   colors: [Colors.green, Colors.yellow, Colors.red, Colors.purple],
                                 ),
                               ),
                             ),
                             const SizedBox(height: 8),
                             Text(
                               'Low for the rest of the day.',
                               style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                             ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildGridCard(
                        title: 'SUNRISE',
                        icon: Icons.wb_twilight_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             const Text(
                               '6:28 AM',
                               style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87),
                             ),
                             const Spacer(),
                             // Simple sine wave representation
                             SizedBox(
                               height: 40,
                               width: double.infinity,
                               child: CustomPaint(
                                 painter: _SineWavePainter(),
                               ),
                             ),
                             const Spacer(),
                             Text(
                               'Sunset: 6:10 PM',
                               style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                             ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildGridCard(
                        title: 'WIND',
                        icon: Icons.air_rounded,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             // Simple Compass
                             Stack(
                               alignment: Alignment.center,
                               children: [
                                 Container(
                                   width: 80,
                                   height: 80,
                                   decoration: BoxDecoration(
                                     shape: BoxShape.circle,
                                     border: Border.all(color: Colors.grey.shade400, width: 1.5),
                                   ),
                                 ),
                                 Column(
                                   mainAxisSize: MainAxisSize.min,
                                   children: const [
                                     Text('1', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.0)),
                                     Text('m/s', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                                   ],
                                 ),
                                 const Positioned(top: 2, child: Text('N', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                 const Positioned(bottom: 2, child: Text('S', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                 const Positioned(left: 4, child: Text('W', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                 const Positioned(right: 4, child: Text('E', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                               ],
                             ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildGridCard(
                        title: 'RAINFALL',
                        icon: Icons.water_drop_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             const Text(
                               '0 mm',
                               style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
                             ),
                             const Text(
                               'in last 24h',
                               style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                             ),
                             const Spacer(),
                             Text(
                               '4 mm expected\nin next 24h.',
                               style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                             ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                     Expanded(
                      child: _buildGridCard(
                        title: 'FEELS LIKE',
                        icon: Icons.thermostat_auto_rounded,
                        height: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             const Text(
                               '73%',
                               style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
                             ),
                             const Spacer(),
                             Text(
                               'Similar to the\nactual\ntemperature',
                               style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                             ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildGridCard(
                        title: 'HUMIDITY',
                        icon: Icons.water_drop_rounded,
                        height: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             const Text(
                               '73%',
                               style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
                             ),
                             const Spacer(),
                             Text(
                               'The dew point is\n16° right now.',
                               style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                             ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard({required String title, required IconData icon, required Widget child, double height = 150}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F0E7), // pale mint/green
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 0.5),
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

class _SineWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height / 2);
    // Draw simple curve representing sun path
    path.quadraticBezierTo(size.width / 2, -size.height / 2, size.width, size.height / 2);
    
    // Draw horizon line
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), Paint()..color=Colors.grey.shade400..strokeWidth=1);
    canvas.drawPath(path, paint);

    // Sun dot
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.28), 4, Paint()..color=Colors.yellow.shade700);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
