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

  final Set<Marker> _markers = {};   // [fixed] final — mutated in-place, never reassigned
  Set<Polyline> _polylines = {};
  Position? _currentPosition;

  bool _isLoadingRoute = false;
  bool _showRoute = false;
  double _routeDistance = 0.0;
  double _routeDuration = 0.0;
  // _destination removed — was written but never read (replaced with local var)

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
    // Delay GPS subscription until device MAC is available in DeviceProvider
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
      // Remove old robot marker, then add updated one
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
          // Green hue marker to distinguish robot from user location
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    });

    // Smooth camera follow — only animate if controller is ready
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
    // tappedPoint is used directly — no need to store in a field
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
      // destination marker removed from set above — no field to null
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // [EXISTING] Google Map — all existing params preserved
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
                  // [EXISTING] Simulated search / hint bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 12),
                        Expanded(child: Text('Long press map to set destination', style: TextStyle(color: Colors.grey))),
                      ],
                    ),
                  ),

                  if (_isLoadingRoute)
                    MapWidgets.buildSearchLoadingIndicator(context),
                ],
              ),
            ),
          ),

          // [EXISTING] Current location FAB
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

          // [NEW] "Follow Robot" FAB — animates camera to robot position
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

          // [NEW] Live robot GPS chip at bottom-left
          if (_robotPosition != null)
            Positioned(
              left: 16,
              bottom: _showRoute ? 200 : 120,
              child: _buildRobotPositionChip(),
            ),

          // [EXISTING] Route info card
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

  // ---------------------------------------------------------------------------
  // [NEW] Small chip showing live robot coordinates
  // ---------------------------------------------------------------------------
  Widget _buildRobotPositionChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        border: Border.all(color: primaryColor.withAlpha(60)),
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
              const Text('Robot GPS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black54)),
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
