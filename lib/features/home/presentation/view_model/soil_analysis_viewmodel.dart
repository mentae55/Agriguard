// lib/features/home/presentation/view_model/soil_analysis_viewmodel.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agriguard_project/core/constants/app_colors.dart';
import '../../data/model/soil_analysis_model.dart';
import '../../data/datasources/remote/soil_analysis_service.dart';

const int kSoilPollIntervalSeconds = 1800;

enum SoilState { initial, loading, refreshing, loaded, error }

class SoilAnalysisViewModel extends ChangeNotifier {
  final SoilAnalysisService _apiService;

  SoilAnalysisViewModel({SoilAnalysisService? apiService})
      : _apiService = apiService ?? SoilAnalysisService();

  SoilState state = SoilState.initial;
  SoilReading? latest;
  List<SoilReading> history = [];
  String errorMessage = '';

  Timer? _timer;
  int secondsUntilNextUpdate = kSoilPollIntervalSeconds;

  Future<void> initialize() async {
    state = SoilState.loading;
    notifyListeners();

    await _loadHistory();
    await _fetchData();
    _startTimer();
  }

  Future<void> refreshNow() async {
    _timer?.cancel();
    state = SoilState.refreshing;
    notifyListeners();
    await _fetchData();
    _startTimer();
  }

  void _startTimer() {
    secondsUntilNextUpdate = kSoilPollIntervalSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsUntilNextUpdate > 0) {
        secondsUntilNextUpdate--;
        notifyListeners();
      } else {
        refreshNow();
      }
    });
  }

  Future<void> _fetchData() async {
    try {
      final snap = await _apiService.fetchLatest();
      latest = snap;
      history.add(snap);
      if (history.length > 20) {
        history.removeAt(0);
      }
      await _saveHistory();

      state = SoilState.loaded;
      errorMessage = '';
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      if (latest != null) {
        // Keep showing last successful data on background refresh error
        state = SoilState.loaded;
      } else {
        state = SoilState.error;
      }
      notifyListeners();
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('soil_history');
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(historyJson);
        history = decoded.map((e) => SoilReading.fromJson(e)).toList();
        if (history.isNotEmpty) {
          latest = history.last;
        }
      } catch (e) {
        // Ignore parse errors on load
      }
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString('soil_history', historyJson);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color getGaugeColor(String param, double value) {
    if (latest == null) return Colors.grey;

    final alert = latest!.alerts
        .where((a) => a.parameter.toLowerCase() == param.toLowerCase())
        .firstOrNull;
        
    if (alert != null) {
      switch (alert.severity.toLowerCase()) {
        case 'low':
          return Colors.amber;
        case 'medium':
          return Colors.orange;
        case 'high':
          return Colors.red;
        default:
          return Colors.orange;
      }
    }

    bool isSafe = true;
    switch (param.toLowerCase()) {
      case 'moisture':
        isSafe = value >= 40 && value <= 70;
        break;
      case 'ph':
        isSafe = value >= 5.5 && value <= 7.5;
        break;
      case 'nitrogen':
        isSafe = value >= 20 && value <= 60;
        break;
      case 'phosphorus':
        isSafe = value >= 10 && value <= 40;
        break;
      case 'potassium':
        isSafe = value >= 100 && value <= 300;
        break;
      case 'temperature':
        isSafe = value >= 15 && value <= 30;
        break;
      case 'ec':
        isSafe = value >= 0.2 && value <= 1.5;
        break;
      case 'organic_matter':
        isSafe = value >= 2 && value <= 5;
        break;
    }

    return isSafe ? Colors.green : Colors.red;
  }
}