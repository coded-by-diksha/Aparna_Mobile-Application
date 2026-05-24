import 'package:equatable/equatable.dart';

abstract class CycleHistoryEvent extends Equatable {
  const CycleHistoryEvent();

  @override
  List<Object> get props => [];
}

class LoadCycleHistory extends CycleHistoryEvent {}
