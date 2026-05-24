import 'package:equatable/equatable.dart';
import '../../../domain/entities/period_stats_entity.dart';

abstract class PeriodStatsState extends Equatable {
  const PeriodStatsState();

  @override
  List<Object?> get props => [];
}

class PeriodStatsInitial extends PeriodStatsState {}

class PeriodStatsLoading extends PeriodStatsState {}

class PeriodStatsLoaded extends PeriodStatsState {
  final PeriodStatsEntity stats;

  const PeriodStatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

class PeriodStatsError extends PeriodStatsState {
  final String message;

  const PeriodStatsError({required this.message});

  @override
  List<Object?> get props => [message];
}
