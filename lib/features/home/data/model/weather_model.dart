// lib/data/models/weather_models.dart
import 'dart:math' as math;

class CityConfig {
  final String name;
  final double lat;
  final double lon;
  final String timezone;

  const CityConfig({
    required this.name,
    required this.lat,
    required this.lon,
    required this.timezone,
  });
}

class WeatherData {
  final double temp;
  final int humidity;
  final double feelsLike;
  final double windSpeed;
  final double windDir;
  final double precipitation;
  final int weatherCode;
  final int isDay;
  final double uvIndex;
  final String sunrise;
  final String sunset;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;

  WeatherData({
    required this.temp,
    required this.humidity,
    required this.feelsLike,
    required this.windSpeed,
    required this.windDir,
    required this.precipitation,
    required this.weatherCode,
    required this.isDay,
    required this.uvIndex,
    required this.sunrise,
    required this.sunset,
    required this.hourly,
    required this.daily,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final hourlyMap = json['hourly'] as Map<String, dynamic>;
    final dailyMap = json['daily'] as Map<String, dynamic>;

    final List<HourlyForecast> hourlyList = [];
    final times = hourlyMap['time'] as List;
    final temps = hourlyMap['temperature_2m'] as List;
    final codes = hourlyMap['weather_code'] as List;

    final String nowStr = current['time'] as String;
    int startIndex = 0;
    try {
      final nowTime = DateTime.parse(nowStr);
      for (int i = 0; i < times.length; i++) {
        final t = DateTime.parse(times[i] as String);
        if (t.isAfter(nowTime) || t.isAtSameMomentAs(nowTime)) {
          startIndex = i;
          break;
        }
      }
    } catch (_) {}

    for (int i = startIndex; i < math.min(startIndex + 24, times.length); i++) {
      hourlyList.add(HourlyForecast(
        time: times[i] as String,
        temp: (temps[i] as num).toDouble(),
        weatherCode: (codes[i] as num).toInt(),
      ));
    }

    final List<DailyForecast> dailyList = [];
    final dTimes = dailyMap['time'] as List;
    final dMaxes = dailyMap['temperature_2m_max'] as List;
    final dMins = dailyMap['temperature_2m_min'] as List;
    final dCodes = dailyMap['weather_code'] as List;

    for (int i = 0; i < math.min(7, dTimes.length); i++) {
      dailyList.add(DailyForecast(
        date: dTimes[i] as String,
        tempMax: (dMaxes[i] as num).toDouble(),
        tempMin: (dMins[i] as num).toDouble(),
        weatherCode: (dCodes[i] as num).toInt(),
      ));
    }

    String sunriseStr = '';
    String sunsetStr = '';
    try {
      final sunrises = dailyMap['sunrise'] as List;
      final sunsets = dailyMap['sunset'] as List;
      if (sunrises.isNotEmpty && sunsets.isNotEmpty) {
        sunriseStr = sunrises[0] as String;
        sunsetStr = sunsets[0] as String;
      }
    } catch (_) {}

    double uvVal = 0.0;
    try {
      final uvs = dailyMap['uv_index_max'] as List;
      if (uvs.isNotEmpty) uvVal = (uvs[0] as num).toDouble();
    } catch (_) {}

    return WeatherData(
      temp: (current['temperature_2m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      windDir: (current['wind_direction_10m'] as num).toDouble(),
      precipitation: (current['precipitation'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
      isDay: (current['is_day'] as num).toInt(),
      uvIndex: uvVal,
      sunrise: sunriseStr,
      sunset: sunsetStr,
      hourly: hourlyList,
      daily: dailyList,
    );
  }
}

class HourlyForecast {
  final String time;
  final double temp;
  final int weatherCode;
  HourlyForecast({required this.time, required this.temp, required this.weatherCode});
}

class DailyForecast {
  final String date;
  final double tempMax;
  final double tempMin;
  final int weatherCode;
  DailyForecast({required this.date, required this.tempMax, required this.tempMin, required this.weatherCode});
}