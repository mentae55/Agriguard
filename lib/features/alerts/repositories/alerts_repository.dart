import 'package:flutter/material.dart';
import '../../home/data/datasources/remote/soil_analysis_service.dart';
import '../../spectral/data/services/spectral_api_service.dart';
import '../models/alert_model.dart';

class AlertsRepository {
  final SoilAnalysisService _soilService;
  final SpectralApiService _spectralService;

  AlertsRepository({SoilAnalysisService? soilService, SpectralApiService? spectralService})
      : _soilService = soilService ?? SoilAnalysisService(),
        _spectralService = spectralService ?? SpectralApiService();

  Future<List<GeneratedAlert>> fetchAndEvaluateAlerts() async {
    final alerts = <GeneratedAlert>[];
    final now = DateTime.now();

    try {
      final soilReading = await _soilService.fetchLatest();
      for (final a in soilReading.alerts) {
        alerts.add(GeneratedAlert(
          id: 'soil_\${a.parameter}',
          title: 'Soil \${a.parameter} Alert',
          description: a.message,
          severity: a.severity.toLowerCase() == 'high' ? AlertSeverity.critical : AlertSeverity.warning,
          paramName: a.parameter,
          value: soilReading.readings[a.parameter]?.value ?? 0.0,
          unit: soilReading.readings[a.parameter]?.unit ?? '',
          recommendation: '',
          icon: Icons.sensors_rounded,
          timestamp: now,
        ));
      }
    } catch (_) {}

    try {
      final spectralReading = await _spectralService.fetchLatest();
      if (spectralReading.riskLevel.toUpperCase() == 'HIGH' || spectralReading.riskLevel.toUpperCase() == 'MEDIUM') {
        alerts.add(GeneratedAlert(
          id: 'spectral_disease',
          title: 'Disease Risk Detected',
          description: 'Risk Level: \${spectralReading.riskLevel}. Cluster: \${spectralReading.cluster}. Disease: \${spectralReading.disease}.',
          severity: spectralReading.riskLevel.toUpperCase() == 'HIGH' ? AlertSeverity.critical : AlertSeverity.warning,
          paramName: 'Disease Detection',
          value: spectralReading.riskProbability,
          unit: '%',
          recommendation: spectralReading.recommendation?.primaryAction ?? '',
          icon: Icons.grass_rounded,
          timestamp: now,
        ));
      }
    } catch (_) {}

    if (alerts.isEmpty) {
      alerts.add(GeneratedAlert(
        id: 'healthy',
        title: 'All Systems Healthy',
        description: 'No soil or spectral issues detected. Your field is in excellent condition.',
        severity: AlertSeverity.info,
        paramName: 'All Parameters',
        value: 0,
        unit: '',
        recommendation: 'Continue current schedule.',
        icon: Icons.check_circle_rounded,
        timestamp: now,
      ));
    }

    return alerts;
  }
}