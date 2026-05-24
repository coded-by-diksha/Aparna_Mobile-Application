import 'package:equatable/equatable.dart';
import '../../../data/models/health_model.dart';

/// Represents a wearable device that can be connected.
class WearableDevice {
  final String id;
  final String name;
  final String type;
  final String icon;
  final bool isAvailable;

  const WearableDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    this.isAvailable = true,
  });
}

abstract class HealthDashboardState extends Equatable {
  const HealthDashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial / not connected – show connect device UI.
class HealthDashboardNotConnected extends HealthDashboardState {}

/// Permission requested, waiting for result.
class HealthDashboardConnecting extends HealthDashboardState {}

/// Scanning for available devices.
class HealthDashboardScanning extends HealthDashboardState {}

/// Devices found, show list for user to select.
class HealthDashboardDeviceList extends HealthDashboardState {
  final List<WearableDevice> devices;

  const HealthDashboardDeviceList({required this.devices});

  @override
  List<Object?> get props => [devices];
}

/// No devices found during scan.
class HealthDashboardNoDevicesFound extends HealthDashboardState {}

/// Device connected, show dashboard with [healthData].
class HealthDashboardConnected extends HealthDashboardState {
  final HealthModel healthData;

  const HealthDashboardConnected({required this.healthData});

  @override
  List<Object?> get props => [healthData];
}

class HealthDashboardError extends HealthDashboardState {
  final String message;

  const HealthDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
