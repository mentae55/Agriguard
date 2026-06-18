// lib/data/models/map_models.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteModel {
  final List<LatLng> points;
  final double distance;
  final double duration;

  RouteModel({required this.points, required this.distance, required this.duration});
}

class LocationModel {
  final double latitude;
  final double longitude;
  final double accuracy;

  LocationModel({required this.latitude, required this.longitude, required this.accuracy});
}
