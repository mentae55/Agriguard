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

  Map<String, dynamic> toJson() => {'value': value, 'unit': unit};
}

class SoilAlert {
  final String param;       // e.g. "moisture_pct"
  final double value;       // current sensor value
  final String unit;        // e.g. "%"
  final String status;      // "low" | "high"
  final String severity;    // "warning" | "critical"
  final String recommendation;

  SoilAlert({
    required this.param,
    required this.value,
    required this.unit,
    required this.status,
    required this.severity,
    required this.recommendation,
  });

  factory SoilAlert.fromJson(Map<String, dynamic> json) {
    return SoilAlert(
      param: json['param'] as String? ?? '--',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      status: json['status'] as String? ?? '--',
      severity: json['severity'] as String? ?? 'warning',
      recommendation: json['recommendation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'param': param,
    'value': value,
    'unit': unit,
    'status': status,
    'severity': severity,
    'recommendation': recommendation,
  };
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

  Map<String, dynamic> toJson() => {
    'primary_action': primaryAction,
    'confidence': confidence,
  };
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

    // Support both the new nested API structure and the local cache structure
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
      // API format — map raw fields into display keys
      parsedReadings.addAll({
        'moisture': SoilParameterReading(
            value: (readingObj['moisture_pct'] as num?)?.toDouble() ?? 0.0,
            unit: '%'),
        'ph': SoilParameterReading(
            value: (readingObj['ph'] as num?)?.toDouble() ?? 0.0, unit: 'pH'),
        'nitrogen': SoilParameterReading(
            value: (readingObj['nitrogen_ppm'] as num?)?.toDouble() ?? 0.0,
            unit: 'ppm'),
        'phosphorus': SoilParameterReading(
            value: (readingObj['phosphorus_ppm'] as num?)?.toDouble() ?? 0.0,
            unit: 'ppm'),
        'potassium': SoilParameterReading(
            value: (readingObj['potassium_ppm'] as num?)?.toDouble() ?? 0.0,
            unit: 'ppm'),
        'temperature': SoilParameterReading(
            value: (readingObj['temperature_c'] as num?)?.toDouble() ?? 0.0,
            unit: '°C'),
        'ec': SoilParameterReading(
            value: (readingObj['ec_ds_m'] as num?)?.toDouble() ?? 0.0,
            unit: 'dS/m'),
        'organic_matter': SoilParameterReading(
            value: (readingObj['organic_matter'] as num?)?.toDouble() ?? 0.0,
            unit: '%'),
      });
    }

    final alertsList = json['alerts'] as List<dynamic>? ?? [];
    final parsedAlerts = alertsList
        .map((e) => SoilAlert.fromJson(e as Map<String, dynamic>))
        .toList();

    return SoilReading(
      fieldId: (readingObj['location_id'] as String?) ??
          (json['field_id'] as String?) ??
          '--',
      deviceId: (readingObj['device_id'] as String?) ??
          (json['device_id'] as String?) ??
          '--',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      readings: parsedReadings,
      alerts: parsedAlerts,
      nAlerts: json['n_alerts'] as int? ?? 0,
      recommendation: json['recommendation'] != null
          ? SoilRecommendation.fromJson(
          json['recommendation'] as Map<String, dynamic>)
          : SoilRecommendation(
        primaryAction: json['primary_action'] as String? ?? '--',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'field_id': fieldId,
    'device_id': deviceId,
    'timestamp': timestamp.toIso8601String(),
    'readings': readings.map((k, v) => MapEntry(k, v.toJson())),
    'alerts': alerts.map((e) => e.toJson()).toList(),
    'n_alerts': nAlerts,
    'recommendation': recommendation?.toJson(),
  };
}