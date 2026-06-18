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

  // New persistent history fields
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final bool isResolved;
  final String historyId;

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
    DateTime? createdAt,
    DateTime? updatedAt,
    this.resolvedAt,
    this.isResolved = false,
    this.historyId = '',
  })  : createdAt = createdAt ?? timestamp,
        updatedAt = updatedAt ?? timestamp;

  GeneratedAlert copyWith({
    String? id,
    String? title,
    String? description,
    AlertSeverity? severity,
    String? paramName,
    double? value,
    String? unit,
    String? recommendation,
    IconData? icon,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    bool? isResolved,
    String? historyId,
  }) {
    return GeneratedAlert(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      paramName: paramName ?? this.paramName,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      recommendation: recommendation ?? this.recommendation,
      icon: icon ?? this.icon,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      isResolved: isResolved ?? this.isResolved,
      historyId: historyId ?? this.historyId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity.name,
      'paramName': paramName,
      'value': value,
      'unit': unit,
      'recommendation': recommendation,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'isResolved': isResolved,
      'historyId': historyId,
    };
  }

  factory GeneratedAlert.fromJson(Map<String, dynamic> json) {
    return GeneratedAlert(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.warning,
      ),
      paramName: json['paramName'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      recommendation: json['recommendation'] as String,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.parse(json['timestamp'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.parse(json['timestamp'] as String),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      isResolved: json['isResolved'] as bool? ?? false,
      historyId: json['historyId'] as String? ?? '',
    );
  }
}