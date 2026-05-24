import '../entities/clinic_entity.dart';
import '../entities/location_entity.dart';
import '../entities/route_point_entity.dart';

abstract class ExpertHelpRepository {
  Future<LocationEntity> getCurrentLocation();
  Future<List<ClinicEntity>> getNearbyClinics(LocationEntity currentPosition);

  /// Fetches road route between two points (e.g. via OSRM). Returns points following streets, or null on error.
  Future<List<RoutePointEntity>?> getRouteBetweenPoints({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  });
}
