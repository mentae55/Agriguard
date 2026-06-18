// lib/data/repositories/weather_repository.dart
import '../model/weather_model.dart';
import '../datasources/remote/weather_api_service.dart';

abstract class WeatherRepository {
  Future<WeatherData> fetchWeather(CityConfig city);
}

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherApiService _apiService;

  WeatherRepositoryImpl({WeatherApiService? apiService})
      : _apiService = apiService ?? WeatherApiService();

  @override
  Future<WeatherData> fetchWeather(CityConfig city) => _apiService.fetchWeather(city);
}