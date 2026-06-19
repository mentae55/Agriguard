// lib/features/spectral/data/models/spectral_reading.dart

class SpectralRecommendation {
  final String primaryAction;
  final List<String> secondaryActions;
  final String urgency;

  SpectralRecommendation({
    required this.primaryAction,
    required this.secondaryActions,
    required this.urgency,
  });

  factory SpectralRecommendation.fromJson(Map<String, dynamic> json) {
    return SpectralRecommendation(
      primaryAction: json['primary_action'] as String? ?? 'No action specified',
      secondaryActions: (json['secondary_actions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      urgency: json['urgency'] as String? ?? 'LOW',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_action': primaryAction,
      'secondary_actions': secondaryActions,
      'urgency': urgency,
    };
  }
}

class SpectralReading {
  final String riskLevel;
  final double riskProbability;
  final String? cluster;
  final String? disease;
  final double confidence;
  final SpectralRecommendation? recommendation;
  final Map<String, double> spectralIndices;
  final DateTime lastUpdated;
  final String deviceId;
  final int readingsCollected;
  final int readingsRequired;

  SpectralReading({
    required this.riskLevel,
    required this.riskProbability,
    this.cluster,
    this.disease,
    required this.confidence,
    this.recommendation,
    required this.spectralIndices,
    required this.lastUpdated,
    required this.deviceId,
    required this.readingsCollected,
    required this.readingsRequired,
  });

  factory SpectralReading.fromJson(Map<String, dynamic> json) {
    Map<String, double> parsedIndices = {};
    if (json['spectral_indices'] != null) {
      final indicesMap = json['spectral_indices'] as Map<String, dynamic>;
      indicesMap.forEach((key, value) {
        parsedIndices[key] = (value as num).toDouble();
      });
    }

    return SpectralReading(
      riskLevel: json['risk_level'] as String? ?? 'NONE',
      riskProbability: (json['risk_probability'] as num?)?.toDouble() ?? 0.0,
      cluster: json['cluster'] as String?,
      disease: json['disease'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      recommendation: json['recommendation'] != null
          ? SpectralRecommendation.fromJson(
              json['recommendation'] as Map<String, dynamic>)
          : null,
      spectralIndices: parsedIndices,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
      deviceId: json['device_id'] as String? ?? 'Unknown',
      readingsCollected: (json['readings_collected'] as num?)?.toInt() ?? 0,
      readingsRequired: (json['readings_required'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'risk_level': riskLevel,
      'risk_probability': riskProbability,
      'cluster': cluster,
      'disease': disease,
      'confidence': confidence,
      'recommendation': recommendation?.toJson(),
      'spectral_indices': spectralIndices,
      'last_updated': lastUpdated.toIso8601String(),
      'device_id': deviceId,
      'readings_collected': readingsCollected,
      'readings_required': readingsRequired,
    };
  }
}
