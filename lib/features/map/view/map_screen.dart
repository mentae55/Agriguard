import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/map_services.dart';
import '../widgets/map_widgets.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  late LocationService _locationService;
  late RouteService _routeService;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Position? _currentPosition;
  
  bool _isLoadingRoute = false;
  bool _showRoute = false;
  double _routeDistance = 0.0;
  double _routeDuration = 0.0;
  
  LatLng? _destination;

  // Initial dummy position (e.g., Cairo, or anywhere)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(30.0444, 31.2357),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _initServices();
  }

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
    _destination = tappedPoint;
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
      _destination = null;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  // A simulated search bar at top
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Long press map to set destination', style: TextStyle(color: Colors.grey))),
                      ],
                    ),
                  ),

                  if (_isLoadingRoute)
                    MapWidgets.buildSearchLoadingIndicator(context),
                ],
              ),
            ),
          ),

          // Floating Action Button
          Positioned(
            right: 16,
            bottom: _showRoute ? 200 : 120, // Adjust depending on if route info is showing
            child: MapWidgets.buildFloatingButton(
              context: context,
              onTap: _goToCurrentLocation,
              icon: Icons.my_location,
              tooltip: 'Current Location',
            ),
          ),

          // Route info card at the bottom
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
}
