import 'package:equatable/equatable.dart';

abstract class HealthEvent extends Equatable {
  const HealthEvent();

  @override
  List<Object?> get props => [];
}

class LoadHealthCycleData extends HealthEvent {}

class LoadHealthData extends HealthEvent {
  /// User ID from profile (int or String).
  final dynamic userId;

  const LoadHealthData({required this.userId});

  @override
  List<Object?> get props => [userId];
}