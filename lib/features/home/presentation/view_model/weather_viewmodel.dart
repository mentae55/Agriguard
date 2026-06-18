// lib/presentation/viewmodels/weather_viewmodel.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/model/weather_model.dart';
import '../../domain/usecases/fetch_weather.dart';

class WeatherViewModel extends ChangeNotifier {
  final FetchWeatherUseCase _fetchWeather;


  final List<CityConfig> cities = const [
    CityConfig(name: 'Cairo', lat: 30.0444, lon: 31.2357, timezone: 'Africa/Cairo'),
    CityConfig(name: 'Alexandria', lat: 31.2001, lon: 29.9187, timezone: 'Africa/Cairo'),
    CityConfig(name: 'Luxor', lat: 25.6872, lon: 32.6396, timezone: 'Africa/Cairo'),
    CityConfig(name: 'Aswan', lat: 24.0889, lon: 32.8998, timezone: 'Africa/Cairo'),
    CityConfig(name: 'Seongnam-si', lat: 37.4200, lon: 127.1265, timezone: 'Asia/Seoul'),
  ];

  CityConfig selectedCity;
  WeatherData? weatherData;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  WeatherViewModel({required FetchWeatherUseCase fetchWeather})
      : _fetchWeather = fetchWeather,
        selectedCity = const CityConfig(name: 'Cairo', lat: 30.0444, lon: 31.2357, timezone: 'Africa/Cairo');

  Future<void> fetchWeather() async {
    isLoading = true;
    hasError = false;
    notifyListeners();

    try {
      weatherData = await _fetchWeather(selectedCity);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      hasError = true;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void selectCity(CityConfig city) {
    selectedCity = city;
    fetchWeather();
  }

  Map<String, dynamic> getWmoDetails(int code, int isDay) {
    switch (code) {
      case 0:
        return {
          'desc': 'Clear Sky',
          'icon': isDay == 1 ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
          'color': isDay == 1 ? Colors.orange.shade400 : Colors.indigo.shade300,
        };
      case 1:
      case 2:
      case 3:
        return {
          'desc': code == 1 ? 'Mainly Clear' : code == 2 ? 'Partly Cloudy' : 'Overcast',
          'icon': isDay == 1 ? Icons.wb_cloudy_rounded : Icons.nights_stay_rounded,
          'color': Colors.blueGrey.shade300,
        };
      case 45:
      case 48:
        return {'desc': 'Foggy', 'icon': Icons.filter_drama_rounded, 'color': Colors.grey.shade400};
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return {'desc': 'Drizzle', 'icon': Icons.grain_rounded, 'color': Colors.blue.shade300};
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return {'desc': 'Rainy', 'icon': Icons.umbrella_rounded, 'color': Colors.blue.shade600};
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return {'desc': 'Snowy', 'icon': Icons.ac_unit_rounded, 'color': Colors.lightBlue.shade200};
      case 80:
      case 81:
      case 82:
        return {'desc': 'Rain Showers', 'icon': Icons.water_drop_rounded, 'color': Colors.blue.shade700};
      case 95:
      case 96:
      case 97:
        return {'desc': 'Thunderstorm', 'icon': Icons.thunderstorm_rounded, 'color': Colors.deepPurple.shade400};
      default:
        return {'desc': 'Unknown', 'icon': Icons.wb_cloudy_rounded, 'color': Colors.grey.shade400};
    }
  }

  String formatDayName(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final today = DateTime.now();
      if (date.year == today.year && date.month == today.month && date.day == today.day) return 'Today';
      const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdayNames[date.weekday - 1];
    } catch (_) {
      return dateStr;
    }
  }

  String formatHour(String timeStr) {
    try {
      final dateTime = DateTime.parse(timeStr);
      final hour = dateTime.hour;
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
      return '$formattedHour $ampm';
    } catch (_) {
      return timeStr;
    }
  }

  String formatTimeOnly(String isoStr) {
    if (isoStr.isEmpty) return '--';
    try {
      final dt = DateTime.parse(isoStr);
      final h = dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = h >= 12 ? 'PM' : 'AM';
      final displayHour = h % 12 == 0 ? 12 : h % 12;
      return '$displayHour:$m $ampm';
    } catch (_) {
      return isoStr;
    }
  }

  double calculateDewPoint(double temp, int humidity) {
    const double b = 17.625;
    const double c = 243.04;
    final double gamma = (b * temp) / (c + temp) + math.log(humidity / 100);
    return (c * gamma) / (b - gamma);
  }

  Map<String, dynamic> getUvDetails(double index) {
    if (index <= 2) return {'desc': 'Low', 'color': Colors.green};
    if (index <= 5) return {'desc': 'Moderate', 'color': Colors.yellow.shade700};
    if (index <= 7) return {'desc': 'High', 'color': Colors.orange};
    if (index <= 10) return {'desc': 'Very High', 'color': Colors.red};
    return {'desc': 'Extreme', 'color': Colors.purple};
  }
}