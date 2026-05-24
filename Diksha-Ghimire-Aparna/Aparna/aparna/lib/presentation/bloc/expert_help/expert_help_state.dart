import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import '../../../domain/entities/clinic_entity.dart';
import '../../../domain/entities/location_entity.dart';

abstract class ExpertHelpState extends Equatable {
  const ExpertHelpState();

  @override
  List<Object?> get props => [];
}

class ExpertHelpInitial extends ExpertHelpState {}

class ExpertHelpLoading extends ExpertHelpState {}

class ExpertHelpLoaded extends ExpertHelpState {
  final LocationEntity userLocation;
  final List<ClinicEntity> clinics;
  final List<ClinicEntity> filteredClinics;
  final String searchQuery;
  final double? maxDistanceKm;
  /// Clinic whose marker was tapped; route line is drawn to it.
  final ClinicEntity? selectedClinic;
  /// Street-following route points from user to selectedClinic (null until loaded or on error).
  final List<LatLng>? routePoints;

  const ExpertHelpLoaded({
    required this.userLocation,
    required this.clinics,
    this.filteredClinics = const [],
    this.searchQuery = '',
    this.maxDistanceKm,
    this.selectedClinic,
    this.routePoints,
  });

  // Copy with
  ExpertHelpLoaded copyWith({
    LocationEntity? userLocation,
    List<ClinicEntity>? clinics,
    List<ClinicEntity>? filteredClinics,
    String? searchQuery,
    double? maxDistanceKm,
    bool clearDistanceFilter = false,
    ClinicEntity? selectedClinic,
    List<LatLng>? routePoints,
    bool clearSelectedClinic = false,
  }) {
    return ExpertHelpLoaded(
      userLocation: userLocation ?? this.userLocation,
      clinics: clinics ?? this.clinics,
      filteredClinics: filteredClinics ?? this.filteredClinics,
      searchQuery: searchQuery ?? this.searchQuery,
      maxDistanceKm: clearDistanceFilter ? null : (maxDistanceKm ?? this.maxDistanceKm),
      selectedClinic: clearSelectedClinic ? null : (selectedClinic ?? this.selectedClinic),
      routePoints: clearSelectedClinic ? null : (routePoints ?? this.routePoints),
    );
  }

  @override
  List<Object?> get props => [userLocation, clinics, filteredClinics, searchQuery, maxDistanceKm, selectedClinic, routePoints];
}

// Expert help error
  class ExpertHelpError extends ExpertHelpState {
  final String message;

  const ExpertHelpError(this.message);

  @override
  List<Object> get props => [message];
}
