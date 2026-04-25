import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class CustomTextFiled extends StatelessWidget {
  final String? hintText;
  final String? title;
  final String? labelText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final VoidCallback? onPressed;

  const CustomTextFiled({
    super.key,
    this.hintText,
    this.title,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    required this.obscureText,
    this.controller,
    this.validator,
    this.onChanged,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          SizedBox(height: 10),
          TextFormField(
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: gray88Color),
              labelText: labelText,
              prefixIcon: Icon(prefixIcon, color: primaryColor),
              suffixIcon: IconButton(
                icon:  Icon(suffixIcon, color: primaryColor),
                onPressed: onPressed,
              ),
              filled: true,
              fillColor: secondaryColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            obscureText: obscureText,
            controller: controller,
            validator: validator,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
