import 'package:flutter/material.dart';
import '../../../core/core.dart';

class ConnectButtonWidget extends StatelessWidget {
  final bool isSending;
  final VoidCallback? onPressed;

  const ConnectButtonWidget({
    super.key,
    required this.isSending,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: isSending ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSending ? primaryColor.withValues(alpha: 0.5) : primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSending
              ? []
              : [
                  BoxShadow(
                    color: primaryColor.withAlpha(90),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSending) ...[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 10),
            ] else ...[
              Icon(Icons.wifi_rounded, color: theme.colorScheme.onPrimary, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              isSending ? 'Connecting...' : 'Connect',
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
