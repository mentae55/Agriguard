// lib/data/repositories/soil_repository.dart
import 'dart:async';
import '../datasources/remote/soil_api_service.dart';
import '../model/soil_model.dart';

abstract class SoilRepository {
  Stream<SoilSnapshot> get soilStream;
  Future<void> initialize();
  void dispose();
}

class SoilRepositoryImpl implements SoilRepository {
  final SoilApiService _apiService;
  Timer? _timer;
  final StreamController<SoilSnapshot> _streamController = StreamController<SoilSnapshot>.broadcast();

  SoilRepositoryImpl({SoilApiService? apiService})
      : _apiService = apiService ?? SoilApiService();

  @override
  Stream<SoilSnapshot> get soilStream => _streamController.stream;

  @override
  Future<void> initialize() async {
    await _apiService.healthCheck();
    await _apiService.startStream();
    await _fetchAndEmit();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchAndEmit());
  }

  Future<void> _fetchAndEmit() async {
    try {
      final snap = await _apiService.fetchLatest();
      if (!_streamController.isClosed) _streamController.add(snap);
    } catch (_) {
      // Silently keep old data
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _streamController.close();
  }
}