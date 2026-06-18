// lib/data/datasources/remote/weather_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../model/weather_model.dart';

class WeatherApiService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  final http.Client _client;

  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<WeatherData> fetchWeather(CityConfig city) async {
    final url = Uri.parse(
      '$_baseUrl'
          '?latitude=${city.lat}'
          '&longitude=${city.lon}'
          '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m,wind_direction_10m'
          '&hourly=temperature_2m,weather_code'
          '&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max'
          '&timezone=auto',
    );

    final res = await _client.get(url).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return WeatherData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Weather API error: ${res.statusCode}');
  }
}