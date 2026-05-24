import 'package:equatable/equatable.dart';

abstract class CycleHistoryState extends Equatable {
  const CycleHistoryState();

  @override
  List<Object> get props => [];
}

class CycleHistoryInitial extends CycleHistoryState {}

class CycleHistoryLoading extends CycleHistoryState {}

class CycleHistoryLoaded extends CycleHistoryState {
  final List<dynamic> history;

  const CycleHistoryLoaded(this.history);

  @override
  List<Object> get props => [history];
}

class CycleHistoryError extends CycleHistoryState {
  final String message;

  const CycleHistoryError(this.message);

  @override
  List<Object> get props => [message];
}
