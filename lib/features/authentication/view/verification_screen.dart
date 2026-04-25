import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_project/core/core.dart';
import '../view_model/user_view_model.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'AbhayaLibre', fontWeight: FontWeight.w700)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F3),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.35,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/app_images/images/plant.png',
              fit: BoxFit.cover,
              height: size.height * 0.22,
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Back
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor, size: 18),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Animated email icon
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withOpacity(0.1),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(Icons.mark_email_read_outlined, color: primaryColor, size: 52),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      'Check Your Email',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'AbhayaLibre',
                        color: blackColor,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'We sent a reset link to',
                      style: TextStyle(fontSize: 15, fontFamily: 'AbhayaLibre', fontWeight: FontWeight.w600, color: grayColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email,
                      style: TextStyle(fontSize: 15, fontFamily: 'AbhayaLibre', fontWeight: FontWeight.w900, color: primaryColor),
                    ),

                    const SizedBox(height: 32),

                    // Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6))],
                      ),
                      child: Column(
                        children: [
                          // Step indicators
                          _buildStep(Icons.email_outlined, 'Open your email app'),
                          const SizedBox(height: 12),
                          _buildStep(Icons.link_rounded, 'Tap the reset link'),
                          const SizedBox(height: 12),
                          _buildStep(Icons.lock_open_outlined, 'Create a new password'),

                          const SizedBox(height: 24),

                          // Confirm button
                          GestureDetector(
                            onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))],
                              ),
                              child: const Center(
                                child: Text(
                                  'Done',
                                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, fontFamily: 'AbhayaLibre'),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Resend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Didn't receive it?",
                                style: TextStyle(color: grayColor, fontSize: 14, fontFamily: 'AbhayaLibre', fontWeight: FontWeight.w700),
                              ),
                              TextButton(
                                onPressed: authViewModel.isLoading
                                    ? null
                                    : () async {
                                  await authViewModel.resetPassword(widget.email);
                                  if (authViewModel.errorMessage != null) {
                                    _showSnackBar(authViewModel.errorMessage!, redColor);
                                  } else {
                                    _showSnackBar('Email sent again!', primaryColor);
                                  }
                                },
                                style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 4)),
                                child: Text(
                                  authViewModel.isLoading ? 'Sending...' : 'Resend',
                                  style: TextStyle(
                                    color: authViewModel.isLoading ? grayColor : primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'AbhayaLibre',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Change Email',
                        style: TextStyle(color: grayColor, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'AbhayaLibre'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (authViewModel.isLoading)
            Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildStep(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontFamily: 'AbhayaLibre',
            fontWeight: FontWeight.w700,
            color: blackColor.withOpacity(0.75),
          ),
        ),
      ],
    );
  }
}