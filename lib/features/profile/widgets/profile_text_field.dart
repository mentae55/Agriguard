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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          readOnly: readOnly,
          style: TextStyle(
             fontSize: 16,
             fontWeight: FontWeight.w700,
             color: readOnly ? Colors.grey.shade600 : Colors.black87,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF1EFE9), // Soft beige
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          keyboardType: isEmail ? TextInputType.emailAddress : keyboardType,
          onSaved: onSaved,
          validator: validator,
        ),
      ],
    );
  }
}
