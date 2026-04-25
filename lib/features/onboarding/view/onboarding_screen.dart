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
      skip: Text("Skip", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
      next: Text("Next", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
      done:  Text("Done", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
      dotsDecorator: DotsDecorator(
        size:  Size.zero,
        activeSize:  Size(width20, height5),
        activeColor: primaryColor,
        color: Colors.grey,
        spacing:  EdgeInsets.symmetric(horizontal: height5),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius50),
        ),
        shape: BoxBorder.all(color: grayColor, width: width2),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) =>  LoginScreen()),
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
        width: screenSize.width ,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),

            Positioned(
              bottom: 120,
              left: 25,
              right: 25,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "AbhayaLibre",
                        color: primaryColor,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    textAlign: TextAlign.center,
                    description,
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