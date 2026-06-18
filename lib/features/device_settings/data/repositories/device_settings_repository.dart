import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_settings_model.dart';

class DeviceSettingsRepository {
  static const String _key = 'agriguard_device_settings';

  Future<DeviceSettings> loadSettings({String? defaultSerial}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString == null) {
        final serial = defaultSerial ?? '122';
        final formattedSerial = serial.isEmpty ? '122' : serial;
        return DeviceSettings(
          deviceName: 'Device#$formattedSerial',
          serialNumber: 'SN: $formattedSerial-ABC',
          samplingInterval: 'Every 10 Minutes',
          dailyStartTime: '06:00 AM',
          batterySaverEnabled: false,
          lastUpdated: DateTime.now(),
        );
      }
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return DeviceSettings.fromJson(map);
    } catch (e) {
      final serial = defaultSerial ?? '122';
      final formattedSerial = serial.isEmpty ? '122' : serial;
      return DeviceSettings(
        deviceName: 'Device#$formattedSerial',
        serialNumber: 'SN: $formattedSerial-ABC',
        samplingInterval: 'Every 10 Minutes',
        dailyStartTime: '06:00 AM',
        batterySaverEnabled: false,
        lastUpdated: DateTime.now(),
      );
    }
  }

  Future<void> saveSettings(DeviceSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(settings.toJson());
    await prefs.setString(_key, jsonString);
  }

  Future<DeviceSettings> updateDeviceName(String name) async {
    final settings = await loadSettings();
    final updated = settings.copyWith(deviceName: name, lastUpdated: DateTime.now());
    await saveSettings(updated);
    return updated;
  }

  Future<DeviceSettings> updateSamplingInterval(String interval) async {
    final settings = await loadSettings();
    final updated = settings.copyWith(samplingInterval: interval, lastUpdated: DateTime.now());
    await saveSettings(updated);
    return updated;
  }

  Future<DeviceSettings> updateDailyStartTime(String startTime) async {
    final settings = await loadSettings();
    final updated = settings.copyWith(dailyStartTime: startTime, lastUpdated: DateTime.now());
    await saveSettings(updated);
    return updated;
  }

  Future<DeviceSettings> updateBatterySaver(bool enabled) async {
    final settings = await loadSettings();
    final updated = settings.copyWith(batterySaverEnabled: enabled, lastUpdated: DateTime.now());
    await saveSettings(updated);
    return updated;
  }
}
