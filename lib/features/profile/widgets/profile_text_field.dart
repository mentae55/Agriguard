import 'package:flutter/material.dart';

class ProfileTextField extends StatelessWidget {
  final String label;
  final String initialValue;
  final bool isEmail;
  final bool readOnly;
  final TextInputType keyboardType;
  final Function(String?)? onSaved;
  final String? Function(String?)? validator;

  const ProfileTextField({
    super.key,
    required this.label,
    required this.initialValue,
    this.isEmail = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.onSaved,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withAlpha(150),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          readOnly: readOnly,
          style: TextStyle(
             fontSize: 16,
             fontWeight: FontWeight.w700,
             color: readOnly
                 ? theme.colorScheme.onSurface.withAlpha(120)
                 : theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? theme.colorScheme.tertiary : const Color(0xFFF1EFE9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          keyboardType: isEmail ? TextInputType.emailAddress : keyboardType,
          onSaved: onSaved,
          validator: validator,
        ),
      ],
    );
  }
}
