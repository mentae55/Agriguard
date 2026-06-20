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
      if (history.length > 20) history.removeAt(0);
      await _saveHistory();

      state = SoilState.loaded;
      errorMessage = '';
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      if (latest != null) {
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
        if (history.isNotEmpty) latest = history.last;
      } catch (_) {}
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

  // Safe ranges matching the API spec exactly
  static const Map<String, List<double>> safeRanges = {
    'moisture':       [15.0, 50.0],
    'ph':             [5.5,  7.8],
    'nitrogen':       [10.0, 70.0],
    'phosphorus':     [5.0,  60.0],
    'potassium':      [50.0, 300.0],
    'temperature':    [8.0,  38.0],
    'ec':             [0.3,  3.0],
    'organic_matter': [1.0,  6.5],
  };

  /// Returns the gauge color for a parameter.
  /// Priority: backend alert severity → fallback to safe-range check.
  Color getGaugeColor(String param, double value) {
    if (latest == null) return Colors.grey;

    // The alert `param` field uses the raw API key (e.g. "moisture_pct"),
    // so we normalise both sides for matching.
    final alert = latest!.alerts.where((a) {
      final alertKey = _normaliseParam(a.param);
      return alertKey == param;
    }).firstOrNull;

    if (alert != null) {
      switch (alert.severity.toLowerCase()) {
        case 'critical':
          return Colors.red;
        case 'warning':
          return Colors.amber;
        default:
          return Colors.orange;
      }
    }

    // Fallback: check against spec safe ranges
    final range = safeRanges[param];
    if (range == null) return Colors.grey;
    final isSafe = value >= range[0] && value <= range[1];
    return isSafe ? Colors.green : Colors.red;
  }

  /// Normalises API param names (e.g. "moisture_pct" → "moisture",
  /// "nitrogen_ppm" → "nitrogen", "ec_ds_m" → "ec") to match the display keys
  /// used in [readings] and [safeRanges].
  static String _normaliseParam(String raw) {
    return raw
        .replaceAll('_pct', '')
        .replaceAll('_ppm', '')
        .replaceAll('_c', '')
        .replaceAll('_ds_m', '')
        .replaceAll('_matter', '_matter'); // keep organic_matter as-is
  }
}