// ============================================================
// spectral_view_model.dart — ChangeNotifier state management
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/spectral_prediction.dart';
import '../data/models/spectral_history_entry.dart';
import '../data/services/spectral_api_service.dart';
import '../data/repositories/spectral_history_repository.dart';
import '../data/services/spectral_notification_service.dart';

enum SpectralState { idle, loading, loaded, error }

class SpectralViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final SpectralApiService _api;
  final SpectralHistoryRepository _historyRepo;

  SpectralViewModel({
    SpectralApiService? api,
    SpectralHistoryRepository? historyRepo,
  })  : _api = api ?? SpectralApiService(),
        _historyRepo = historyRepo ?? SpectralHistoryRepository();

  // ── State ─────────────────────────────────────────────────
  SpectralState _state = SpectralState.idle;
  SpectralPrediction? _prediction;
  String _errorMessage = '';
  Timer? _pollingTimer;
  bool _disposed = false;

  SpectralState get state => _state;
  SpectralPrediction? get prediction => _prediction;
  String get errorMessage => _errorMessage;
  bool get isLoading => _state == SpectralState.loading;
  bool get hasData => _prediction != null;

  // ── Lifecycle ─────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopPolling();
    }
  }

  // ── Initialize ────────────────────────────────────────────
  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    _setState(SpectralState.loading);

    // Start server stream (non-blocking)
    await _api.startStream();

    // Immediate first fetch
    await _fetchLatest();

    // Start 30-minute polling
    _startPolling();
  }

  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _fetchLatest(),
    );
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  bool _isFetching = false;

  // ── Fetch Latest ──────────────────────────────────────────
  Future<void> _fetchLatest() async {
    if (_disposed || _isFetching) return;
    _isFetching = true;

    try {
      final result = await _api.fetchLatest();
      if (_disposed) return;
      
      final bool wasStateChanged = _prediction?.timestamp != result.timestamp || _state != SpectralState.loaded;
      _prediction = result;
      if (wasStateChanged) {
        _setState(SpectralState.loaded);
      }

      // Persist to history
      final entry = SpectralHistoryEntry(
        id: result.timestamp.millisecondsSinceEpoch.toString(),
        plantId: result.plantId,
        riskLevel: result.riskLevel,
        riskProbability: result.riskProbability,
        predictedGroup: result.predictedGroup,
        likelyDisease: result.likelyDisease,
        alertMessage: result.alertMessage,
        timestamp: result.timestamp,
      );
      final bool isNewEntry = await _historyRepo.addEntry(entry);

      // Trigger push notification only if HIGH or MEDIUM risk AND it's a new unique event
      if (isNewEntry && (result.isHigh || result.isMedium)) {
        SpectralNotificationService.showSpectralAlert(
          title: 'Spectral Disease Alert',
          body: result.alertMessage.isNotEmpty ? result.alertMessage : 'High or Medium risk detected.',
        );
      }
    } catch (e) {
      if (_disposed) return;
      if (_state != SpectralState.loaded) {
        // Only show error if we have no data yet
        _errorMessage = _friendlyError(e.toString());
        _setState(SpectralState.error);
      }
    } finally {
      _isFetching = false;
    }
  }

  /// Manual refresh (pull-to-refresh or retry button)
  Future<void> refresh() async {
    _setState(SpectralState.loading);
    await _fetchLatest();
  }

  // ── Helpers ───────────────────────────────────────────────
  void _setState(SpectralState s) {
    if (_disposed) return;
    _state = s;
    notifyListeners();
  }

  String _friendlyError(String raw) {
    if (raw.contains('SocketException') || raw.contains('Failed host lookup')) {
      return 'No internet connection. Please check your network.';
    }
    if (raw.contains('TimeoutException') || raw.contains('timed out')) {
      return 'Request timed out. The server may be starting up — try again shortly.';
    }
    if (raw.contains('404')) return 'No spectral data available yet.';
    return 'Unable to fetch data. Please try again.';
  }

  // ── Dispose ───────────────────────────────────────────────
  Future<void> tearDown() async {
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    await _api.stopStream();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
