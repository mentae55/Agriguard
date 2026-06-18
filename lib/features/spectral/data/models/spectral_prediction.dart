// ============================================================
// spectral_prediction.dart  — Spectral Analysis domain model
// ============================================================

class SpectralPrediction {
  final String plantId;
  final bool isAtRisk;
  final String riskLevel;          // NONE | MEDIUM | HIGH
  final double riskProbability;    // 0.0 – 1.0

  final String predictedGroup;     // Fungal | Viral | Pest_Bacterial
  final double groupConfidence;
  final Map<String, double> allGroupProbs;

  final String likelyDisease;
  final double diseaseConfidence;
  final Map<String, double> allDiseaseProbs;

  final List<String> actions;
  final String alertMessage;
  final String likelyDiseaseMessage;

  final DateTime timestamp;

  const SpectralPrediction({
    required this.plantId,
    required this.isAtRisk,
    required this.riskLevel,
    required this.riskProbability,
    required this.predictedGroup,
    required this.groupConfidence,
    required this.allGroupProbs,
    required this.likelyDisease,
    required this.diseaseConfidence,
    required this.allDiseaseProbs,
    required this.actions,
    required this.alertMessage,
    required this.likelyDiseaseMessage,
    required this.timestamp,
  });

  // ── JSON deserialization ──────────────────────────────────
  factory SpectralPrediction.fromJson(Map<String, dynamic> j) {
    Map<String, double> toDoubleMap(dynamic raw) {
      if (raw == null || raw is! Map) return {};
      return raw.map((k, v) =>
          MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0.0));
    }

    List<String> toStringList(dynamic raw) {
      if (raw == null || raw is! List) return [];
      return raw.map((e) => e.toString()).toList();
    }

    return SpectralPrediction(
      plantId: j['plant_id']?.toString() ?? 'PLANT_001',
      isAtRisk: j['is_at_risk'] as bool? ?? false,
      riskLevel: j['risk_level']?.toString() ?? 'NONE',
      riskProbability: (j['risk_probability'] as num?)?.toDouble() ?? 0.0,
      predictedGroup: j['predicted_group']?.toString() ?? '--',
      groupConfidence: (j['group_confidence'] as num?)?.toDouble() ?? 0.0,
      allGroupProbs: toDoubleMap(j['all_group_probs']),
      likelyDisease: j['likely_disease']?.toString() ?? '--',
      diseaseConfidence: (j['disease_confidence'] as num?)?.toDouble() ?? 0.0,
      allDiseaseProbs: toDoubleMap(j['all_disease_probs']),
      actions: toStringList(j['actions']),
      alertMessage: j['alert_message']?.toString() ?? '',
      likelyDiseaseMessage: j['likely_disease_message']?.toString() ?? '',
      timestamp: j['timestamp'] != null
          ? DateTime.tryParse(j['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // ── JSON serialization (for local storage) ────────────────
  Map<String, dynamic> toJson() => {
        'plant_id': plantId,
        'is_at_risk': isAtRisk,
        'risk_level': riskLevel,
        'risk_probability': riskProbability,
        'predicted_group': predictedGroup,
        'group_confidence': groupConfidence,
        'all_group_probs': allGroupProbs,
        'likely_disease': likelyDisease,
        'disease_confidence': diseaseConfidence,
        'all_disease_probs': allDiseaseProbs,
        'actions': actions,
        'alert_message': alertMessage,
        'likely_disease_message': likelyDiseaseMessage,
        'timestamp': timestamp.toIso8601String(),
      };

  // ── Helpers ───────────────────────────────────────────────
  bool get isHigh => riskLevel.toUpperCase() == 'HIGH';
  bool get isMedium => riskLevel.toUpperCase() == 'MEDIUM';
  bool get isNone => riskLevel.toUpperCase() == 'NONE';

  String get riskPercent =>
      '${(riskProbability * 100).toStringAsFixed(1)}%';

  String get diseasePercent =>
      '${(diseaseConfidence * 100).toStringAsFixed(1)}%';

  String get groupPercent =>
      '${(groupConfidence * 100).toStringAsFixed(1)}%';
}
