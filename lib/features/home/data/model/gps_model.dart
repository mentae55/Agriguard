// lib/data/models/gps_models.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RobotGpsModel {
  final double lat;
  final double lng;
  final DateTime? timestamp;

  RobotGpsModel({required this.lat, required this.lng, this.timestamp});

  factory RobotGpsModel.fromJson(Map<String, dynamic> json) {
    return RobotGpsModel(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
    );
  }

  LatLng toLatLng() => LatLng(lat, lng);
}