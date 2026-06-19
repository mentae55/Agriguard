// lib/features/home/data/model/soil_analysis_model.dart

class SoilParameterReading {
  final double value;
  final String unit;

  SoilParameterReading({
    required this.value,
    required this.unit,
  });

  factory SoilParameterReading.fromJson(Map<String, dynamic> json) {
    return SoilParameterReading(
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'unit': unit,
    };
  }
}

class SoilAlert {
  final String parameter;
  final String severity; // "high" | "medium" | "low"
  final String message;

  SoilAlert({
    required this.parameter,
    required this.severity,
    required this.message,
  });

  factory SoilAlert.fromJson(Map<String, dynamic> json) {
    return SoilAlert(
      parameter: json['parameter'] as String? ?? '--',
      severity: json['severity'] as String? ?? 'low',
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parameter': parameter,
      'severity': severity,
      'message': message,
    };
  }
}

class SoilRecommendation {
  final String primaryAction;
  final double confidence;

  SoilRecommendation({
    required this.primaryAction,
    required this.confidence,
  });

  factory SoilRecommendation.fromJson(Map<String, dynamic> json) {
    return SoilRecommendation(
      primaryAction: json['primary_action'] as String? ?? '--',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_action': primaryAction,
      'confidence': confidence,
    };
  }
}

class SoilReading {
  final String fieldId;
  final String deviceId;
  final DateTime timestamp;
  final Map<String, SoilParameterReading> readings;
  final List<SoilAlert> alerts;
  final int nAlerts;
  final SoilRecommendation? recommendation;

  SoilReading({
    required this.fieldId,
    required this.deviceId,
    required this.timestamp,
    required this.readings,
    required this.alerts,
    required this.nAlerts,
    this.recommendation,
  });

  factory SoilReading.fromJson(Map<String, dynamic> json) {
    final readingObj = json['reading'] as Map<String, dynamic>? ?? {};
    
    // Support both the new nested API structure and the old/local cache structure
    final Map<String, SoilParameterReading> parsedReadings = {};
    if (json.containsKey('readings')) {
      // Local cache format
      final readingsMap = json['readings'] as Map<String, dynamic>? ?? {};
      readingsMap.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          parsedReadings[key] = SoilParameterReading.fromJson(value);
        }
      });
    } else {
      // API format
      parsedReadings.addAll({
        'moisture': SoilParameterReading(value: (readingObj['moisture_pct'] as num?)?.toDouble() ?? 0.0, unit: '%'),
        'ph': SoilParameterReading(value: (readingObj['ph'] as num?)?.toDouble() ?? 0.0, unit: 'pH'),
        'nitrogen': SoilParameterReading(value: (readingObj['nitrogen_ppm'] as num?)?.toDouble() ?? 0.0, unit: 'ppm'),
        'phosphorus': SoilParameterReading(value: (readingObj['phosphorus_ppm'] as num?)?.toDouble() ?? 0.0, unit: 'ppm'),
        'potassium': SoilParameterReading(value: (readingObj['potassium_ppm'] as num?)?.toDouble() ?? 0.0, unit: 'ppm'),
        'temperature': SoilParameterReading(value: (readingObj['temperature_c'] as num?)?.toDouble() ?? 0.0, unit: '°C'),
        'ec': SoilParameterReading(value: (readingObj['ec_ds_m'] as num?)?.toDouble() ?? 0.0, unit: 'dS/m'),
        'organic_matter': SoilParameterReading(value: (readingObj['organic_matter'] as num?)?.toDouble() ?? 0.0, unit: '%'),
      });
    }

    final alertsList = json['alerts'] as List<dynamic>? ?? [];
    final parsedAlerts = alertsList
        .map((e) => SoilAlert.fromJson(e as Map<String, dynamic>))
        .toList();

    return SoilReading(
      fieldId: (readingObj['location_id'] as String?) ?? (json['field_id'] as String?) ?? '--',
      deviceId: (readingObj['device_id'] as String?) ?? (json['device_id'] as String?) ?? '--',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      readings: parsedReadings,
      alerts: parsedAlerts,
      nAlerts: json['n_alerts'] as int? ?? 0,
      recommendation: json['recommendation'] != null
          ? SoilRecommendation.fromJson(json['recommendation'] as Map<String, dynamic>)
          : SoilRecommendation(
              primaryAction: json['primary_action'] as String? ?? '--',
              confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field_id': fieldId,
      'device_id': deviceId,
      'timestamp': timestamp.toIso8601String(),
      'readings': readings.map((key, value) => MapEntry(key, value.toJson())),
      'alerts': alerts.map((e) => e.toJson()).toList(),
      'n_alerts': nAlerts,
      'recommendation': recommendation?.toJson(),
    };
  }
}
