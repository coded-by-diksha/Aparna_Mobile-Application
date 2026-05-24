import 'package:equatable/equatable.dart';

abstract class PeriodStatsEvent extends Equatable {
  const PeriodStatsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPeriodStats extends PeriodStatsEvent {
  final int userId;
  final String token;

  const LoadPeriodStats({required this.userId, required this.token});

  @override
  List<Object?> get props => [userId, token];
}
