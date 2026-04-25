import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  static const String DEVICE_NAME         = "AgriGuard_Robot";
  static const String SERVICE_UUID           = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String WIFI_CRED_CHAR_UUID    = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String WIFI_LIST_CHAR_UUID    = "c865921c-29b1-11ee-be56-0242ac120002";
  static const String WIFI_CMD_CHAR_UUID     = "beb5483e-36e1-4688-b7f5-ea07361b26aa";

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? _credCharacteristic;
  BluetoothCharacteristic? _listCharacteristic;
  BluetoothCharacteristic? _cmdCharacteristic;

  // ===== 1. Permissions =====
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  // ===== 2. Scan for AgriGuard =====
  Stream<List<ScanResult>> startScan() {
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      withNames: [DEVICE_NAME],
    );
    return FlutterBluePlus.scanResults;
  }

  void stopScan() => FlutterBluePlus.stopScan();

  // ===== 3. Connect =====
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
        mtu: null,
      );
      connectedDevice = device;

      await Future.delayed(const Duration(seconds: 2));

      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
          for (BluetoothCharacteristic char in service.characteristics) {
            final uuid = char.uuid.toString().toLowerCase();
            if (uuid == WIFI_CRED_CHAR_UUID.toLowerCase()) {
              _credCharacteristic = char;
            }
            if (uuid == WIFI_LIST_CHAR_UUID.toLowerCase()) {
              _listCharacteristic = char;
            }
            if (uuid == WIFI_CMD_CHAR_UUID.toLowerCase()) {
              _cmdCharacteristic = char;
            }
          }
        }
      }

      await _db.child('Devices/${device.remoteId}/bluetooth').update({
        'status': 'connected',
        'device_name': device.platformName,
        'last_seen': ServerValue.timestamp,
      });

      return _credCharacteristic != null;
    } catch (e) {
      print('BLE Connect Error: $e');
      return false;
    }
  }

  // ===== 4. Fetch WiFi List =====
  Future<List<String>> fetchWifiNetworks() async {
    if (connectedDevice == null) return [];

    try {
      if (_cmdCharacteristic != null) {
        await _cmdCharacteristic!.write(
          utf8.encode('SCAN_WIFI'),
          withoutResponse: false,
        );
        print('Sent: SCAN_WIFI');
        await Future.delayed(const Duration(seconds: 5));
      }

      if (_listCharacteristic != null) {
        final List<int> value = await _listCharacteristic!.read();
        final String raw = utf8.decode(value);
        print('WiFi List received: $raw');

        if (raw.isEmpty || raw == "No networks found") return [];
        return raw.split(',').where((s) => s.isNotEmpty).toList();
      }
    } catch (e) {
      print('fetchWifiNetworks Error: $e');
    }
    return [];
  }

  // ===== 5. Request WiFi List =====
  Future<void> requestWifiList() async {
    if (_cmdCharacteristic == null) return;

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (_listCharacteristic != null) {
        await _listCharacteristic!.setNotifyValue(true);
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final bytes = utf8.encode('SCAN_WIFI');
      await _cmdCharacteristic!.write(bytes, withoutResponse: false);
      print('Sent: SCAN_WIFI command');

    } catch (e) {
      print('requestWifiList Error: $e');
    }
  }

  // ===== 6. Listen to WiFi List =====
  Stream<List<String>> listenToWifiList() async* {
    if (_listCharacteristic == null) return;

    await _listCharacteristic!.setNotifyValue(true);

    await for (final value in _listCharacteristic!.lastValueStream) {
      if (value.isNotEmpty) {
        final raw = utf8.decode(value);
        final networks = raw.split(',')
            .where((s) => s.isNotEmpty)
            .toList();
        print('WiFi networks received: $networks');
        yield networks;
      }
    }
  }

  // ===== 7. إرسال WiFi Credentials (مع chunking لـ BLE 20-byte limit) =====
  Future<bool> sendWifiCredentials({
    required String ssid,
    required String password,
    required String serialNumber,
  }) async {
    if (_credCharacteristic == null) {
      print('DEBUG: _credCharacteristic is NULL! Connection might be lost.');
      return false;
    }

    try {
      // تنظيف البيانات من أي مسافات زائدة في البداية أو النهاية
      final cleanSSID = ssid.trim();
      final cleanPassword = password.trim();
      final cleanSerial = serialNumber.trim();

      // تجميع البيانات مع إضافة \n في النهاية كما يطلب الـ ESP32
      final String data = '$cleanSSID,$cleanPassword,$cleanSerial\n';
      final List<int> bytes = utf8.encode(data);
      const int chunkSize = 20;

      print('DEBUG: [BleService] Sending data to ESP32...');
      print('DEBUG: [BleService] Raw String: "$data"');
      print('DEBUG: [BleService] Total Bytes: ${bytes.length}');

      // تقسيم البيانات إلى أجزاء (Chunks) حجم كل منها 20 بايت
      for (int i = 0; i < bytes.length; i += chunkSize) {
        final int end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        final List<int> chunk = bytes.sublist(i, end);

        await _credCharacteristic!.write(chunk, withoutResponse: false);
        print('DEBUG: Chunk sent [${i ~/ chunkSize + 1}]: ${utf8.decode(chunk)}');

        // تأخير بسيط بين كل جزء لضمان معالجة الـ ESP32 للبيانات
        await Future.delayed(const Duration(milliseconds: 150));
      }

      print('DEBUG: [BleService] All data sent successfully ✅');

      // ننتظر قليلاً قبل تحديث Firebase والانتهاء للتأكد من أن الـ ESP32 استلم آخر بايت
      await Future.delayed(const Duration(seconds: 2));

      // نستخدم الـ MAC Address بالكامل (مع النقطتين) كمفتاح في قاعدة البيانات ليتطابق مع DeviceProvider
      final deviceMac = connectedDevice?.remoteId.toString() ?? cleanSerial;

      await _db.child('Devices/$deviceMac').update({
        'wifi_ssid': cleanSSID,
        'configured_at': ServerValue.timestamp,
        'online': false, // نضبطها لـ false في البداية
        'status': 0,
      });

      return true;
    } catch (e) {
      print('DEBUG: [BleService] BLE Write Error: $e');
      return false;
    }
  }

  // ===== 8. جيبي الـ Serial من الـ MAC Address =====
  String getDeviceSerial() {
    if (connectedDevice == null) return '';
    return connectedDevice!.remoteId.toString().replaceAll(':', '');
  }

  // جديد: الحصول على الـ ID الكامل (مع النقطتين) لاستخدامه في مسارات قاعدة البيانات
  String getDeviceId() {
    if (connectedDevice == null) return '';
    return connectedDevice!.remoteId.toString();
  }

  // ===== 9. مراقبة الاتصال بـ Firebase =====
  // يسمع على مسارين في نفس الوقت:
  // - المسار بـ colons:    /Devices/78:1C:3C:B8:8C:8A/online  (firmware الجديد)
  // - المسار بدون colons: /Devices/781C3CB88C8A/online          (firmware القديم)
  // فيشتغل مع أي firmware
  Stream<bool> listenToDeviceOnline(String macWithColons) {
    final macWithoutColons = macWithColons.replaceAll(':', '');

    final controller = StreamController<bool>.broadcast();
    StreamSubscription? sub1;
    StreamSubscription? sub2;

    void handleUpdate(DatabaseEvent event) {
      if (event.snapshot.value == true && !controller.isClosed) {
        debugPrint('DEBUG [Firebase]: online=true detected at path: ${event.snapshot.ref.path}');
        controller.add(true);
      }
    }

    sub1 = _db
        .child('Devices/$macWithColons/online')
        .onValue
        .listen(handleUpdate, onError: (e) => debugPrint('Stream1 error: $e'));

    sub2 = _db
        .child('Devices/$macWithoutColons/online')
        .onValue
        .listen(handleUpdate, onError: (e) => debugPrint('Stream2 error: $e'));

    controller.onCancel = () {
      sub1?.cancel();
      sub2?.cancel();
    };

    debugPrint('DEBUG [Firebase]: Listening on TWO paths:');
    debugPrint('  Path 1 (with colons):    Devices/$macWithColons/online');
    debugPrint('  Path 2 (without colons): Devices/$macWithoutColons/online');

    return controller.stream;
  }

  // ===== 10. التحكم في الريلاي =====
  Future<void> setRelayStatus({
    required String serialNumber,
    required int status,
  }) async {
    await _db.child('Devices/$serialNumber/status').set(status);
  }

  Stream<int> listenToRelayStatus(String serialNumber) {
    return _db
        .child('Devices/$serialNumber/status')
        .onValue
        .map((event) => (event.snapshot.value as int?) ?? 0);
  }

  // ===== 11. قطع الاتصال =====
  Future<void> disconnect() async {
    await connectedDevice?.disconnect();
    connectedDevice = null;
    _credCharacteristic = null;
    _listCharacteristic = null;
    _cmdCharacteristic = null;
  }
  // أضيفي هذه الدالة داخل كلاس BleService في ملف connection_service.dart

  Future<bool> connectToSavedDevice(String macAddress) async {
    try {
      // 1. تحويل الـ MAC Address لـ Device Identifier
      BluetoothDevice device = BluetoothDevice.fromId(macAddress);

      // 2. محاولة الاتصال
      await device.connect(timeout: const Duration(seconds: 15), autoConnect: false);

      // 3. تخزين الجهاز المتصل في الـ Service
      connectedDevice = device;

      // 4. اكتشاف الخدمات (مهم جداً للتعامل مع الـ ESP32 لاحقاً)
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString() == SERVICE_UUID) {
          for (var char in service.characteristics) {
            if (char.uuid.toString() == WIFI_CRED_CHAR_UUID) _credCharacteristic = char;
            if (char.uuid.toString() == WIFI_LIST_CHAR_UUID) _listCharacteristic = char;
            if (char.uuid.toString() == WIFI_CMD_CHAR_UUID)  _cmdCharacteristic = char;
          }
        }
      }
      return true;
    } catch (e) {
      print('Direct Connection Error: $e');
      return false;
    }
  }
  Future<bool> connectToSpecificDevice(String targetMac) async {
    try {
      // 1. ابدأ المسح
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      BluetoothDevice? targetDevice;

      // 2. انتظر ظهور الجهاز المطلوب في نتائج المسح
      await for (List<ScanResult> results in FlutterBluePlus.scanResults) {
        for (ScanResult r in results) {
          if (r.device.remoteId.toString() == targetMac) {
            targetDevice = r.device;
            break;
          }
        }
        if (targetDevice != null) break;
      }

      await FlutterBluePlus.stopScan();

      if (targetDevice != null) {
        // 3. اتصل بالجهاز
        await targetDevice.connect();
        connectedDevice = targetDevice;

        // 4. اكتشف الخدمات (مهم جداً للتعامل مع الخصائص لاحقاً)
        await targetDevice.discoverServices();
        return true;
      }
      return false;
    } catch (e) {
      print("Direct Connection Error: $e");
      return false;
    }
  }

}

