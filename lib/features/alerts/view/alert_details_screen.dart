import 'package:flutter/material.dart';
import 'package:agriguard_project/core/core.dart';

class AlertDetailsScreen extends StatelessWidget {
  const AlertDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Alerts & Notifications',
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
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.smart_toy_rounded, color: primaryColor, size: 30),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDCFCE7), width: 2), // Pale green border
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Critical Nitrogen\nDeficiency',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Detected: 13Dec 10:15 AM',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Map Placeholder
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
                image: const DecorationImage(
                  image: AssetImage('assets/app_images/images/1.png'), // placeholder
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(220),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'View On Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recommendations
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                 color: const Color(0xFFF0FDF4),
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: const Color(0xFFDCFCE7), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommendations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildRecItem('1. Immediate Spot Fertilization', '-Apply nitrogen rich fertilizer (e.g., Urea)'),
                  const SizedBox(height: 16),
                  _buildRecItem('2. Schedule Follow-up Scan', '-Re-scan area in 3 days to verify uptake'),
                ],
              ),
            ),
            
            // Adding a little plant decoration at bottom like the design
            const SizedBox(height: 40),
            Align(
              alignment: Alignment.bottomRight,
              child: Opacity(
                 opacity: 0.5,
                 child: Image.asset(
                    'assets/app_images/images/plant.png',
                    height: 80,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                 ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecItem(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
             fontSize: 14,
             fontWeight: FontWeight.bold,
             color: Colors.black87,
             fontFamily: 'AbhayaLibre',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
             fontSize: 12,
             color: Colors.grey.shade600,
             fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
