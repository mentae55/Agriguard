
import '../models/soil_alert_engine.dart';
import '../models/alert_model.dart';
import '../services/alerts_api_service.dart';
import 'package:agriguard_project/features/home/view/soil_analysis_screen.dart' show SoilSnapshot;

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