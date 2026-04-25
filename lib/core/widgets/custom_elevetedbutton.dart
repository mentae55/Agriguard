import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
class CustomElevatedButton extends StatelessWidget {
  final void Function()? onPressed;
  final String text;

  const CustomElevatedButton({
    super.key,
    required this.text, this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: Size(double.infinity, 50),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 25,
            color: whiteColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'AbhayaLibre',

          ),
        ),
      ),
    );
  }
}
