import 'package:flutter/material.dart';

import '../../../core/core.dart';

class StatusCardWidget extends StatelessWidget {
  String _statusMessage ;
  bool _isSuccess ;
  bool _isSending ;
  StatusCardWidget(
      this._statusMessage, this._isSuccess, this._isSending);

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    Color borderColor;
    Color textColor;
    if (_isSuccess) {
      cardColor = Colors.green.withOpacity(0.08);
      borderColor = Colors.green.withOpacity(0.3);
      textColor = Colors.green;
    } else if (_isSending) {
      cardColor = primaryColor.withOpacity(0.06);
      borderColor = primaryColor.withOpacity(0.2);
      textColor = primaryColor;
    } else {
      cardColor = Colors.orange.withOpacity(0.08);
      borderColor = Colors.orange.withOpacity(0.3);
      textColor = Colors.orange;
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
                color: primaryColor,
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
