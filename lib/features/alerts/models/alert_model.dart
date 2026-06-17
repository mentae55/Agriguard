import 'package:flutter/material.dart';

enum AlertSeverity { critical, warning, info }

class GeneratedAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final String paramName;
  final double value;
  final String unit;
  final String recommendation;
  final IconData icon;
  final DateTime timestamp;

  const GeneratedAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.paramName,
    required this.value,
    required this.unit,
    required this.recommendation,
    required this.icon,
    required this.timestamp,
  });
}