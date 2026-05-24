import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../data/models/health_model.dart';
import 'health_dashboard_event.dart';
import 'health_dashboard_state.dart';

class HealthDashboardBloc
    extends Bloc<HealthDashboardEvent, HealthDashboardState> {
  final _healthService = DependencyInjection.healthService;
  Timer? _syncTimer;
  DateTime? _lastLoadRequestAt;

  HealthDashboardBloc() : super(HealthDashboardNotConnected()) {
    on<ConnectDevice>(_onConnectDevice);
    on<StartScanDevices>(_onStartScanDevices);
    on<SelectDevice>(_onSelectDevice);
    on<RemoveDevice>(_onRemoveDevice);
    on<LoadHealthData>(_onLoadHealthData);
    on<SyncHealthData>(_onSyncHealthData);
  }

  @override
  Future<void> close() {
    _syncTimer?.cancel();
    return super.close();
  }


  Future<void> _onConnectDevice(
    ConnectDevice event,
    Emitter<HealthDashboardState> emit,
  ) async {
    // Start scanning for devices
    add(StartScanDevices());
  }

  Future<void> _onStartScanDevices(
    StartScanDevices event,
    Emitter<HealthDashboardState> emit,
  ) async {
    emit(HealthDashboardScanning());
    try {
      // Scan for actual Bluetooth devices
      final devices = await _healthService.scanForDevices();
      
      // If no BLE devices found, show Health Connect / app options so user can sync
      // from Fitbit, Google Fit, etc. via Health Connect (no physical device needed)
      if (devices.isEmpty) {
        final fallbackDevices = _getFallbackDevices();
        emit(HealthDashboardDeviceList(devices: fallbackDevices));
      } else {
        // Mix real BLE devices with fallback so user can still choose Health Connect
        final realDevices = devices.where((d) => d.id != 'health_connect').toList();
        final fallbacks = _getFallbackDevices();
        final combined = [...realDevices, ...fallbacks];
        emit(HealthDashboardDeviceList(devices: combined));
      }
    } catch (e) {
      // scanForDevices already handles platform errors and returns fallback devices
      // If we get here, it's a different error
      final errorMsg = e.toString();
      final isPlatformError = errorMsg.contains('Platform.') ||
          errorMsg.contains('Unsupported operation') ||
          errorMsg.contains('_operatingSystem');
      
      if (isPlatformError) {
        // Even if error occurs, try to get fallback devices
        try {
          final fallbackDevices = _getFallbackDevices();
          emit(HealthDashboardDeviceList(devices: fallbackDevices));
        } catch (_) {
          emit(HealthDashboardError('Device scanning is not available on this platform.'));
        }
      } else {
        emit(HealthDashboardError('Failed to scan for devices: ${e.toString()}'));
      }
    }
  }

  /// Single option to sync real data from Health Connect (Fitbit, Google Fit, etc.) – no physical device needed.
  List<WearableDevice> _getFallbackDevices() {
    return [
      const WearableDevice(
        id: 'health_connect',
        name: 'Health Connect (Fitbit, Google Fit, etc.)',
        type: 'Sync real data from apps connected to Health Connect',
        icon: 'fitness_center',
        isAvailable: true,
      ),
    ];
  }

  Future<void> _onSelectDevice(
    SelectDevice event,
    Emitter<HealthDashboardState> emit,
  ) async {
    emit(HealthDashboardConnecting());
    final userId = DependencyInjection.authRepository.userProfile['uid'];
    if (userId == null) {
      emit(HealthDashboardError('Please sign in to view health data.'));
      return;
    }
    HealthModel? data;
    try {
      // Try to pair with Bluetooth device if it's a real device
      bool paired = false;
      if (event.device.id != 'health_connect') {
        paired = await _healthService.pairDevice(event.device.id);
        if (!paired) {
          debugPrint('Pairing failed, but continuing with device registration');
        }
      }
      
      // Request health permissions
      final granted = await _healthService.requestAuthorization();
      if (!granted && !paired) {
        emit(HealthDashboardError('Permission denied or not available'));
        return;
      }
      
      // Fetch or create health data with device info
      data = await _healthService.fetchHealthData(userId);
      data = await _healthService.syncCurrentLocation(userId, currentData: data) ?? data;
      final uid = userId is int ? userId : 0;
      
      // Sync real data from Health Connect (Fitbit, etc.) – pass device so backend shows "Connected"
      HealthModel? syncedData;
      try {
        syncedData = await _healthService.syncHealthDataFromDevice(
          userId,
          deviceName: event.device.name,
          deviceType: event.device.type,
          deviceToken: event.device.id,
        );
      } catch (e) {
        debugPrint('Initial sync failed: $e');
      }

      if (data == null) {
        data = syncedData ?? HealthModel(
          userId: uid,
          heartRate: 0,
          activityIntensity: '',
          healthDataHistory: HealthDataHistory.empty,
          activityRecognition: '',
          location: data?.location ?? '',
          deviceName: event.device.name,
          deviceType: event.device.type,
          deviceToken: event.device.id,
          lastUpdated: DateTime.now(),
        );
        await _healthService.recordHealthData(data);
      } else {
        final updatedData = syncedData ?? HealthModel(
          userId: data.userId,
          heartRate: data.heartRate,
          activityIntensity: data.activityIntensity,
          healthDataHistory: data.healthDataHistory,
          activityRecognition: data.activityRecognition,
          location: data.location,
          deviceName: event.device.name,
          deviceType: event.device.type,
          deviceToken: event.device.id,
          lastUpdated: DateTime.now(),
        );
        await _healthService.updateHealthData(userId, updatedData);
        data = updatedData;
      }
      
      emit(HealthDashboardConnected(healthData: data));
      
      // Start hourly sync timer
      _startPeriodicSync();
    } catch (e) {
      final msg = e.toString();
      final isUnsupportedPlatform = e is UnsupportedError ||
          msg.contains('Platform.') ||
          msg.contains('Unsupported operation');
      if (isUnsupportedPlatform) {
        // Web/desktop: skip native health APIs, just save device info
        try {
          final uid = userId is int ? userId : 0;
          final deviceData = HealthModel(
            userId: uid,
            heartRate: 0,
            activityIntensity: '',
            healthDataHistory: HealthDataHistory.empty,
            activityRecognition: '',
            location: data?.location ?? '',
            deviceName: event.device.name,
            deviceType: event.device.type,
            deviceToken: event.device.id,
            lastUpdated: DateTime.now(),
          );
          await _healthService.recordHealthData(deviceData);
          emit(HealthDashboardConnected(healthData: deviceData));
          _startPeriodicSync();
        } catch (_) {
          final uid = userId is int ? userId : 0;
          emit(HealthDashboardConnected(
            healthData: HealthModel(
              userId: uid,
              heartRate: 0,
              activityIntensity: '',
              healthDataHistory: HealthDataHistory.empty,
              activityRecognition: '',
              location: data?.location ?? '',
              deviceName: event.device.name,
              deviceType: event.device.type,
              deviceToken: event.device.id,
              lastUpdated: DateTime.now(),
            ),
          ));
          _startPeriodicSync();
        }
      } else {
        emit(HealthDashboardError(msg));
      }
    }
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      add(SyncHealthData());
    });
  }

  /// Sync health data from connected device.
  Future<void> _onSyncHealthData(
    SyncHealthData event,
    Emitter<HealthDashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HealthDashboardConnected) {
      return; // Only sync if device is connected
    }
    
    final userId = DependencyInjection.authRepository.userProfile['uid'];
    if (userId == null) return;
    
    try {
      final d = currentState.healthData;
      final syncedData = await _healthService.syncHealthDataFromDevice(
        userId,
        deviceName: d.deviceName,
        deviceType: d.deviceType,
        deviceToken: d.deviceToken,
      );
      if (syncedData != null) {
        emit(HealthDashboardConnected(healthData: syncedData));
      }
    } catch (e) {
      debugPrint('Error during hourly sync: $e');
      // Don't emit error state, just log it
    }
  }

  Future<void> _onRemoveDevice(
    RemoveDevice event,
    Emitter<HealthDashboardState> emit,
  ) async {
    final userId = DependencyInjection.authRepository.userProfile['uid'];
    if (userId == null) {
      emit(HealthDashboardError('Please sign in to remove device.'));
      return;
    }
    try {
      // Stop sync timer
      _syncTimer?.cancel();
      _syncTimer = null;
      
      // Clear device info from backend by updating with empty device fields
      final currentData = await _healthService.fetchHealthData(userId);
      if (currentData != null) {
        final clearedData = HealthModel(
          userId: currentData.userId,
          heartRate: currentData.heartRate,
          activityIntensity: currentData.activityIntensity,
          healthDataHistory: currentData.healthDataHistory,
          activityRecognition: currentData.activityRecognition,
          location: currentData.location,
          deviceName: '',
          deviceType: '',
          deviceToken: '',
          lastUpdated: currentData.lastUpdated,
        );
        await _healthService.updateHealthData(userId, clearedData);
      }
      emit(HealthDashboardNotConnected());
    } catch (e) {
      emit(HealthDashboardError('Failed to remove device: ${e.toString()}'));
    }
  }

  Future<void> _onLoadHealthData(
    LoadHealthData event,
    Emitter<HealthDashboardState> emit,
  ) async {
    final now = DateTime.now();
    if (_lastLoadRequestAt != null && now.difference(_lastLoadRequestAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastLoadRequestAt = now;

    final userId = DependencyInjection.authRepository.userProfile['uid'];
    if (userId == null) return;
    try {
      var data = await _healthService.fetchHealthData(userId);
      data = await _healthService.syncCurrentLocation(userId, currentData: data) ?? data;
      if (data != null && data.deviceName.isNotEmpty) {
        final synced = await _healthService.syncHealthDataFromDevice(
          userId,
          deviceName: data.deviceName,
          deviceType: data.deviceType,
          deviceToken: data.deviceToken,
        );
        if (synced != null) data = synced;

        emit(HealthDashboardConnected(healthData: data));
        _startPeriodicSync();
        return;
      }
    } catch (_) {}
    final current = state;
    if (current is HealthDashboardConnected) {
      emit(HealthDashboardConnected(healthData: current.healthData));
      _startPeriodicSync();
    }
  }
}
