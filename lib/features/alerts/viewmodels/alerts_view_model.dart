
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../repositories/alerts_repository.dart';
import '../repositories/alert_history_repository.dart';

enum AlertsViewState { loading, loaded, error }

extension _ListExt<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class AlertsViewModel extends ChangeNotifier {
  final AlertsRepository _repository;
  final AlertHistoryRepository _historyRepository;
  Timer? _pollTimer;

  // State
  List<GeneratedAlert> _alerts = [];
  List<GeneratedAlert> _history = [];
  AlertsViewState _state = AlertsViewState.loading;
  String _errorMessage = '';
  DateTime? _lastUpdated;

  // Getters
  List<GeneratedAlert> get alerts => List.unmodifiable(_alerts);
  List<GeneratedAlert> get history => List.unmodifiable(_history);
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

  AlertsViewModel({
    AlertsRepository? repository,
    AlertHistoryRepository? historyRepository,
  })  : _repository = repository ?? AlertsRepository(),
        _historyRepository = historyRepository ?? AlertHistoryRepository();

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

  Future<void> clearAlertHistory() async {
    await _historyRepository.clearHistory();
    _history = [];
    _alerts = [
      GeneratedAlert(
        id: 'healthy',
        title: 'All Systems Healthy',
        description: 'All soil parameters are within optimal ranges. Your field is in excellent condition.',
        severity: AlertSeverity.info,
        paramName: 'All Parameters',
        value: 0,
        unit: '',
        recommendation: 'Continue current irrigation and fertilisation schedule. Next recommended scan in 24 hours.',
        icon: Icons.check_circle_rounded,
        timestamp: DateTime.now(),
      )
    ];
    notifyListeners();
  }

  Future<void> _fetchData() async {
    try {
      final rawAlerts = await _repository.fetchAndEvaluateAlerts();
      
      // Load history from storage
      var historyList = await _historyRepository.fetchHistory();
      
      // Filter out healthy alert for lifecycle state machine
      final newIssues = rawAlerts.where((a) => a.id != 'healthy').toList();
      final activeAlerts = historyList.where((a) => !a.isResolved).toList();
      
      final allParams = <String>{
        ...newIssues.map((a) => a.paramName),
        ...activeAlerts.map((a) => a.paramName),
      };
      
      for (final paramName in allParams) {
        final currentIssue = newIssues.firstWhereOrNull((a) => a.paramName == paramName);
        final activeIssue = activeAlerts.firstWhereOrNull((a) => a.paramName == paramName);
        
        if (activeIssue == null && currentIssue != null) {
          // A new issue appears
          final newAlert = currentIssue.copyWith(
            historyId: 'hist_${DateTime.now().millisecondsSinceEpoch}_${currentIssue.id}',
            isResolved: false,
          );
          await _historyRepository.saveAlert(newAlert);
        } else if (activeIssue != null && currentIssue == null) {
          // Resolve alerts automatically when conditions return to normal
          await _historyRepository.resolveAlert(activeIssue.historyId, DateTime.now());
        } else if (activeIssue != null && currentIssue != null) {
          final isEscalated = activeIssue.severity == AlertSeverity.warning &&
              currentIssue.severity == AlertSeverity.critical;
          if (isEscalated) {
            // A warning becomes critical
            await _historyRepository.resolveAlert(activeIssue.historyId, DateTime.now());
            final newAlert = currentIssue.copyWith(
              historyId: 'hist_${DateTime.now().millisecondsSinceEpoch}_${currentIssue.id}',
              isResolved: false,
            );
            await _historyRepository.saveAlert(newAlert);
          } else {
            // Cooldown check (12-Hour)
            final timeDiff = DateTime.now().difference(activeIssue.createdAt);
            if (timeDiff.inHours >= 12) {
              await _historyRepository.resolveAlert(activeIssue.historyId, DateTime.now());
              final newAlert = currentIssue.copyWith(
                historyId: 'hist_${DateTime.now().millisecondsSinceEpoch}_${currentIssue.id}',
                isResolved: false,
              );
              await _historyRepository.saveAlert(newAlert);
            } else {
              // Update existing active alert
              final updatedAlert = activeIssue.copyWith(
                value: currentIssue.value,
                description: currentIssue.description,
                recommendation: currentIssue.recommendation,
                severity: currentIssue.severity,
                updatedAt: DateTime.now(),
              );
              await _historyRepository.updateAlert(updatedAlert);
            }
          }
        }
      }
      
      // Reload history and state
      historyList = await _historyRepository.fetchHistory();
      _history = historyList;
      
      final active = historyList.where((a) => !a.isResolved).toList();
      if (active.isEmpty) {
        final healthyAlert = rawAlerts.firstWhereOrNull((a) => a.id == 'healthy') ?? rawAlerts.first;
        _alerts = [healthyAlert];
      } else {
        _alerts = active;
      }
      
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