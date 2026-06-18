// lib/data/datasources/remote/firebase_service.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../../model/gps_model.dart';

class FirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _gpsSub;

  Stream<RobotGpsModel> listenToRobotGps(String deviceMac) {
    final controller = StreamController<RobotGpsModel>.broadcast();

    _gpsSub?.cancel();

    final gpsPath = 'Devices/$deviceMac/gps';
    debugPrint('[FirebaseService] Listening on: $gpsPath');

    _gpsSub = _db.child(gpsPath).onValue.listen(
          (DatabaseEvent event) {
        final data = event.snapshot.value;
        if (data == null) return;

        try {
          final map = Map<String, dynamic>.from(data as Map);
          final model = RobotGpsModel.fromJson(map);
          if (!controller.isClosed) controller.add(model);
        } catch (e) {
          debugPrint('[FirebaseService] Parse error: $e');
        }
      },
      onError: (error) => debugPrint('[FirebaseService] Stream error: $error'),
    );

    controller.onCancel = () {
      _gpsSub?.cancel();
      _gpsSub = null;
    };

    return controller.stream;
  }

  void dispose() {
    _gpsSub?.cancel();
    _gpsSub = null;
  }
}