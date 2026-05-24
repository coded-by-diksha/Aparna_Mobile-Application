import '../entities/health.dart';
import 'package:health/health.dart';

abstract class HealthRepository {
  Future<List<HealthEntity>> getConnectableDeviceOptions();
  Future<bool> requestAuthorizationForTypes(List<HealthDataType> typeList);
  Future<List<HealthDataPoint>> getHealthDataFromLast24Hours();
  Future<List<HealthDataPoint>> getTotalStepsInInterval(DateTime start, DateTime end);
}

