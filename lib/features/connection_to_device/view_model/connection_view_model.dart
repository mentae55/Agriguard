import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/connection_service.dart';

class ConnectionViewModel extends ChangeNotifier {
  final BleService _bleService = BleService();
  BleService get bleService => _bleService;

  // --- Bluetooth Scan State ---
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _connectingDeviceId;

  List<ScanResult> get scanResults => _scanResults;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  String? get connectingDeviceId => _connectingDeviceId;

  // --- WiFi Configuration State ---
  List<String> _wifiNetworks = [];
  String? _selectedSSID;
  bool _isLoadingNetworks = false;
  bool _isSending = false;
  String _statusMessage = '';
  bool _isSuccess = false;
  bool _showHiddenNetworkSection = false;
  bool _isHiddenNetwork = false;
  // الـ MAC نحتفظ بيه قبل ما نعمل disconnect من BLE
  String? _lastConnectedMac;

  List<String> get wifiNetworks => _wifiNetworks;
  String? get selectedSSID => _selectedSSID;
  bool get isLoadingNetworks => _isLoadingNetworks;
  bool get isSending => _isSending;
  String get statusMessage => _statusMessage;
  bool get isSuccess => _isSuccess;
  bool get showHiddenNetworkSection => _showHiddenNetworkSection;
  bool get isHiddenNetwork => _isHiddenNetwork;
  // الـ MAC متاح حتى بعد قطع الـ BLE
  String? get lastConnectedMac => _lastConnectedMac;

  // --- Bluetooth Methods ---

  Future<void> checkPermissions() async {
    await _bleService.requestPermissions();
  }

  void startScan() {
    _scanResults = [];
    _isScanning = true;
    notifyListeners();

    _bleService.startScan().listen((results) {
      _scanResults = results;
      notifyListeners();
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      _isScanning = scanning;
      notifyListeners();
    });
  }

  void stopScan() {
    _bleService.stopScan();
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    _isConnecting = true;
    _connectingDeviceId = device.remoteId.toString();
    notifyListeners();

    final success = await _bleService.connectToDevice(device);

    _isConnecting = false;
    _connectingDeviceId = null;
    notifyListeners();
    
    if (success) {
      // Reset WiFi state for new connection
      resetWifiState();
    }
    
    return success;
  }

  // --- WiFi Methods ---

  void resetWifiState() {
    _wifiNetworks = [];
    _selectedSSID = null;
    _statusMessage = '';
    _isSuccess = false;
    _isHiddenNetwork = false;
    _showHiddenNetworkSection = false;
    notifyListeners();
  }

  void setSelectedSSID(String? ssid, bool isHidden, bool showSection) {
    _selectedSSID = ssid;
    _isHiddenNetwork = isHidden;
    _showHiddenNetworkSection = showSection;
    notifyListeners();
  }

  Future<void> loadWifiNetworks() async {
    _isLoadingNetworks = true;
    _wifiNetworks = [];
    notifyListeners();

    try {
      final networks = await _bleService.fetchWifiNetworks();
      _wifiNetworks = networks;
    } catch (e) {
      debugPrint('Error loading WiFi: $e');
    } finally {
      _isLoadingNetworks = false;
      notifyListeners();
    }
  }

  Future<void> connectToWifi({
    required String password,
    String? hiddenSSID,
  }) async {
    _isSending = true;
    _statusMessage = '📡 Sending credentials to AgriGuard...';
    _isSuccess = false;
    notifyListeners();

    final String ssid = _isHiddenNetwork ? (hiddenSSID ?? '') : (_selectedSSID ?? '');
    final String serial = _bleService.getDeviceSerial();
    final String fullId = _bleService.getDeviceId();

    print('DEBUG: [ViewModel] Connection started');
    print('DEBUG: [ViewModel] SSID: $ssid');
    print('DEBUG: [ViewModel] Serial (for ESP): $serial');
    print('DEBUG: [ViewModel] Full ID (for Firebase): $fullId');

    final sent = await _bleService.sendWifiCredentials(
      ssid: ssid,
      password: password,
      serialNumber: serial,
    );

    if (!sent) {
      _isSending = false;
      _statusMessage = '❌ Failed to send. Check BLE connection.';
      notifyListeners();
      return;
    }

    _statusMessage = '⏳ Waiting for ESP32 to connect...';
    notifyListeners();

    _bleService.listenToDeviceOnline(fullId).timeout(
      const Duration(seconds: 45),
      onTimeout: (sink) {
        _isSending = false;
        _statusMessage = '⏱️ Timeout. Check credentials and try again.';
        notifyListeners();
        sink.close();
      },
    ).listen((isOnline) {
      if (isOnline) {
        // نحفظ الـ MAC قبل الـ disconnect لأن connectedDevice هيبقى null بعدها
        _lastConnectedMac = fullId;
        _isSending = false;
        _statusMessage = '✅ AgriGuard connected successfully!';
        _isSuccess = true;
        _bleService.disconnect();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _bleService.stopScan();
    super.dispose();
  }
}
