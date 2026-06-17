// =============================================================================
// map_screen.dart
// [MODIFIED] — Added live robot GPS marker layer on top of existing map.
// All original map logic (user location, route planning) is preserved.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_project/core/core.dart';
import 'package:agriguard_project/features/connection_to_device/services/device_provider.dart';
import '../services/map_services.dart';
import '../services/robot_gps_service.dart';
import '../widgets/map_widgets.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  // [EXISTING] Services
  late LocationService _locationService;
  late RouteService _routeService;

  // [NEW] Robot GPS service
  final RobotGpsService _robotGpsService = RobotGpsService();
  StreamSubscription<LatLng>? _robotGpsSub;

  final Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Position? _currentPosition;

  bool _isLoadingRoute = false;
  bool _showRoute = false;
  double _routeDistance = 0.0;
  double _routeDuration = 0.0;

  // [NEW] Track the robot's last known position for the info chip
  LatLng? _robotPosition;

  // Initial dummy position (Cairo, Egypt — same as ESP32 base coordinates)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(30.0444, 31.2357),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _initServices();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRobotGpsStream());
  }

  @override
  void dispose() {
    _robotGpsSub?.cancel();
    _robotGpsService.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // [EXISTING] Initialize location and route services — unchanged
  // ---------------------------------------------------------------------------
  void _initServices() {
    _locationService = LocationService(
      onLocationUpdate: (Position pos) {
        setState(() {
          _currentPosition = pos;
        });
        _goToCurrentLocation();
      },
      showSnackBar: (String msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      },
      updateCurrentMarker: (Position pos) {
        _addMarker(LatLng(pos.latitude, pos.longitude), "current", "Current Location");
      },
    );

    _routeService = RouteService(
      setIsLoadingRoute: (bool val) => setState(() => _isLoadingRoute = val),
      setPolylines: (Set<Polyline> polys) => setState(() => _polylines = polys),
      setShowRoute: (bool val) => setState(() => _showRoute = val),
      setRouteInfo: (double dist, double dur) => setState(() {
        _routeDistance = dist;
        _routeDuration = dur;
      }),
      showSnackBar: (String msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      },
    );

    _locationService.initLocation();
  }

  // ---------------------------------------------------------------------------
  // [NEW] Subscribe to robot GPS stream from Firebase
  // Uses DeviceProvider to get the MAC address of the connected device.
  // ---------------------------------------------------------------------------
  void _startRobotGpsStream() {
    final mac = context.read<DeviceProvider>().savedMac;
    if (mac == null) {
      debugPrint('[MapScreen] No device MAC — skipping robot GPS stream.');
      return;
    }

    debugPrint('[MapScreen] Starting robot GPS stream for $mac');
    _robotGpsSub = _robotGpsService.listenToRobotGps(mac).listen(
      (LatLng latLng) {
        _updateRobotMarker(latLng);
      },
      onError: (e) => debugPrint('[MapScreen] Robot GPS error: $e'),
    );
  }

  // ---------------------------------------------------------------------------
  // [NEW] Update the robot marker and animate camera to follow it
  // ---------------------------------------------------------------------------
  void _updateRobotMarker(LatLng pos) {
    setState(() {
      _robotPosition = pos;
      _markers.removeWhere((m) => m.markerId.value == 'robot');
      _markers.add(
        Marker(
          markerId: const MarkerId('robot'),
          position: pos,
          infoWindow: InfoWindow(
            title: '🤖 AgriGuard Robot',
            snippet: 'Lat: ${pos.latitude.toStringAsFixed(5)}, '
                'Lng: ${pos.longitude.toStringAsFixed(5)}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    });

    if (_controller.isCompleted) {
      _controller.future.then((controller) {
        controller.animateCamera(
          CameraUpdate.newLatLng(pos),
        );
      });
    }
  }

  // ---------------------------------------------------------------------------
  // [EXISTING] Map interaction handlers — unchanged
  // ---------------------------------------------------------------------------
  Future<void> _goToCurrentLocation() async {
    if (_currentPosition == null) return;
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 16.5,
      ),
    ));
  }

  void _addMarker(LatLng pos, String id, String title) {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == id);
      _markers.add(
        Marker(
          markerId: MarkerId(id),
          position: pos,
          infoWindow: InfoWindow(title: title),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            id == "current" ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed
          ),
        ),
      );
    });
  }

  void _onMapLongPress(LatLng tappedPoint) {
    _addMarker(tappedPoint, "destination", "Destination");

    if (_currentPosition != null) {
       _routeService.fetchRoute(
         LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
         tappedPoint,
       );
    }
  }

  void _clearRoute() {
    setState(() {
      _showRoute = false;
      _polylines.clear();
      _markers.removeWhere((m) => m.markerId.value == "destination");
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onLongPress: _onMapLongPress,
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.onSurface.withAlpha(isDark ? 15 : 10),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: grayColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Long press map to set destination',
                            style: TextStyle(color: grayColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_isLoadingRoute)
                    MapWidgets.buildSearchLoadingIndicator(context),
                ],
              ),
            ),
          ),

          Positioned(
            right: 16,
            bottom: _showRoute ? 200 : 120,
            child: MapWidgets.buildFloatingButton(
              context: context,
              onTap: _goToCurrentLocation,
              icon: Icons.my_location,
              tooltip: 'My Location',
            ),
          ),

          if (_robotPosition != null)
            Positioned(
              right: 16,
              bottom: _showRoute ? 260 : 180,
              child: MapWidgets.buildFloatingButton(
                context: context,
                onTap: () {
                  _controller.future.then((c) {
                    c.animateCamera(CameraUpdate.newCameraPosition(
                      CameraPosition(target: _robotPosition!, zoom: 17),
                    ));
                  });
                },
                icon: Icons.smart_toy_rounded,
                tooltip: 'Follow Robot',
              ),
            ),

          if (_robotPosition != null)
            Positioned(
              left: 16,
              bottom: _showRoute ? 200 : 120,
              child: _buildRobotPositionChip(theme, isDark),
            ),

          if (_showRoute)
             Positioned(
               bottom: 110,
               left: 16,
               right: 16,
               child: MapWidgets.buildRouteInfoCard(
                 context,
                 distance: _routeDistance,
                 duration: _routeDuration,
                 onClose: _clearRoute,
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildRobotPositionChip(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withAlpha(isDark ? 15 : 10),
            blurRadius: 8,
          ),
        ],
        border: Border.all(color: primaryColor.withAlpha(isDark ? 120 : 60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.smart_toy_rounded, color: primaryColor, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Robot GPS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
              Text(
                '${_robotPosition!.latitude.toStringAsFixed(4)}, '
                '${_robotPosition!.longitude.toStringAsFixed(4)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
