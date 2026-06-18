// lib/data/datasources/remote/soil_api_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../model/soil_model.dart';

class SoilApiService {
  static const String _baseUrl = 'https://malakmohamed21-robot-api.hf.space';
  final http.Client _client;

  SoilApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<SoilSnapshot> fetchLatest() async {
    final res = await _client
        .get(Uri.parse('$_baseUrl/soil/stream/latest'))
        .timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      return SoilSnapshot.fromJson(
        Map<String, dynamic>.from(jsonDecode(res.body) as Map),
      );
    }
    throw Exception('Failed to fetch soil data: ${res.statusCode}');
  }

  Future<void> startStream() async {
    await _client
        .post(
      Uri.parse('$_baseUrl/soil/stream/start'),
      headers: {'Content-Type': 'application/json'},
    )
        .timeout(const Duration(seconds: 10));
  }

  Future<void> healthCheck() async {
    final res = await _client
        .get(Uri.parse('$_baseUrl/health'))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('Server not ready (${res.statusCode})');
    }
  }
}