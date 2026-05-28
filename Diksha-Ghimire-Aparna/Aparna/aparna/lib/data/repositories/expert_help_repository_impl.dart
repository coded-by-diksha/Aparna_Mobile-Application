import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../core/constant/apiConstant.dart';
import '../../domain/entities/clinic_entity.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/route_point_entity.dart';
import '../../domain/repositories/expert_help_repository.dart';

class ExpertHelpRepositoryImpl implements ExpertHelpRepository {
  @override
  Future<LocationEntity> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LocationEntity(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  Future<List<ClinicEntity>> getNearbyClinics(LocationEntity currentPosition) async {
    try {
      final url = '${ApiConstant.baseUrl}experthelp';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          final lat = item['latitude'] != null ? double.tryParse(item['latitude'].toString()) ?? 0.0 : 0.0;
          final lon = item['longitude'] != null ? double.tryParse(item['longitude'].toString()) ?? 0.0 : 0.0;
          
          // Calculate distance
          final distanceInMeters = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            lat,
            lon,
          );
          
          String distanceStr;
          if (distanceInMeters >= 1000) {
            distanceStr = '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
          } else {
            distanceStr = '${distanceInMeters.toStringAsFixed(0)} m';
          }

          return ClinicEntity(
            id: item['exid'].toString(),
            name: item['associatename'] ?? 'Unknown Expert',
            address: item['address'] ?? 'No address provided',
            latitude: lat,
            longitude: lon,
            phone: item['contactinfo'] ?? 'N/A',
            description: item['description'] ?? '',
            distance: distanceStr,
            clinicImage: item['clinic_image'] ?? item['clinicimage'] ?? item['image_url'],
          );
        }).toList();
      } else {
        print('Error fetching live experts: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception in getNearbyClinics: $e');
      return [];
    }
  }

  @override
  Future<List<RoutePointEntity>?> getRouteBetweenPoints({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      // OSRM expects lon,lat order in URL
      final url = Uri.parse(
        '${ApiConstant.osrmRoutingBaseUrl}${fromLng},$fromLat;${toLng},$toLat'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('', 408),
      );
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;
      final geometry = (routes.first as Map<String, dynamic>)['geometry'] as Map<String, dynamic>?;
      if (geometry == null) return null;
      final coords = geometry['coordinates'] as List<dynamic>?;
      if (coords == null || coords.isEmpty) return null;
      // GeoJSON coordinates are [lng, lat]
      return coords.map((c) {
        final list = c as List<dynamic>;
        return RoutePointEntity(
          latitude: (list[1] as num).toDouble(),
          longitude: (list[0] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      print('Exception in getRouteBetweenPoints: $e');
      return null;
    }
  }
}
