// lib/presentation/widgets/common/section_label.dart
import 'package:flutter/material.dart';
import 'package:agriguard_project/core/core.dart';

class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.displayMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        fontFamily: 'AbhayaLibre',
        letterSpacing: -0.3,
      ) ??
          TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;

  const SectionHeader({super.key, required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 18),
          ),
          const SizedBox(width: 10),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}