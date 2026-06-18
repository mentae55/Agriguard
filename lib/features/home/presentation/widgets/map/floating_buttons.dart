// lib/presentation/widgets/map/floating_buttons.dart
import 'package:agriguard_project/core/core.dart';
import 'package:flutter/material.dart';


class FloatingButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String? tooltip;

  const FloatingButton({
    super.key,
    required this.onTap,
    required this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(radius16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.onSurface.withAlpha(isDark ? 15 : 10),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 26,
          ),
        ),
      ),
    );
  }
}