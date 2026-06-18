// lib/presentation/viewmodels/soil_analysis_viewmodel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/model/soil_model.dart';
import '../../domain/usecases/fetch_soil_data.dart';

class SoilAnalysisViewModel extends ChangeNotifier {
  final FetchSoilDataUseCase _fetchSoilData;

  SoilAnalysisViewModel({required FetchSoilDataUseCase fetchSoilData})
      : _fetchSoilData = fetchSoilData;

  SoilSnapshot? latest;
  final List<SoilSnapshot> history = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  StreamSubscription<SoilSnapshot>? _sub;

  Future<void> initialize() async {
    try {
      _sub = _fetchSoilData().listen(
            (snap) {
          latest = snap;
          history.add(snap);
          if (history.length > 20) history.removeAt(0);
          isLoading = false;
          hasError = false;
          notifyListeners();
        },
        onError: (e) {
          isLoading = false;
          hasError = true;
          errorMessage = e.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      isLoading = false;
      hasError = true;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy': return Colors.green.shade600;
      case 'warning': return orangeColor;
      case 'critical': return redColor;
      default: return grayColor;
    }
  }

  Color statusBg(String status, {bool isDark = false}) {
    switch (status.toLowerCase()) {
      case 'healthy': return isDark ? const Color(0xFF1A3A1A) : const Color(0xFFF0FDF4);
      case 'warning': return isDark ? const Color(0xFF3A2F1A) : const Color(0xFFFFF8E1);
      case 'critical': return isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFFEBEE);
      default: return isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    }
  }

  String formatTimestamp(String ts) {
    if (ts.isEmpty) return '--';
    try {
      final dt = DateTime.parse(ts);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, $h:$m';
    } catch (_) {
      return ts;
    }
  }

  String formatParamName(String raw) {
    return raw
        .replaceAll('_ppm', '')
        .replaceAll('_pct', '')
        .replaceAll('_c', '')
        .replaceAll('_ds_m', '')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Color? alertColorForParam(String paramKey) {
    if (latest == null) return null;
    for (final a in latest!.alerts) {
      if (a.param == paramKey) {
        return a.severity.toLowerCase() == 'critical' ? redColor : orangeColor;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}