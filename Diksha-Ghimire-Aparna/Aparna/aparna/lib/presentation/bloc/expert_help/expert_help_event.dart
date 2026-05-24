import 'package:equatable/equatable.dart';
import '../../../domain/entities/clinic_entity.dart';

abstract class ExpertHelpEvent extends Equatable {
  const ExpertHelpEvent();

  @override
  List<Object> get props => [];
}

class LoadExpertHelpMap extends ExpertHelpEvent {}

class SearchClinics extends ExpertHelpEvent {
  final String query;

  const SearchClinics(this.query);

  @override
  List<Object> get props => [query];
}

class FilterByDistance extends ExpertHelpEvent {
  final double? maxDistanceKm;

  const FilterByDistance(this.maxDistanceKm);

  @override
  List<Object> get props => [maxDistanceKm ?? 0];
}

class ClearFilters extends ExpertHelpEvent {}

/// User tapped a clinic marker; fetch route and set selected clinic.
class SelectClinic extends ExpertHelpEvent {
  final ClinicEntity clinic;

  const SelectClinic(this.clinic);

  @override
  List<Object> get props => [clinic];
}

/// User closed the clinic detail sheet; clear selection and route.
class ClearSelectedClinic extends ExpertHelpEvent {}
