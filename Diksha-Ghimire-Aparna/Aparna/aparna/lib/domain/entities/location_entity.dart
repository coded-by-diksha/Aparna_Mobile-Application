import 'package:equatable/equatable.dart';

/// Domain entity for a geographic location.
/// Abstracts platform-specific location types 
class LocationEntity extends Equatable {
  final double latitude;
  final double longitude;

  const LocationEntity({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}
