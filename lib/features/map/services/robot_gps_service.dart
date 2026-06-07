// =============================================================================
// robot_gps_service.dart
// [NEW] Streams live robot GPS data from Firebase Realtime Database.
// The ESP32 writes to /Devices/{MAC}/gps every few seconds.
// =============================================================================

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';

class RobotGpsService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  StreamSubscription<DatabaseEvent>? _gpsSub;

  /// Starts listening to GPS updates from Firebase.
  /// [deviceMac] — the device MAC address with colons (e.g. "78:1C:3C:B8:8C:8A")
  /// [onLocationUpdate] — called whenever a new valid coordinate arrives
  Stream<LatLng> listenToRobotGps(String deviceMac) {
    final controller = StreamController<LatLng>.broadcast();

    // Cancel any previous subscription to avoid leaks
    _gpsSub?.cancel();

    final gpsPath = 'Devices/$deviceMac/gps';
    debugPrint('[RobotGpsService] Listening on: $gpsPath');

    _gpsSub = _db.child(gpsPath).onValue.listen(
      (DatabaseEvent event) {
        final data = event.snapshot.value;
        if (data == null) return;

        try {
          // Firebase returns a Map<Object?, Object?> — handle safely
          final map = Map<String, dynamic>.from(data as Map);
          final lat = (map['lat'] as num?)?.toDouble();
          final lng = (map['lng'] as num?)?.toDouble();

          if (lat != null && lng != null) {
            debugPrint('[RobotGpsService] GPS update → lat: $lat, lng: $lng');
            if (!controller.isClosed) {
              controller.add(LatLng(lat, lng));
            }
          }
        } catch (e) {
          debugPrint('[RobotGpsService] Parse error: $e');
        }
      },
      onError: (error) {
        debugPrint('[RobotGpsService] Stream error: $error');
      },
    );

    // Clean up subscription when the stream has no more listeners
    controller.onCancel = () {
      _gpsSub?.cancel();
      _gpsSub = null;
      debugPrint('[RobotGpsService] Stream cancelled.');
    };

    return controller.stream;
  }

  /// Disposes all active subscriptions — call from State.dispose()
  void dispose() {
    _gpsSub?.cancel();
    _gpsSub = null;
  }
}
