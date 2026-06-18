// lib/presentation/viewmodels/home_viewmodel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/model/soil_model.dart';
import '../../domain/usecases/fetch_soil_data.dart';

class HomeViewModel extends ChangeNotifier {
  final FetchSoilDataUseCase _fetchSoilData;
  final String serial;

  HomeViewModel({
    required FetchSoilDataUseCase fetchSoilData,
    required this.serial,
  }) : _fetchSoilData = fetchSoilData;

  // State
  double? soilTemperature;
  double? soilMoisture;
  String? soilStatus;
  List<SoilAlert> liveAlerts = [];
  bool dataLoaded = false;
  int selectedNavIndex = 2;

  StreamSubscription<SoilSnapshot>? _sub;

  void initialize() {
    _sub = _fetchSoilData().listen(_onSoilData);
  }

  void _onSoilData(SoilSnapshot snap) {
    soilTemperature = snap.reading.temperatureC;
    soilMoisture = snap.reading.moisturePct;
    soilStatus = snap.soilStatus;
    liveAlerts = SoilAlertEngine.evaluate(snap);
    dataLoaded = true;
    notifyListeners();
  }

  void setNavIndex(int index) {
    selectedNavIndex = index;
    notifyListeners();
  }

  int get criticalCount =>
      liveAlerts.where((a) => a.severity == 'critical').length;

  int get totalAlerts =>
      liveAlerts.where((a) => a.severity != 'info').length;

  SoilAlert? get topAlert {
    final nonInfo = liveAlerts.where((a) => a.severity != 'info').toList();
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
    _sub?.cancel();
    super.dispose();
  }
}

class SoilAlertEngine {
  static List<SoilAlert> evaluate(SoilSnapshot snap) {
    return snap.alerts;
  }
}