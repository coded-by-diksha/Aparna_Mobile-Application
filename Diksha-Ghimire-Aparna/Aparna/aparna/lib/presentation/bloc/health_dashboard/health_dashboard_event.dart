import 'package:equatable/equatable.dart';
import 'health_dashboard_state.dart';

abstract class HealthDashboardEvent extends Equatable {
  const HealthDashboardEvent();

  @override
  List<Object?> get props => [];
}

/// User taps "Connect Device" – start scanning for devices.
class ConnectDevice extends HealthDashboardEvent {}

/// Start scanning for available wearable devices.
class StartScanDevices extends HealthDashboardEvent {}

/// User selects a device to connect.
class SelectDevice extends HealthDashboardEvent {
  final WearableDevice device;

  const SelectDevice(this.device);

  @override
  List<Object?> get props => [device];
}

/// Load or refresh health data (e.g. from API; falls back to mock for demo).
class LoadHealthData extends HealthDashboardEvent {}

/// User wants to remove/disconnect the current device.
class RemoveDevice extends HealthDashboardEvent {}

/// Sync health data from connected device (triggered manually or hourly).
class SyncHealthData extends HealthDashboardEvent {}
