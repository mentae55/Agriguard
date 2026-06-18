// lib/domain/usecases/fetch_weather.dart
import '../../data/model/weather_model.dart';
import '../../data/repositories/weather_repository.dart';

class FetchWeatherUseCase {
  final WeatherRepository _repository;

  FetchWeatherUseCase({required WeatherRepository repository})
      : _repository = repository;

  Future<WeatherData> call(CityConfig city) => _repository.fetchWeather(city);
}