import 'package:flutter/material.dart';

class DashboardButton extends StatelessWidget {
  final VoidCallback onTap;

  const DashboardButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final buttonColor = isDark ? Colors.green.shade700 : Colors.green.shade600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_rounded, color: theme.colorScheme.onPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Go to Dashboard',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                fontFamily: 'AbhayaLibre',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
