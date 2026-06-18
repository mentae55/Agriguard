import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../home/data/model/soil_model.dart';

class AlertsApiService {
  static const String _baseUrl = 'https://malakmohamed21-robot-api.hf.space';
  static const Duration _timeout = Duration(hours: 1);

  Future<SoilSnapshot> fetchLatestSnapshot() async {
    final res = await http
        .get(Uri.parse('$_baseUrl/soil/stream/latest'))
        .timeout(_timeout);

    if (res.statusCode == 200) {
      return SoilSnapshot.fromJson(
          Map<String, dynamic>.from(jsonDecode(res.body) as Map));
    } else {
      throw Exception('Server returned ${res.statusCode}');
    }
  }
}