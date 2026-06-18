import 'package:flutter/material.dart';
import '../data/models/device_settings_model.dart';
import '../data/repositories/device_settings_repository.dart';

enum DeviceSettingsState { loading, loaded, error }

class DeviceSettingsViewModel extends ChangeNotifier {
  final DeviceSettingsRepository _repository;
  final String _serial;

  DeviceSettings? _settings;
  DeviceSettingsState _state = DeviceSettingsState.loading;
  String _errorMessage = '';
  bool _isSaving = false;

  DeviceSettingsViewModel({
    required String serial,
    DeviceSettingsRepository? repository,
  })  : _serial = serial,
        _repository = repository ?? DeviceSettingsRepository();

  DeviceSettings? get settings => _settings;
  DeviceSettingsState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isLoading => _state == DeviceSettingsState.loading;
  bool get isSaving => _isSaving;

  Future<void> loadSettings() async {
    _state = DeviceSettingsState.loading;
    notifyListeners();
    try {
      _settings = await _repository.loadSettings(defaultSerial: _serial);
      _state = DeviceSettingsState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = DeviceSettingsState.error;
    }
    notifyListeners();
  }

  Future<bool> updateDeviceName(String name) async {
    _setSaving(true);
    try {
      _settings = await _repository.updateDeviceName(name);
      _setSaving(false);
      return true;
    } catch (e) {
      _setSaving(false);
      return false;
    }
  }

  Future<bool> updateSamplingInterval(String interval) async {
    _setSaving(true);
    try {
      _settings = await _repository.updateSamplingInterval(interval);
      _setSaving(false);
      return true;
    } catch (e) {
      _setSaving(false);
      return false;
    }
  }

  Future<bool> updateDailyStartTime(String startTime) async {
    _setSaving(true);
    try {
      _settings = await _repository.updateDailyStartTime(startTime);
      _setSaving(false);
      return true;
    } catch (e) {
      _setSaving(false);
      return false;
    }
  }

  Future<bool> updateBatterySaver(bool enabled) async {
    _setSaving(true);
    try {
      _settings = await _repository.updateBatterySaver(enabled);
      _setSaving(false);
      return true;
    } catch (e) {
      _setSaving(false);
      return false;
    }
  }

  void _setSaving(bool saving) {
    _isSaving = saving;
    notifyListeners();
  }
}
