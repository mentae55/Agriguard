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
    return GestureDetector(
      onTap: isSending ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSending ? primaryColor.withOpacity(0.5) : primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSending
              ? []
              : [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSending) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
            ] else ...[
              const Icon(Icons.wifi_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              isSending ? 'Connecting...' : 'Connect',
              style: const TextStyle(
                color: Colors.white,
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
