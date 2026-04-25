import 'package:agriguard_project/features/connection_to_device/view/select_device_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:agriguard_project/core/core.dart';
import 'package:provider/provider.dart';
import '../../authentication/view_model/user_view_model.dart';
import '../../onboarding/view/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      FirebaseAuth.instance.authStateChanges().first.then((user) {
        if (!mounted) return;
        if (user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SelectDeviceScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OnboardingScreen()),
          );
        }
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      body: Center(
        child: Lottie.asset('assets/app_images/animation/agri_guard.json'),
      ),
    );
  }
}
