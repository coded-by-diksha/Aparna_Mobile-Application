import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/cycle_service.dart';
import '../../../data/services/health_service.dart';
import 'health_event.dart';
import 'health_state.dart';

class HealthBloc extends Bloc<HealthEvent, HealthState> {
  final CycleService _cycleService;
  final HealthService _healthService;

  HealthBloc(this._cycleService, this._healthService) : super(HealthInitial()) {
    on<LoadHealthCycleData>(_onLoadHealthCycleData);
    on<LoadHealthData>(_onLoadHealthData);
  }

  Future<void> _onLoadHealthData(
    LoadHealthData event,
    Emitter<HealthState> emit,
  ) async {
    emit(HealthDataLoading());
    try {
      final healthData = await _healthService.fetchHealthData(event.userId);
      emit(HealthDataLoaded(healthData: healthData));
    } catch (e) {
      emit(HealthDataError(e.toString()));
    }
  }
  Future<void> _onLoadHealthCycleData(
    LoadHealthCycleData event,
    Emitter<HealthState> emit,
  ) async {
    emit(HealthCycleLoading());
    try {
      final history = await _cycleService.fetchHistory();
      if (history.isEmpty) {
        emit(const HealthCycleLoaded(
          cycleDay: null,
          nextPeriodDays: null,
          currentPhase: '—',
          cyclesTracked: 0,
        ));
        return;
      }

      final lastStart = DateTime.parse(history[0]['period_start_date'] as String);
      final today = DateTime.now();
      final lastStartDate = DateTime(lastStart.year, lastStart.month, lastStart.day);
      final todayDate = DateTime(today.year, today.month, today.day);
      int dayOfCycle = todayDate.difference(lastStartDate).inDays + 1;
      if (dayOfCycle <= 0) dayOfCycle = 1;
      if (dayOfCycle > 45) dayOfCycle = 45;

      int avgCycleLength = 28;
      if (history[0]['cycle_length'] != null) {
        final cl = history[0]['cycle_length'];
        avgCycleLength = cl is num ? cl.toInt() : int.tryParse(cl?.toString() ?? '28') ?? 28;
      }

      String phase = _phaseFromCycleDay(dayOfCycle, avgCycleLength);
      int? daysUntilNext;

      final prediction = await _cycleService.fetchPrediction();
      if (prediction.isNotEmpty) {
        final dates = prediction['predictedDates'] as List?;
        if (dates != null && dates.isNotEmpty) {
          final nextDateStr = dates[0]['date'] as String?;
          if (nextDateStr != null) {
            final nextDate = DateTime.parse(nextDateStr);
            final nextDateOnly = DateTime(nextDate.year, nextDate.month, nextDate.day);
            daysUntilNext = nextDateOnly.difference(todayDate).inDays;
            if (daysUntilNext < 0) daysUntilNext = 0;
          }
        }
      }

      emit(HealthCycleLoaded(
        cycleDay: dayOfCycle,
        nextPeriodDays: daysUntilNext,
        currentPhase: phase,
        cyclesTracked: history.length,
      ));
    } catch (e) {
      emit(HealthCycleError(e.toString()));
    }
  }

  String _phaseFromCycleDay(int dayOfCycle, int avgCycleLength) {
    final ovul = (avgCycleLength / 2).round();
    if (dayOfCycle <= 5) return 'Menstrual Phase';
    if (dayOfCycle <= ovul - 3) return 'Follicular Phase';
    if (dayOfCycle <= ovul + 2) return 'Ovulation Phase';
    return 'Luteal Phase';
  }
}
