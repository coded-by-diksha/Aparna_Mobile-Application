import 'package:flutter_bloc/flutter_bloc.dart';
import 'period_tracking_event.dart';
import 'period_tracking_state.dart';

class PeriodTrackingBloc extends Bloc<PeriodTrackingEvent, PeriodTrackingState> {
  PeriodTrackingBloc() : super(const PeriodTrackingState()) {
    on<TogglePeriodSwitch>(_onTogglePeriodSwitch);
    on<UpdatePeriodDuration>(_onUpdatePeriodDuration);
    on<SetPeriodStartDate>(_onSetPeriodStartDate);
    on<UpdatePeriodDays>(_onUpdatePeriodDays);
    on<CalendarDateTapped>(_onCalendarDateTapped);
    on<UpdateFlowLevel>(_onUpdateFlowLevel);
    on<UpdateSymptoms>(_onUpdateSymptoms);
    on<UpdateMood>(_onUpdateMood);
    on<UpdateWeight>(_onUpdateWeight);
    on<ResetPeriodTracking>(_onResetPeriodTracking);
  }

  void _onTogglePeriodSwitch(TogglePeriodSwitch event, Emitter<PeriodTrackingState> emit) {
    emit(state.copyWith(periodSwitchValue: event.isOn));
    
    // If period is being turned on and we have a start date, update period days
    if (event.isOn && state.periodStartDate != null) {
      final newPeriodDays = state.getPeriodDays(state.periodStartDate!);
      emit(state.copyWith(periodDays: newPeriodDays));
    }
    // If period is being turned off, clear period days
    else if (!event.isOn) {
      emit(state.copyWith(periodDays: <DateTime>{}));
    }
  }

  void _onUpdatePeriodDuration(UpdatePeriodDuration event, Emitter<PeriodTrackingState> emit) {
    emit(state.copyWith(periodDurationDays: event.days));
    
    // If we have a start date, update the period days with new duration
    if (state.periodStartDate != null) {
      final newPeriodDays = state.getPeriodDays(state.periodStartDate!);
      emit(state.copyWith(periodDays: newPeriodDays));
    }
  }

  void _onSetPeriodStartDate(SetPeriodStartDate event, Emitter<PeriodTrackingState> emit) {
    final normalizedDate = DateTime(event.date.year, event.date.month, event.date.day);
    emit(state.copyWith(periodStartDate: normalizedDate));
    
    // If period switch is on, update period days
    if (state.periodSwitchValue) {
      final newPeriodDays = state.getPeriodDays(normalizedDate);
      emit(state.copyWith(periodDays: newPeriodDays));
    }
  }

  void _onUpdatePeriodDays(UpdatePeriodDays event, Emitter<PeriodTrackingState> emit) {
    emit(state.copyWith(periodDays: event.periodDays));
  }

  void _onCalendarDateTapped(CalendarDateTapped event, Emitter<PeriodTrackingState> emit) {
    // Check if it's a future date
    DateTime today = DateTime.now();
    DateTime normalizedToday = DateTime(today.year, today.month, today.day);
    DateTime normalizedSelectedDay = DateTime(event.selectedDay.year, event.selectedDay.month, event.selectedDay.day);
    
    if (normalizedSelectedDay.isAfter(normalizedToday)) {
      emit(state.copyWith(errorMessage: 'Cannot select future dates'));
      return;
    }

    // Clear any previous error
    emit(state.copyWith(errorMessage: null));
    
    // Handle period day selection logic
    if (state.periodDays.contains(normalizedSelectedDay)) {
      // If it's already a period day, show edit options
      // This will be handled in the UI layer
    } else {
      // If it's not a period day, allow starting period
      // This will also be handled in the UI layer
    }
  }

  void _onUpdateFlowLevel(UpdateFlowLevel event, Emitter<PeriodTrackingState> emit) {
    final normalizedDate = DateTime(event.date.year, event.date.month, event.date.day);
    final newFlowLevels = Map<DateTime, String>.from(state.flowLevels);
    newFlowLevels[normalizedDate] = event.flowLevel;
    emit(state.copyWith(flowLevels: newFlowLevels));
  }

  void _onUpdateSymptoms(UpdateSymptoms event, Emitter<PeriodTrackingState> emit) {
    final normalizedDate = DateTime(event.date.year, event.date.month, event.date.day);
    final newSymptoms = Map<DateTime, List<String>>.from(state.symptoms);
    newSymptoms[normalizedDate] = event.symptoms;
    emit(state.copyWith(symptoms: newSymptoms));
  }

  void _onUpdateMood(UpdateMood event, Emitter<PeriodTrackingState> emit) {
    final normalizedDate = DateTime(event.date.year, event.date.month, event.date.day);
    final newMoods = Map<DateTime, String>.from(state.moods);
    newMoods[normalizedDate] = event.mood;
    emit(state.copyWith(moods: newMoods));
  }

  void _onUpdateWeight(UpdateWeight event, Emitter<PeriodTrackingState> emit) {
    final normalizedDate = DateTime(event.date.year, event.date.month, event.date.day);
    final newWeights = Map<DateTime, double>.from(state.weights);
    newWeights[normalizedDate] = event.weight;
    emit(state.copyWith(weights: newWeights));
  }

  void _onResetPeriodTracking(ResetPeriodTracking event, Emitter<PeriodTrackingState> emit) {
    emit(const PeriodTrackingState());
  }
}
