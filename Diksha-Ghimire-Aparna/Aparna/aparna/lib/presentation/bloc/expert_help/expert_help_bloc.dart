import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'expert_help_event.dart';
import 'expert_help_state.dart';
import '../../../domain/repositories/expert_help_repository.dart';
import '../../../domain/entities/clinic_entity.dart';

class ExpertHelpBloc extends Bloc<ExpertHelpEvent, ExpertHelpState> {
  final ExpertHelpRepository expertHelpRepository;

  ExpertHelpBloc({required this.expertHelpRepository}) : super(ExpertHelpInitial()) {
    on<LoadExpertHelpMap>(_onLoadExpertHelpMap);
    on<SearchClinics>(_onSearchClinics);
    on<FilterByDistance>(_onFilterByDistance);
    on<ClearFilters>(_onClearFilters);
    on<SelectClinic>(_onSelectClinic);
    on<ClearSelectedClinic>(_onClearSelectedClinic);
  }

  Future<void> _onLoadExpertHelpMap(
    LoadExpertHelpMap event,
    Emitter<ExpertHelpState> emit,
  ) async {
    emit(ExpertHelpLoading());
    try {
      final position = await expertHelpRepository.getCurrentLocation();
      final clinics = await expertHelpRepository.getNearbyClinics(position);

      emit(ExpertHelpLoaded(
        userLocation: position,
        clinics: clinics,
        filteredClinics: clinics,
      ));
    } catch (e) {
      emit(ExpertHelpError(e.toString()));
    }
  }

  void _onSearchClinics(
    SearchClinics event,
    Emitter<ExpertHelpState> emit,
  ) {
    final currentState = state;
    if (currentState is ExpertHelpLoaded) {
      final query = event.query.toLowerCase().trim();
      
      List<ClinicEntity> filtered = currentState.clinics;
      
      // Apply search query filter
      if (query.isNotEmpty) {
        filtered = filtered.where((clinic) {
          return clinic.name.toLowerCase().contains(query) ||
                 clinic.address.toLowerCase().contains(query) ||
                 clinic.description.toLowerCase().contains(query);
        }).toList();
      }
      
      // Apply distance filter if set
      if (currentState.maxDistanceKm != null) {
        filtered = _filterByDistanceValue(filtered, currentState.maxDistanceKm!);
      }
      
      emit(currentState.copyWith(
        filteredClinics: filtered,
        searchQuery: event.query,
      ));
    }
  }

  void _onFilterByDistance(
    FilterByDistance event,
    Emitter<ExpertHelpState> emit,
  ) {
    final currentState = state;
    if (currentState is ExpertHelpLoaded) {
      List<ClinicEntity> filtered = currentState.clinics;
      
      // Apply search query filter first
      if (currentState.searchQuery.isNotEmpty) {
        final query = currentState.searchQuery.toLowerCase().trim();
        filtered = filtered.where((clinic) {
          return clinic.name.toLowerCase().contains(query) ||
                 clinic.address.toLowerCase().contains(query) ||
                 clinic.description.toLowerCase().contains(query);
        }).toList();
      }
      
      // Apply distance filter
      if (event.maxDistanceKm != null) {
        filtered = _filterByDistanceValue(filtered, event.maxDistanceKm!);
      }
      
      emit(currentState.copyWith(
        filteredClinics: filtered,
        maxDistanceKm: event.maxDistanceKm,
        clearDistanceFilter: event.maxDistanceKm == null,
      ));
    }
  }

  void _onClearFilters(
    ClearFilters event,
    Emitter<ExpertHelpState> emit,
  ) {
    final currentState = state;
    if (currentState is ExpertHelpLoaded) {
      emit(currentState.copyWith(
        filteredClinics: currentState.clinics,
        searchQuery: '',
        clearDistanceFilter: true,
      ));
    }
  }

  Future<void> _onSelectClinic(
    SelectClinic event,
    Emitter<ExpertHelpState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ExpertHelpLoaded) return;

    // Emit immediately with selected clinic and no route (line will show straight until route loads)
    emit(currentState.copyWith(
      selectedClinic: event.clinic,
      routePoints: null,
      clearSelectedClinic: false,
    ));

    final routePoints = await expertHelpRepository.getRouteBetweenPoints(
      fromLat: currentState.userLocation.latitude,
      fromLng: currentState.userLocation.longitude,
      toLat: event.clinic.latitude,
      toLng: event.clinic.longitude,
    );

    final points = routePoints
        ?.map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    final latestState = state;
    if (latestState is ExpertHelpLoaded &&
        latestState.selectedClinic?.id == event.clinic.id) {
      emit(latestState.copyWith(routePoints: points, clearSelectedClinic: false));
    }
  }

  void _onClearSelectedClinic(
    ClearSelectedClinic event,
    Emitter<ExpertHelpState> emit,
  ) {
    final currentState = state;
    if (currentState is ExpertHelpLoaded) {
      emit(currentState.copyWith(clearSelectedClinic: true));
    }
  }

  List<ClinicEntity> _filterByDistanceValue(List<ClinicEntity> clinics, double maxKm) {
    return clinics.where((clinic) {
      // Parse distance string (e.g., "2.5 km" or "500 m")
      final distanceStr = clinic.distance.toLowerCase().trim();
      if (distanceStr.isEmpty) return true;
      
      try {
        if (distanceStr.contains('km')) {
          final km = double.parse(distanceStr.replaceAll('km', '').trim());
          return km <= maxKm;
        } else if (distanceStr.contains('m')) {
          final m = double.parse(distanceStr.replaceAll('m', '').trim());
          return (m / 1000) <= maxKm;
        }
      } catch (_) {
        return true;
      }
      return true;
    }).toList();
  }
}
