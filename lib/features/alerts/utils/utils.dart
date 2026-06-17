
import 'package:flutter/material.dart';
import 'package:agriguard_project/core/core.dart';
import '../models/alert_model.dart';

class AlertFormatters {
  const AlertFormatters._();

  static Color severityColor(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return redColor;
      case AlertSeverity.warning:
        return orangeColor;
      case AlertSeverity.info:
        return primaryColor;
    }
  }

  static Color severityBg(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return const Color(0xFFFFEBEE);
      case AlertSeverity.warning:
        return const Color(0xFFFFF8E1);
      case AlertSeverity.info:
        return const Color(0xFFF0FDF4);
    }
  }

  static String severityLabel(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return 'CRITICAL';
      case AlertSeverity.warning:
        return 'WARNING';
      case AlertSeverity.info:
        return 'HEALTHY';
    }
  }

  static String formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, $h:$m';
  }
}