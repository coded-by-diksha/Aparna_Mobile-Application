import 'package:equatable/equatable.dart';

abstract class AdminAnalyticsState extends Equatable {
  const AdminAnalyticsState();

  @override
  List<Object?> get props => [];
}

class AdminAnalyticsInitial extends AdminAnalyticsState {}

class AdminAnalyticsLoading extends AdminAnalyticsState {}

class AdminAnalyticsLoaded extends AdminAnalyticsState {
  final Map<String, dynamic> stats;

  const AdminAnalyticsLoaded(this.stats);

  int get userCount => (stats['userCount'] is int)
      ? stats['userCount'] as int
      : int.tryParse(stats['userCount']?.toString() ?? '0') ?? 0;

  int get blogCount => (stats['blogCount'] is int)
      ? stats['blogCount'] as int
      : int.tryParse(stats['blogCount']?.toString() ?? '0') ?? 0;

  int get clinicCount => (stats['clinicCount'] is int)
      ? stats['clinicCount'] as int
      : int.tryParse(stats['clinicCount']?.toString() ?? '0') ?? 0;

  @override
  List<Object?> get props => [stats];
}

class AdminAnalyticsError extends AdminAnalyticsState {
  final String message;

  const AdminAnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}
