import 'package:equatable/equatable.dart';

/// A point on a route ( from OSRM) with latitude and longitude.
class RoutePointEntity extends Equatable {
  final double latitude;
  final double longitude;

  const RoutePointEntity({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object> get props => [latitude, longitude];
}
