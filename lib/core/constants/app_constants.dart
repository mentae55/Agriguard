class AppConstants {
  AppConstants._();

  static const String baseUrl = 'https://malakmohamed21-robot-api.hf.space';
  static const Duration pollInterval = Duration(seconds: 12);
  static const Duration soilPollInterval = Duration(seconds: 5);
  static const String weatherApi = 'https://api.open-meteo.com/v1/forecast';
  static const String osrmApi = 'https://router.project-osrm.org/route/v1/driving';
}