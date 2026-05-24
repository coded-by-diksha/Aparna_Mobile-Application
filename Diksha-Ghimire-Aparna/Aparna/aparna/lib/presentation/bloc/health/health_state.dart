import 'package:equatable/equatable.dart';
import '../../../data/models/health_model.dart';

abstract class HealthState extends Equatable {
  const HealthState();

  @override
  List<Object?> get props => [];
}

class HealthInitial extends HealthState {}

class HealthCycleLoading extends HealthState {}

class HealthCycleLoaded extends HealthState {
  final int? cycleDay;
  final int? nextPeriodDays;
  final String currentPhase;
  final int cyclesTracked;

  const HealthCycleLoaded({
    this.cycleDay,
    this.nextPeriodDays,
    this.currentPhase = '—',
    this.cyclesTracked = 0,
  });

  @override
  List<Object?> get props => [cycleDay, nextPeriodDays, currentPhase, cyclesTracked];
}

class HealthCycleError extends HealthState {
  final String message;

  const HealthCycleError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Backend health data (synced with API)
class HealthDataLoading extends HealthState {}

class HealthDataLoaded extends HealthState {
  final HealthModel? healthData;

  const HealthDataLoaded({this.healthData});

  @override
  List<Object?> get props => [healthData];
}

class HealthDataError extends HealthState {
  final String message;

  const HealthDataError(this.message);

  @override
  List<Object?> get props => [message];
}
