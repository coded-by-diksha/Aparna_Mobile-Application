import 'package:aparna/data/services/health_service.dart';
import 'package:aparna/domain/entities/health.dart';
import 'package:aparna/domain/repositories/health_repository.dart';
import 'package:health/health.dart';

class HealthRepositoryImpl implements HealthRepository {
  final HealthService healthService;

  HealthRepositoryImpl(this.healthService);

  @override
  Future<List<HealthEntity>> getConnectableDeviceOptions() async {
    final options = HealthService.getConnectableDeviceOptions();
    return options
        .map(
          (o) => HealthEntity(
            id: o.id,
            name: o.name,
            description: o.description,
            icon: o.icon,
            healthTypes: o.healthTypes,
          ),
        )
        .toList();
  }

  @override
  Future<List<HealthDataPoint>> getHealthDataFromLast24Hours() async {
    return await healthService.getHealthDataFromLast24Hours();
    // TODO: implement getHealthDataFromLast24Hours
  }
  
  @override
  Future<List<HealthDataPoint>> getTotalStepsInInterval(DateTime start, DateTime end) async {
    // TODO: implement getTotalStepsInInterval
    return await healthService.getTotalStepsInInterval(start, end);
  }
  
  @override
  Future<bool> requestAuthorizationForTypes(List<HealthDataType> typeList) async {
    return await healthService.requestAuthorizationForTypes(typeList);
    // TODO: implement requestAuthorizationForTypes
  }
}
  