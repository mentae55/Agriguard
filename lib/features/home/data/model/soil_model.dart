// lib/data/models/soil_models.dart

class SoilReading {
  final String locationId;
  final String deviceId;
  final double moisturePct;
  final double ph;
  final double nitrogenPpm;
  final double phosphorusPpm;
  final double potassiumPpm;
  final double temperatureC;
  final double ecDsM;
  final double organicMatter;

  SoilReading({
    required this.locationId,
    required this.deviceId,
    required this.moisturePct,
    required this.ph,
    required this.nitrogenPpm,
    required this.phosphorusPpm,
    required this.potassiumPpm,
    required this.temperatureC,
    required this.ecDsM,
    required this.organicMatter,
  });

  factory SoilReading.fromJson(Map<String, dynamic> j) => SoilReading(
    locationId: j['location_id']?.toString() ?? '--',
    deviceId: j['device_id']?.toString() ?? '--',
    moisturePct: (j['moisture_pct'] as num?)?.toDouble() ?? 0.0,
    ph: (j['ph'] as num?)?.toDouble() ?? 0.0,
    nitrogenPpm: (j['nitrogen_ppm'] as num?)?.toDouble() ?? 0.0,
    phosphorusPpm: (j['phosphorus_ppm'] as num?)?.toDouble() ?? 0.0,
    potassiumPpm: (j['potassium_ppm'] as num?)?.toDouble() ?? 0.0,
    temperatureC: (j['temperature_c'] as num?)?.toDouble() ?? 0.0,
    ecDsM: (j['ec_ds_m'] as num?)?.toDouble() ?? 0.0,
    organicMatter: (j['organic_matter'] as num?)?.toDouble() ?? 0.0,
  );
}

class SoilAlert {
  final String param;
  final double value;
  final String unit;
  final String status;
  final String severity;
  final String recommendation;

  SoilAlert({
    required this.param,
    required this.value,
    required this.unit,
    required this.status,
    required this.severity,
    required this.recommendation,
  });

  factory SoilAlert.fromJson(Map<String, dynamic> j) => SoilAlert(
    param: j['param']?.toString() ?? '--',
    value: (j['value'] as num?)?.toDouble() ?? 0.0,
    unit: j['unit']?.toString() ?? '',
    status: j['status']?.toString() ?? '--',
    severity: j['severity']?.toString() ?? 'warning',
    recommendation: j['recommendation']?.toString() ?? '',
  );
}

class SoilSnapshot {
  final String soilStatus;
  final String timestamp;
  final int nAlerts;
  final String primaryAction;
  final double confidence;
  final SoilReading reading;
  final List<SoilAlert> alerts;

  SoilSnapshot({
    required this.soilStatus,
    required this.timestamp,
    required this.nAlerts,
    required this.primaryAction,
    required this.confidence,
    required this.reading,
    required this.alerts,
  });

  factory SoilSnapshot.fromJson(Map<String, dynamic> j) => SoilSnapshot(
    soilStatus: j['soil_status']?.toString() ?? 'unknown',
    timestamp: j['timestamp']?.toString() ?? '',
    nAlerts: (j['n_alerts'] as num?)?.toInt() ?? 0,
    primaryAction: j['primary_action']?.toString() ?? '--',
    confidence: (j['confidence'] as num?)?.toDouble() ?? 0.0,
    reading: SoilReading.fromJson(
        Map<String, dynamic>.from(j['reading'] as Map? ?? {})),
    alerts: (j['alerts'] as List? ?? [])
        .map((a) => SoilAlert.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList(),
  );
}