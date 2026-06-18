// lib/data/repositories/gps_repository.dart
import 'dart:async';
import '../datasources/remote/firebase_service.dart';
import '../model/gps_model.dart';

abstract class GpsRepository {
  Stream<RobotGpsModel> getRobotGpsStream(String deviceMac);
  void dispose();
}

class GpsRepositoryImpl implements GpsRepository {
  final FirebaseService _firebaseService;

  GpsRepositoryImpl({FirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? FirebaseService();

  @override
  Stream<RobotGpsModel> getRobotGpsStream(String deviceMac) {
    return _firebaseService.listenToRobotGps(deviceMac);
  }

  @override
  void dispose() => _firebaseService.dispose();
}