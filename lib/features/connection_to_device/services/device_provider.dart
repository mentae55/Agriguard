import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

enum DeviceStatus { loading, found, notFound, error }

class DeviceProvider extends ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // تعريف StreamSubscriptions لإغلاقهما عند الضرورة وتجنب تسريب الذاكرة
  StreamSubscription<DatabaseEvent>? _statusSubscription;  // MAC مع colons
  StreamSubscription<DatabaseEvent>? _statusSub2;          // MAC بدون colons

  DeviceStatus _status = DeviceStatus.loading;
  String? _savedMac;
  String? _savedSerial;
  bool _isDeviceOnline = false;

  DeviceStatus get status => _status;
  String? get savedMac => _savedMac;
  String? get savedSerial => _savedSerial;
  bool get hasDevice => _status == DeviceStatus.found;
  bool get isDeviceOnline => _isDeviceOnline;

  /// [تحسين] دالة الفحص الأساسية
  Future<void> checkSavedDevice(String userId) async {
    _status = DeviceStatus.loading;
    notifyListeners();

    try {
      final snapshot = await _db.child('Users/$userId/device_mac').get();

      if (snapshot.exists && snapshot.value != null) {
        _savedMac = snapshot.value.toString();
        _savedSerial = _savedMac!.replaceAll(':', '');
        _status = DeviceStatus.found;

        // [إضافة] ابدأ مراقبة حالة الـ Online فوراً
        _listenToDeviceOnlineStatus(_savedMac!);
      } else {
        _resetDeviceData();
        _status = DeviceStatus.notFound;
      }
    } catch (e) {
      debugPrint('DeviceProvider Error: $e');
      _status = DeviceStatus.error;
    }
    notifyListeners();
  }

  /// [جديد] مراقبة حالة الجهاز Real-time على مسارين:
  /// - /Devices/{MAC_WITH_COLONS}/online    (firmware الجديد)
  /// - /Devices/{MAC_WITHOUT_COLONS}/online (firmware القديم)
  void _listenToDeviceOnlineStatus(String macWithColons) {
    _statusSubscription?.cancel();
    _statusSub2?.cancel();

    final macWithoutColons = macWithColons.replaceAll(':', '');
    bool online1 = false;
    bool online2 = false;

    // المسار الأول: مع colons
    _statusSubscription = _db
        .child('Devices/$macWithColons/online')
        .onValue
        .listen((event) {
      online1 = event.snapshot.value == true;
      _isDeviceOnline = online1 || online2;
      notifyListeners();
    }, onError: (error) {
      debugPrint('Stream1 Error: $error');
    });

    // المسار الثاني: بدون colons (للـ firmware القديم)
    _statusSub2 = _db
        .child('Devices/$macWithoutColons/online')
        .onValue
        .listen((event) {
      online2 = event.snapshot.value == true;
      _isDeviceOnline = online1 || online2;
      notifyListeners();
    }, onError: (error) {
      debugPrint('Stream2 Error: $error');
    });

    debugPrint('DeviceProvider: Listening on paths:');
    debugPrint('  Devices/$macWithColons/online');
    debugPrint('  Devices/$macWithoutColons/online');
  }

  /// [تحسين] زرار الـ Refresh اليدوي
  /// حتى مع وجود Stream، الزرار ده هيفيد لو المستخدم عايز يتأكد يدوياً
  Future<void> refreshOnlineStatus() async {
    if (_savedMac == null) return;

    try {
      // نستخدم get(ForceRefresh) للتأكد من تخطي الكاش المحلي
      final snapshot = await _db.child('Devices/$_savedMac/online').get();
      _isDeviceOnline = snapshot.value == true;
      notifyListeners();
    } catch (e) {
      debugPrint('Refresh Error: $e');
    }
  }

  Future<void> saveDevice(String userId, String macAddress) async {
    try {
      await _db.child('Users/$userId').update({
        'device_mac': macAddress,
        'linked_at': ServerValue.timestamp,
      });
      _savedMac = macAddress;
      _savedSerial = macAddress.replaceAll(':', '');
      _status = DeviceStatus.found;
      _listenToDeviceOnlineStatus(macAddress); // ابدأ المراقبة فور الحفظ
    } catch (e) {
      debugPrint('saveDevice Error: $e');
    }
  }

  Future<void> removeDevice(String userId) async {
    try {
      _statusSubscription?.cancel();
      _statusSub2?.cancel();
      await _db.child('Users/$userId/device_mac').remove();
      _resetDeviceData();
      _status = DeviceStatus.notFound;
      notifyListeners();
    } catch (e) {
      debugPrint('removeDevice Error: $e');
    }
  }

  void _resetDeviceData() {
    _savedMac = null;
    _savedSerial = null;
    _isDeviceOnline = false;
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _statusSub2?.cancel();
    super.dispose();
  }
}