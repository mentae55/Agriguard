import 'package:flutter/material.dart';
import '../../../core/core.dart';

class StatusCardWidget extends StatelessWidget {
  final String _statusMessage;
  final bool _isSuccess;
  final bool _isSending;

  const StatusCardWidget(
      this._statusMessage, this._isSuccess, this._isSending, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color cardColor;
    Color borderColor;
    Color textColor;

    if (_isSuccess) {
      cardColor = isDark ? Colors.green.withAlpha(25) : Colors.green.withValues(alpha: 0.08);
      borderColor = isDark ? Colors.green.withAlpha(60) : Colors.green.withValues(alpha: 0.3);
      textColor = isDark ? Colors.green.shade400 : Colors.green.shade800;
    } else if (_isSending) {
      cardColor = isDark ? primaryColor.withAlpha(25) : primaryColor.withValues(alpha: 0.06);
      borderColor = isDark ? primaryColor.withAlpha(60) : primaryColor.withValues(alpha: 0.2);
      textColor = isDark ? Colors.green.shade300 : primaryColor;
    } else {
      cardColor = isDark ? Colors.orange.withAlpha(25) : Colors.orange.withValues(alpha: 0.08);
      borderColor = isDark ? Colors.orange.withAlpha(60) : Colors.orange.withValues(alpha: 0.3);
      textColor = isDark ? Colors.orange.shade400 : Colors.orange.shade800;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          if (_isSending)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor,
              ),
            )
          else
            Icon(
              _isSuccess
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
              color: textColor,
              size: 18,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontFamily: 'AbhayaLibre',
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
