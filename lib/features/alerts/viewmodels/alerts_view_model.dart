
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../repositories/alerts_repository.dart';

enum AlertsViewState { loading, loaded, error }

class AlertsViewModel extends ChangeNotifier {
  final AlertsRepository _repository;
  Timer? _pollTimer;

  // State
  List<GeneratedAlert> _alerts = [];
  AlertsViewState _state = AlertsViewState.loading;
  String _errorMessage = '';
  DateTime? _lastUpdated;

  // Getters
  List<GeneratedAlert> get alerts => List.unmodifiable(_alerts);
  AlertsViewState get state => _state;
  String get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;

  // Computed
  List<GeneratedAlert> get criticalAlerts =>
      _alerts.where((a) => a.severity == AlertSeverity.critical).toList();

  List<GeneratedAlert> get warningAlerts =>
      _alerts.where((a) => a.severity == AlertSeverity.warning).toList();

  bool get isLoading => _state == AlertsViewState.loading;
  bool get hasError => _state == AlertsViewState.error;
  bool get isHealthy => criticalAlerts.isEmpty && warningAlerts.isEmpty;

  AlertsViewModel({AlertsRepository? repository})
      : _repository = repository ?? AlertsRepository();

  void startPolling({Duration interval = const Duration(seconds: 10)}) {
    _fetchData();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => _fetchData());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> refresh() async {
    _setState(AlertsViewState.loading);
    await _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final alerts = await _repository.fetchAndEvaluateAlerts();
      _alerts = alerts;
      _lastUpdated = DateTime.now();
      _setState(AlertsViewState.loaded);
    } catch (e) {
      _errorMessage = e.toString();
      if (_state != AlertsViewState.loaded) {
        _setState(AlertsViewState.error);
      }
    }
  }

  void _setState(AlertsViewState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}