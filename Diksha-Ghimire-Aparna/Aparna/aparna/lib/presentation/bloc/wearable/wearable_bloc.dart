import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/services/health_service.dart';
import '../../../data/models/health_model.dart';
import 'wearable_event.dart';
import 'wearable_state.dart';

class WearableBloc extends Bloc<WearableEvent, WearableState> {
  final HealthService _healthService = DependencyInjection.healthService;

  WearableBloc() : super(WearableInitial()) {
    on<LoadNearbyDevices>(_onLoadNearbyDevices);
    on<RefreshNearbyDevices>(_onRefreshNearbyDevices);
    on<ConnectToDevice>(_onConnectToDevice);
  }

  void _onLoadNearbyDevices(
    LoadNearbyDevices event,
    Emitter<WearableState> emit,
  ) {
    emit(WearableLoading());
    final devices = HealthService.getConnectableDeviceOptions();
    emit(NearbyDevicesLoaded(devices: devices));
  }

  Future<void> _onRefreshNearbyDevices(
    RefreshNearbyDevices event,
    Emitter<WearableState> emit,
  ) async {
    final current = state;
    if (current is NearbyDevicesLoaded) {
      emit(NearbyDevicesLoaded(
        devices: current.devices,
        connectingIds: current.connectingIds,
        connectedIds: current.connectedIds,
      ));
      return;
    }
    add(LoadNearbyDevices());
  }

  Future<void> _onConnectToDevice(
    ConnectToDevice event,
    Emitter<WearableState> emit,
  ) async {
    final device = event.device;
    final current = state;
    if (current is! NearbyDevicesLoaded) return;
    if (current.connectingIds.contains(device.id) ||
        current.connectedIds.contains(device.id)) return;

    emit(NearbyDevicesLoaded(
      devices: current.devices,
      connectingIds: {...current.connectingIds, device.id},
      connectedIds: current.connectedIds,
    ));

    try {
      final granted =
          await _healthService.requestAuthorizationForTypes(device.healthTypes);

      if (!granted) {
        emit(ConnectFailure(
          message: 'Permission denied or not available',
          devices: current.devices,
          connectedIds: current.connectedIds,
        ));
        return;
      }

      final newConnectedIds = {...current.connectedIds, device.id};
      var syncedToBackend = false;
      try {
        syncedToBackend = await _syncHealthDataToBackend();
      } catch (_) {}

      emit(ConnectSuccess(
        deviceName: device.name,
        devices: current.devices,
        connectedIds: newConnectedIds,
        syncedToBackend: syncedToBackend,
      ));
    } catch (e) {
      emit(ConnectFailure(
        message: e.toString(),
        devices: current.devices,
        connectedIds: current.connectedIds,
      ));
    }
  }

  Future<bool> _syncHealthDataToBackend() async {
    final authRepo =
        DependencyInjection.authRepository as AuthRepositoryImpl;
    final userId = authRepo.userProfile['uid'];
    if (userId == null) return false;

    final steps = await _healthService.getTotalStepsToday();
    final model = HealthModel(
      userId: userId is int ? userId : int.tryParse(userId.toString()) ?? 0,
      heartRate: 0,
      activityIntensity: 'moderate',
      healthDataHistory: HealthDataHistory(
        steps: steps ?? 0,
        calories: 0,
        distance: 0,
        sleepHours: 0,
        waterIntake: 0,
      ),
      activityRecognition: 'unknown',
      location: '',
      deviceName: 'Phone / Wearable',
      deviceType: 'wearable',
      deviceToken: '',
    );
    await _healthService.recordHealthData(model);
    return true;
  }
}
