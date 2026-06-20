// ============================================================
// spectral_api_service.dart — HTTP layer for Spectral endpoints
// ============================================================
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/spectral_prediction.dart';
import '../../../../core/constants/app_constants.dart';

class SpectralApiService {
  final String _baseUrl;
  static const Duration _defaultTimeout = Duration(seconds: 45);

  final http.Client _client;
  SpectralApiService({http.Client? client}) 
      : _client = client ?? http.Client(),
        _baseUrl = AppConstants.baseUrl;

  /// Helper with exponential backoff
  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() requestFn, {
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await requestFn();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
  }

  /// POST /spectral/stream/start
  Future<void> startStream() async {
    try {
      await _requestWithRetry(
        () => _client
            .post(
              Uri.parse('$_baseUrl/spectral/stream/start'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 60)),
        maxRetries: 2,
      );
    } catch (_) {}
  }

  /// POST /spectral/stream/stop
  Future<void> stopStream() async {
    try {
      await _client
          .post(
            Uri.parse('$_baseUrl/spectral/stream/stop'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  /// GET /spectral/stream/latest
  Future<SpectralPrediction> fetchLatest() async {
    final res = await _requestWithRetry(
          () => _client
          .get(Uri.parse('$_baseUrl/spectral/stream/latest'))
          .timeout(_defaultTimeout),
      maxRetries: 3,
    );
    if (res.statusCode == 200) {
      try {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic>) {
          return SpectralPrediction.fromJson(body);
        }
        throw const FormatException('Unexpected JSON root format');
      } catch (e) {
        throw Exception('Failed to parse spectral data: $e');
      }
    }
    throw Exception('Server returned ${res.statusCode}');
  }

  /// GET /spectral/health
  Future<bool> healthCheck() async {
    try {
      final res = await _client
          .get(Uri.parse('$_baseUrl/spectral/health'))
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
