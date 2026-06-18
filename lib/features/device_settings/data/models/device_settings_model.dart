class DeviceSettings {
  final String deviceName;
  final String serialNumber;
  final String samplingInterval;
  final String dailyStartTime;
  final bool batterySaverEnabled;
  final DateTime lastUpdated;

  const DeviceSettings({
    required this.deviceName,
    required this.serialNumber,
    required this.samplingInterval,
    required this.dailyStartTime,
    required this.batterySaverEnabled,
    required this.lastUpdated,
  });

  DeviceSettings copyWith({
    String? deviceName,
    String? serialNumber,
    String? samplingInterval,
    String? dailyStartTime,
    bool? batterySaverEnabled,
    DateTime? lastUpdated,
  }) {
    return DeviceSettings(
      deviceName: deviceName ?? this.deviceName,
      serialNumber: serialNumber ?? this.serialNumber,
      samplingInterval: samplingInterval ?? this.samplingInterval,
      dailyStartTime: dailyStartTime ?? this.dailyStartTime,
      batterySaverEnabled: batterySaverEnabled ?? this.batterySaverEnabled,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceName': deviceName,
      'serialNumber': serialNumber,
      'samplingInterval': samplingInterval,
      'dailyStartTime': dailyStartTime,
      'batterySaverEnabled': batterySaverEnabled,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory DeviceSettings.fromJson(Map<String, dynamic> json) {
    return DeviceSettings(
      deviceName: json['deviceName'] as String? ?? 'Device#122',
      serialNumber: json['serialNumber'] as String? ?? 'SN: 12345-ABC',
      samplingInterval: json['samplingInterval'] as String? ?? 'Every 10 Minutes',
      dailyStartTime: json['dailyStartTime'] as String? ?? '06:00 AM',
      batterySaverEnabled: json['batterySaverEnabled'] as bool? ?? false,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }
}
