// lib/presentation/viewmodels/map_viewmodel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/model/gps_model.dart';
import '../../data/model/map_models.dart';
import '../../domain/usecases/calculate_route.dart';
import '../../domain/usecases/stream_robot_gps.dart';

class MapViewModel extends ChangeNotifier {
  final CalculateRouteUseCase _calculateRoute;
  final StreamRobotGpsUseCase? _streamRobotGps;

  MapViewModel({
    required CalculateRouteUseCase calculateRoute,
    StreamRobotGpsUseCase? streamRobotGps,
  })  : _calculateRoute = calculateRoute,
        _streamRobotGps = streamRobotGps;

  // State
  final Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  LocationModel? currentPosition;
  RobotGpsModel? robotPosition;
  bool isLoadingRoute = false;
  bool showRoute = false;
  double routeDistance = 0.0;
  double routeDuration = 0.0;

  StreamSubscription<RobotGpsModel>? _gpsSub;

  Future<void> initializeLocation() async {
    final loc = await _calculateRoute.getCurrentLocation();
    if (loc != null) {
      currentPosition = loc;
      _addMarker(
        LatLng(loc.latitude, loc.longitude),
        "current",
        "Current Location",
        BitmapDescriptor.hueAzure,
      );
      notifyListeners();
    }
  }

  void startRobotGpsStream(String? deviceMac) {
    if (deviceMac == null || _streamRobotGps == null) return;

    _gpsSub = _streamRobotGps(deviceMac).listen(
          (model) {
        robotPosition = model;
        _updateRobotMarker(model.toLatLng());
        notifyListeners();
      },
      onError: (e) => debugPrint('[MapViewModel] Robot GPS error: $e'),
    );
  }

  void _updateRobotMarker(LatLng pos) {
    markers.removeWhere((m) => m.markerId.value == 'robot');
    markers.add(
      Marker(
        markerId: const MarkerId('robot'),
        position: pos,
        infoWindow: InfoWindow(
          title: '🤖 AgriGuard Robot',
          snippet: 'Lat: ${pos.latitude.toStringAsFixed(5)}, Lng: ${pos.longitude.toStringAsFixed(5)}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );
  }

  void _addMarker(LatLng pos, String id, String title, double hue) {
    markers.removeWhere((m) => m.markerId.value == id);
    markers.add(
      Marker(
        markerId: MarkerId(id),
        position: pos,
        infoWindow: InfoWindow(title: title),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      ),
    );
  }

  Future<void> setDestination(LatLng tappedPoint) async {
    _addMarker(tappedPoint, "destination", "Destination", BitmapDescriptor.hueRed);

    if (currentPosition == null) return;

    isLoadingRoute = true;
    notifyListeners();

    try {
      final route = await _calculateRoute(
        LatLng(currentPosition!.latitude, currentPosition!.longitude),
        tappedPoint,
      );

      polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: route.points,
          color: primaryColor,
          width: 5,
        ),
      };
      routeDistance = route.distance;
      routeDuration = route.duration;
      showRoute = true;
    } catch (e) {
      debugPrint('Route error: $e');
    } finally {
      isLoadingRoute = false;
      notifyListeners();
    }
  }

  void clearRoute() {
    showRoute = false;
    polylines.clear();
    markers.removeWhere((m) => m.markerId.value == "destination");
    notifyListeners();
  }

  CameraPosition getInitialPosition() => const CameraPosition(
    target: LatLng(30.0444, 31.2357),
    zoom: 14.4746,
  );

  CameraPosition? getCurrentCameraPosition() {
    if (currentPosition == null) return null;
    return CameraPosition(
      target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
      zoom: 16.5,
    );
  }

  CameraPosition? getRobotCameraPosition() {
    if (robotPosition == null) return null;
    return CameraPosition(
      target: robotPosition!.toLatLng(),
      zoom: 17,
    );
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    super.dispose();
  }
}