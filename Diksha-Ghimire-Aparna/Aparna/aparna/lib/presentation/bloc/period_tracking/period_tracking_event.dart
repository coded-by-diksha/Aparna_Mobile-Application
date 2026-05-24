import 'package:equatable/equatable.dart';

abstract class PeriodTrackingEvent extends Equatable {
  const PeriodTrackingEvent();

  @override
  List<Object?> get props => [];
}

class TogglePeriodSwitch extends PeriodTrackingEvent {
  final bool isOn;

  const TogglePeriodSwitch(this.isOn);

  @override
  List<Object?> get props => [isOn];
}

class UpdatePeriodDuration extends PeriodTrackingEvent {
  final int days;

  const UpdatePeriodDuration(this.days);

  @override
  List<Object?> get props => [days];
}

class SetPeriodStartDate extends PeriodTrackingEvent {
  final DateTime date;

  const SetPeriodStartDate(this.date);

  @override
  List<Object?> get props => [date];
}

class UpdatePeriodDays extends PeriodTrackingEvent {
  final Set<DateTime> periodDays;

  const UpdatePeriodDays(this.periodDays);

  @override
  List<Object?> get props => [periodDays];
}

class CalendarDateTapped extends PeriodTrackingEvent {
  final DateTime selectedDay;

  const CalendarDateTapped(this.selectedDay);

  @override
  List<Object?> get props => [selectedDay];
}

class UpdateFlowLevel extends PeriodTrackingEvent {
  final DateTime date;
  final String flowLevel;

  const UpdateFlowLevel(this.date, this.flowLevel);

  @override
  List<Object?> get props => [date, flowLevel];
}

class UpdateSymptoms extends PeriodTrackingEvent {
  final DateTime date;
  final List<String> symptoms;

  const UpdateSymptoms(this.date, this.symptoms);

  @override
  List<Object?> get props => [date, symptoms];
}

class UpdateMood extends PeriodTrackingEvent {
  final DateTime date;
  final String mood;

  const UpdateMood(this.date, this.mood);

  @override
  List<Object?> get props => [date, mood];
}

class UpdateWeight extends PeriodTrackingEvent {
  final DateTime date;
  final double weight;

  const UpdateWeight(this.date, this.weight);

  @override
  List<Object?> get props => [date, weight];
}

class ResetPeriodTracking extends PeriodTrackingEvent {
  const ResetPeriodTracking();
}
