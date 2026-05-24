import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_period_stats_usecase.dart';
import 'period_stats_event.dart';
import 'period_stats_state.dart';

class PeriodStatsBloc extends Bloc<PeriodStatsEvent, PeriodStatsState> {
  final GetPeriodStatsUseCase getPeriodStatsUseCase;

  PeriodStatsBloc({required this.getPeriodStatsUseCase}) : super(PeriodStatsInitial()) {
    on<LoadPeriodStats>(_onLoadPeriodStats);
  }

  Future<void> _onLoadPeriodStats(
    LoadPeriodStats event,
    Emitter<PeriodStatsState> emit,
  ) async {
    emit(PeriodStatsLoading());
    try {
      final stats = await getPeriodStatsUseCase(event.userId, event.token);
      emit(PeriodStatsLoaded(stats: stats));
    } catch (e) {
      emit(PeriodStatsError(message: e.toString()));
    }
  }
}
