import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/remote/soil_analysis_service.dart';
import '../../../alerts/models/alert_model.dart';
import '../../../alerts/repositories/alert_history_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final SoilAnalysisService _soilService;
  final AlertHistoryRepository _historyRepository;
  final String serial;

  HomeViewModel({
    SoilAnalysisService? soilService,
    AlertHistoryRepository? historyRepository,
    required this.serial,
  })  : _soilService = soilService ?? SoilAnalysisService(),
        _historyRepository = historyRepository ?? AlertHistoryRepository();

  // State
  double? soilTemperature;
  double? soilMoisture;
  String? soilStatus;
  List<GeneratedAlert> liveAlerts = [];
  bool dataLoaded = false;
  int selectedNavIndex = 2;

  Timer? _timer;

  void initialize() {
    _fetchData();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _fetchData());
  }

  Future<void> _fetchData() async {
    try {
      final soilReading = await _soilService.fetchLatest();
      soilTemperature = soilReading.readings['temperature']?.value ?? 0.0;
      soilMoisture = soilReading.readings['moisture']?.value ?? 0.0;
      soilStatus = soilReading.nAlerts == 0 ? 'Healthy' : 'Needs Attention';
      dataLoaded = true;
    } catch (_) {
      // Keep old data if fetch fails
    }

    try {
      // Same source of truth as AlertsViewModel: active + not-yet-viewed alerts
      final history = await _historyRepository.fetchHistory();
      liveAlerts = history.where((a) => !a.isResolved && !a.isViewed).toList();
    } catch (_) {}

    notifyListeners();
  }

  // NEW: dismiss an alert from the home banner (and from the Alerts tab)
  // once the user has opened it, without marking it as resolved.
  Future<void> markAlertAsViewed(GeneratedAlert alert) async {
    if (alert.historyId.isEmpty || alert.isViewed) return;

    final viewedAt = DateTime.now();
    await _historyRepository.markAsViewed(alert.historyId, viewedAt);

    liveAlerts = liveAlerts.where((a) => a.historyId != alert.historyId).toList();
    notifyListeners();
  }

  void setNavIndex(int index) {
    selectedNavIndex = index;
    notifyListeners();
  }

  int get criticalCount =>
      liveAlerts.where((a) => a.severity == AlertSeverity.critical).length;

  int get totalAlerts =>
      liveAlerts.where((a) => a.severity != AlertSeverity.info).length;

  GeneratedAlert? get topAlert {
    final nonInfo = liveAlerts.where((a) => a.severity != AlertSeverity.info).toList();
    return nonInfo.isEmpty ? null : nonInfo.first;
  }

  Color getTempColor(double t) {
    if (t < 8) return const Color(0xFF5B9BD5);
    if (t < 15) return const Color(0xFF70B77E);
    if (t < 30) return primaryColor;
    if (t < 36) return orangeColor;
    return redColor;
  }

  IconData getTempIcon(double t) {
    if (t < 10) return Icons.ac_unit_rounded;
    if (t < 28) return Icons.thermostat_rounded;
    return Icons.local_fire_department_rounded;
  }

  String get formattedSerial => serial.isEmpty
      ? '122'
      : serial.length > 6
      ? serial.substring(0, 6).toUpperCase()
      : serial.toUpperCase();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}