import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agriguard_project/features/home/view/soil_analysis_screen.dart' show SoilSnapshot;

class AlertsApiService {
  static const String _baseUrl = 'https://robot-api-production.up.railway.app';
  static const Duration _timeout = Duration(seconds: 15);

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