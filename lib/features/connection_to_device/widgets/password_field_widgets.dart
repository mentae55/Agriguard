import 'package:flutter/material.dart';
import '../../../core/core.dart';

class PasswordFieldWidgets extends StatefulWidget {
  final TextEditingController controller;
  const PasswordFieldWidgets({super.key, required this.controller});

  @override
  State<PasswordFieldWidgets> createState() => _PasswordFieldWidgetsState();
}

class _PasswordFieldWidgetsState extends State<PasswordFieldWidgets> {
  bool isPasswordHidden = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withAlpha(isDark ? 12 : 8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: isPasswordHidden,
        style: TextStyle(
          fontFamily: 'AbhayaLibre',
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
        validator: (v) =>
            (v == null || v.isEmpty) ? 'Please enter your password' : null,
        decoration: InputDecoration(
          hintText: 'Enter WiFi password',
          hintStyle: TextStyle(
            color: grayColor.withOpacity(0.6),
            fontFamily: 'AbhayaLibre',
          ),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: primaryColor,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isPasswordHidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: grayColor,
              size: 20,
            ),
            onPressed: () =>
                setState(() => isPasswordHidden = !isPasswordHidden),
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? theme.colorScheme.onSurface.withAlpha(30) : const Color(0xFFE2E8E4),
              width: 1.2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? theme.colorScheme.onSurface.withAlpha(30) : const Color(0xFFE2E8E4),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: redColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
