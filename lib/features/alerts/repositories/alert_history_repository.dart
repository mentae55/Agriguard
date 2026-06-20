import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_model.dart';

class AlertHistoryRepository {
  static const String _key = 'agriguard_alert_history';

  Future<List<GeneratedAlert>> fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString == null) return [];
      final List<dynamic> list = json.decode(jsonString);
      return list.map((item) => GeneratedAlert.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveHistory(List<GeneratedAlert> history) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(history.map((a) => a.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  Future<void> saveAlert(GeneratedAlert alert) async {
    final history = await fetchHistory();
    history.add(alert);
    await saveHistory(history);
  }

  Future<void> updateAlert(GeneratedAlert alert) async {
    final history = await fetchHistory();
    final idx = history.indexWhere((a) => a.historyId == alert.historyId);
    if (idx != -1) {
      history[idx] = alert;
      await saveHistory(history);
    }
  }

  Future<void> resolveAlert(String historyId, DateTime resolvedAt) async {
    final history = await fetchHistory();
    final idx = history.indexWhere((a) => a.historyId == historyId);
    if (idx != -1) {
      history[idx] = history[idx].copyWith(
        isResolved: true,
        resolvedAt: resolvedAt,
        updatedAt: resolvedAt,
      );
      await saveHistory(history);
    }
  }

  // NEW: mark an alert as viewed without touching its resolution state
  Future<void> markAsViewed(String historyId, DateTime viewedAt) async {
    final history = await fetchHistory();
    final idx = history.indexWhere((a) => a.historyId == historyId);
    if (idx != -1 && !history[idx].isViewed) {
      history[idx] = history[idx].copyWith(
        isViewed: true,
        viewedAt: viewedAt,
      );
      await saveHistory(history);
    }
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}