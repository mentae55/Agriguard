import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import '../../authentication/view/login_screen.dart';
import 'package:agriguard_project/core/core.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return IntroductionScreen(
      pages: [
        _buildCustomPage(
          context,
          screenSize,
          imagePath: 'assets/app_images/images/1.png',
          title: "Welcome to the future of smart farming",
          description: "Your smart companion to monitor your land and ensure the best crop yield with ease.",
        ),
        _buildCustomPage(
          context,
          screenSize,
          imagePath: 'assets/app_images/images/2.png',
          title: "Track your Robot",
          description: "Discover the robot's geographic location and track its path moment by moment.",
        ),
        _buildCustomPage(
          context,
          screenSize,
          imagePath: 'assets/app_images/images/3.png',
          title: "Watch your soil around the clock",
          description: "Detect nutrient deficiencies and plant diseases as soon as they occur.",
        ),
      ],
      onDone: () => _navigateToHome(context),
      onSkip: () => _navigateToHome(context),
      showSkipButton: true,
      skip: Text(
        "Skip", 
        style: TextStyle(
          color: primaryColor, 
          fontWeight: FontWeight.w900,
          fontFamily: 'AbhayaLibre',
          fontSize: 16,
        )
      ),
      next: Text(
        "Next", 
        style: TextStyle(
          color: primaryColor, 
          fontWeight: FontWeight.w900,
          fontFamily: 'AbhayaLibre',
          fontSize: 16,
        )
      ),
      done: Text(
        "Done", 
        style: TextStyle(
          color: primaryColor, 
          fontWeight: FontWeight.w900,
          fontFamily: 'AbhayaLibre',
          fontSize: 16,
        )
      ),
      dotsDecorator: DotsDecorator(
        size: const Size(8, 8),
        activeSize: const Size(22, 8),
        activeColor: primaryColor,
        color: const Color(0xFFD0E0CC),
        spacing: EdgeInsets.symmetric(horizontal: 4),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  PageViewModel _buildCustomPage(
      BuildContext context,
      Size screenSize, {
        required String imagePath,
        required String title,
        required String description,
      }) {
    return PageViewModel(
      titleWidget: const SizedBox.shrink(),
      decoration: const PageDecoration(
        contentMargin: EdgeInsets.zero,
        imagePadding: EdgeInsets.zero,
        bodyPadding: EdgeInsets.zero,
      ),
      bodyWidget: SizedBox(
        height: screenSize.height * 0.9,
        width: screenSize.width,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),

            // Smooth linear gradient overlay to fade image into white at the bottom for readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.02),
                      Colors.white.withOpacity(0.6),
                      Colors.white,
                    ],
                    stops: const [0.0, 0.4, 0.72, 1.0],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 120,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "AbhayaLibre",
                      color: primaryColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "AbhayaLibre",
                      color: grayColor,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}