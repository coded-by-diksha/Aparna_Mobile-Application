import 'package:equatable/equatable.dart';
import '../../../data/services/health_service.dart';

abstract class WearableEvent extends Equatable {
  const WearableEvent();

  @override
  List<Object?> get props => [];
}

class LoadNearbyDevices extends WearableEvent {}

class RefreshNearbyDevices extends WearableEvent {}

class ConnectToDevice extends WearableEvent {
  final ConnectableDeviceOption device;

  const ConnectToDevice({required this.device});

  @override
  List<Object?> get props => [device.id];
}
