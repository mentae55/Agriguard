// lib/data/datasources/local/location_service.dart
import 'package:geolocator/geolocator.dart';

import '../../model/map_models.dart';

class LocationService {
  Future<LocationModel?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LocationModel(
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
    );
  }

  Future<LocationModel?> initAndGetLocation() async {
    return getCurrentLocation();
  }
}