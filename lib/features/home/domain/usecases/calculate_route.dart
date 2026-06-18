// lib/domain/usecases/calculate_route.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/model/map_models.dart';
import '../../data/repositories/map_repository.dart';

class CalculateRouteUseCase {
  final MapRepository _repository;

  CalculateRouteUseCase({required MapRepository repository})
      : _repository = repository;

  Future<RouteModel> call(LatLng origin, LatLng destination) =>
      _repository.getRoute(origin, destination);

  Future<LocationModel?> getCurrentLocation() =>
      _repository.getCurrentLocation();
}