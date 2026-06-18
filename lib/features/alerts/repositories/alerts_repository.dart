
import '../../home/data/model/soil_model.dart';
import '../models/soil_alert_engine.dart';
import '../models/alert_model.dart';
import '../services/alerts_api_service.dart';

class AlertsRepository {
  final AlertsApiService _apiService;

  AlertsRepository({AlertsApiService? apiService})
      : _apiService = apiService ?? AlertsApiService();

  Future<List<GeneratedAlert>> fetchAndEvaluateAlerts() async {
    final snapshot = await _apiService.fetchLatestSnapshot();
    return SoilAlertEngine.evaluate(snapshot);
  }

  Future<SoilSnapshot> fetchLatestSnapshot() async {
    return await _apiService.fetchLatestSnapshot();
  }
}