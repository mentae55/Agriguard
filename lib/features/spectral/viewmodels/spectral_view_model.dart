// ============================================================
// spectral_view_model.dart — ChangeNotifier state management
// ============================================================
import 'dart:async';
import 'dart:convert';
import 'package:agriguard_project/features/spectral/data/models/spectral_prediction.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/spectral_api_service.dart';

const Duration kSpectralPollInterval = Duration(seconds:  30);

enum SpectralState { idle, loading, loaded, error }

class SpectralViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final SpectralApiService _api;

  SpectralViewModel({
    SpectralApiService? api,
  }) : _api = api ?? SpectralApiService();

  SpectralState _state = SpectralState.idle;
  SpectralPrediction? _reading;
  String _errorMessage = '';
  Timer? _pollingTimer;
  bool _disposed = false;
  
  List<SpectralPrediction> history = [];

  SpectralState get state => _state;
  SpectralPrediction? get reading => _reading;
  String get errorMessage => _errorMessage;
  bool get isLoading => _state == SpectralState.loading;
  bool get hasData => _reading != null;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopPolling();
    }
  }

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    _setState(SpectralState.loading);

    await _loadHistory();
    await _api.startStream();
    await _fetchLatest();
    _startPolling();
  }

  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(kSpectralPollInterval, (_) => _fetchLatest());
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  bool _isFetching = false;

  Future<void> _fetchLatest() async {
    if (_disposed || _isFetching) return;
    _isFetching = true;

    try {
      final result = await _api.fetchLatest();
      if (_disposed) return;
      
      _reading = result;
      
      history.add(result);
      if (history.length > 20) {
        history.removeAt(0);
      }
      await _saveHistory();

      _errorMessage = '';
      _setState(SpectralState.loaded);
    } catch (e) {
      if (_disposed) return;
      if (_reading != null) {
        // Keep showing last known data
        _setState(SpectralState.loaded);
      } else {
        _errorMessage = _friendlyError(e.toString());
        _setState(SpectralState.error);
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() async {
    _setState(SpectralState.loading);
    _stopPolling();
    await _fetchLatest();
    _startPolling();
  }
  
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('spectral_history');
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(historyJson);
        history = decoded.map((e) => SpectralPrediction.fromJson(e)).toList();
        if (history.isNotEmpty) {
          _reading = history.last;
        }
      } catch (e) {
        // Ignore parse errors on load
      }
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString('spectral_history', historyJson);
  }

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
      return 'Request timed out. Server may be starting up.';
    }
    if (raw.contains('404')) return 'No spectral data available yet.';
    return 'Unable to fetch data. Please try again.';
  }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
