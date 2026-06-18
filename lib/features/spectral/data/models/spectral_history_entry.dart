// ============================================================
// spectral_history_entry.dart — lightweight local history record
// ============================================================

class SpectralHistoryEntry {
  final String id;
  final String plantId;
  final String riskLevel;
  final double riskProbability;
  final String predictedGroup;
  final String likelyDisease;
  final String alertMessage;
  final DateTime timestamp;

  const SpectralHistoryEntry({
    required this.id,
    required this.plantId,
    required this.riskLevel,
    required this.riskProbability,
    required this.predictedGroup,
    required this.likelyDisease,
    required this.alertMessage,
    required this.timestamp,
  });

  factory SpectralHistoryEntry.fromJson(Map<String, dynamic> j) =>
      SpectralHistoryEntry(
        id: j['id']?.toString() ?? '',
        plantId: j['plant_id']?.toString() ?? '',
        riskLevel: j['risk_level']?.toString() ?? 'NONE',
        riskProbability: (j['risk_probability'] as num?)?.toDouble() ?? 0.0,
        predictedGroup: j['predicted_group']?.toString() ?? '--',
        likelyDisease: j['likely_disease']?.toString() ?? '--',
        alertMessage: j['alert_message']?.toString() ?? '',
        timestamp: j['timestamp'] != null
            ? DateTime.tryParse(j['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'plant_id': plantId,
        'risk_level': riskLevel,
        'risk_probability': riskProbability,
        'predicted_group': predictedGroup,
        'likely_disease': likelyDisease,
        'alert_message': alertMessage,
        'timestamp': timestamp.toIso8601String(),
      };

  bool get isHigh => riskLevel.toUpperCase() == 'HIGH';
  bool get isMedium => riskLevel.toUpperCase() == 'MEDIUM';
  String get riskPercent =>
      '${(riskProbability * 100).toStringAsFixed(1)}%';
}
