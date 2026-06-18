// lib/data/datasources/remote/osrm_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../model/map_models.dart';

class OsrmService {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving';
  final http.Client _client;

  OsrmService({http.Client? client}) : _client = client ?? http.Client();

  Future<RouteModel> fetchRoute(LatLng origin, LatLng destination) async {
    final response = await _client.get(
      Uri.parse(
        '$_baseUrl/'
            '${origin.longitude},${origin.latitude};'
            '${destination.longitude},${destination.latitude}'
            '?overview=full&geometries=polyline',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['code'] == 'Ok') {
        final route = data['routes'][0];
        final points = _decodePolyline(route['geometry']);
        return RouteModel(
          points: points,
          distance: (route['distance'] as num).toDouble(),
          duration: (route['duration'] as num).toDouble(),
        );
      }
    }
    throw Exception('Failed to fetch route');
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}