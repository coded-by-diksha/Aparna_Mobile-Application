import 'package:equatable/equatable.dart';
import '../../../data/services/health_service.dart';

abstract class WearableState extends Equatable {
  const WearableState();

  @override
  List<Object?> get props => [];
}

class WearableInitial extends WearableState {}

class WearableLoading extends WearableState {}

class NearbyDevicesLoaded extends WearableState {
  final List<ConnectableDeviceOption> devices;
  final Set<String> connectingIds;
  final Set<String> connectedIds;

  const NearbyDevicesLoaded({
    required this.devices,
    this.connectingIds = const {},
    this.connectedIds = const {},
  });

  @override
  List<Object?> get props => [devices, connectingIds, connectedIds];
}

class WearableLoadError extends WearableState {
  final String message;

  const WearableLoadError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Emitted after a device connects; UI keeps showing list from [devices] / [connectedIds].
class ConnectSuccess extends WearableState {
  final String deviceName;
  final bool syncedToBackend;
  final List<ConnectableDeviceOption> devices;
  final Set<String> connectedIds;

  const ConnectSuccess({
    required this.deviceName,
    required this.devices,
    required this.connectedIds,
    this.syncedToBackend = false,
  });

  @override
  List<Object?> get props => [deviceName, syncedToBackend, devices, connectedIds];
}

class ConnectFailure extends WearableState {
  final String message;
  final List<ConnectableDeviceOption> devices;
  final Set<String> connectedIds;

  const ConnectFailure({
    required this.message,
    required this.devices,
    required this.connectedIds,
  });

  @override
  List<Object?> get props => [message, devices, connectedIds];
}
