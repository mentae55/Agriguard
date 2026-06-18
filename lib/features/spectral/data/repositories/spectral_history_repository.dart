// ============================================================
// spectral_history_repository.dart — SharedPreferences storage
// ============================================================
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/spectral_history_entry.dart';

class SpectralHistoryRepository {
  static const String _key = 'agriguard_spectral_history';
  
  List<SpectralHistoryEntry>? _cache;

  Future<List<SpectralHistoryEntry>> fetchHistory() async {
    if (_cache != null) return _cache!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString == null) {
        _cache = [];
        return _cache!;
      }
      final List<dynamic> list = json.decode(jsonString);
      _cache = list
          .map((item) => SpectralHistoryEntry.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList();
      return _cache!;
    } catch (_) {
      _cache = [];
      return _cache!;
    }
  }

  Future<void> _saveHistory(List<SpectralHistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    // Run encoding in background to avoid jank on main thread if list is large
    final jsonString = await compute<List<SpectralHistoryEntry>, String>(
      (list) => json.encode(list.map((e) => e.toJson()).toList()),
      history,
    );
    await prefs.setString(_key, jsonString);
  }

  Future<bool> addEntry(SpectralHistoryEntry entry) async {
    final history = await fetchHistory();
    // Prevent duplicate entries based on timestamp
    if (history.isNotEmpty && history.first.timestamp == entry.timestamp) {
      return false;
    }
    
    history.insert(0, entry); // newest first
    // Keep max 200 entries
    if (history.length > 200) history.removeRange(200, history.length);
    
    // Fire and forget save (don't block UI)
    _saveHistory(history);
    return true;
  }

  Future<void> clearHistory() async {
    _cache = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
