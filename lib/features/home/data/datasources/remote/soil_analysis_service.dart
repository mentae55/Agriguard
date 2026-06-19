// lib/features/home/data/datasources/remote/soil_analysis_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:agriguard_project/core/constants/app_constants.dart';
import '../../model/soil_analysis_model.dart';

class SoilAnalysisService {
  final String _baseUrl;
  final http.Client _client;

  SoilAnalysisService({http.Client? client}) 
      : _client = client ?? http.Client(),
        _baseUrl = AppConstants.baseUrl;

  Future<SoilReading> fetchLatest() async {
    final res = await _client
        .get(Uri.parse('$_baseUrl/soil/stream/latest'))
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      return SoilReading.fromJson(
        Map<String, dynamic>.from(jsonDecode(res.body) as Map),
      );
    }
    throw Exception('Failed to fetch soil data: ${res.statusCode}');
  }
}
