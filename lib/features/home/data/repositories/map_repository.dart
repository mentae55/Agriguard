// lib/data/repositories/map_repository.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../datasources/local/location_service.dart';
import '../datasources/remote/osrm_service.dart';
import '../model/map_models.dart';

abstract class MapRepository {
  Future<RouteModel> getRoute(LatLng origin, LatLng destination);
  Future<LocationModel?> getCurrentLocation();
}

class MapRepositoryImpl implements MapRepository {
  final OsrmService _osrmService;
  final LocationService _locationService;

  MapRepositoryImpl({
    OsrmService? osrmService,
    LocationService? locationService,
  })  : _osrmService = osrmService ?? OsrmService(),
        _locationService = locationService ?? LocationService();

  @override
  Future<RouteModel> getRoute(LatLng origin, LatLng destination) =>
      _osrmService.fetchRoute(origin, destination);

  @override
  Future<LocationModel?> getCurrentLocation() =>
      _locationService.getCurrentLocation();
}