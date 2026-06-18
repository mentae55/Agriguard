// ============================================================
// spectral_history_view_model.dart
// ============================================================
import 'package:flutter/foundation.dart';
import '../data/models/spectral_history_entry.dart';
import '../data/repositories/spectral_history_repository.dart';

enum HistoryFilter { all, none, medium, high }
enum HistorySortOrder { newestFirst, oldestFirst, highestRisk }

class SpectralHistoryViewModel extends ChangeNotifier {
  final SpectralHistoryRepository _repo;

  SpectralHistoryViewModel({SpectralHistoryRepository? repo})
      : _repo = repo ?? SpectralHistoryRepository();

  List<SpectralHistoryEntry> _allEntries = [];
  bool _isLoading = false;
  String _searchQuery = '';
  HistoryFilter _filter = HistoryFilter.all;
  HistorySortOrder _sortOrder = HistorySortOrder.newestFirst;

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  HistoryFilter get filter => _filter;
  HistorySortOrder get sortOrder => _sortOrder;

  List<SpectralHistoryEntry> get entries {
    var list = List<SpectralHistoryEntry>.from(_allEntries);

    // Filter by risk level
    if (_filter != HistoryFilter.all) {
      final level = _filter.name.toUpperCase();
      list = list.where((e) => e.riskLevel.toUpperCase() == level).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) =>
          e.plantId.toLowerCase().contains(q) ||
          e.likelyDisease.toLowerCase().contains(q) ||
          e.predictedGroup.toLowerCase().contains(q)).toList();
    }

    // Sort
    switch (_sortOrder) {
      case HistorySortOrder.newestFirst:
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case HistorySortOrder.oldestFirst:
        list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case HistorySortOrder.highestRisk:
        list.sort((a, b) => b.riskProbability.compareTo(a.riskProbability));
        break;
    }

    return list;
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();
    _allEntries = await _repo.fetchHistory();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _repo.clearHistory();
    _allEntries = [];
    notifyListeners();
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setFilter(HistoryFilter f) {
    _filter = f;
    notifyListeners();
  }

  void setSortOrder(HistorySortOrder s) {
    _sortOrder = s;
    notifyListeners();
  }
}
