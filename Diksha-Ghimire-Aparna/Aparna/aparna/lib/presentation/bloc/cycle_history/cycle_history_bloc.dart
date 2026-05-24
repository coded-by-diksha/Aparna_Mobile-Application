import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/cycle_service.dart';
import 'cycle_history_event.dart';
import 'cycle_history_state.dart';

class CycleHistoryBloc extends Bloc<CycleHistoryEvent, CycleHistoryState> {
  final CycleService _cycleService;

  CycleHistoryBloc(this._cycleService) : super(CycleHistoryInitial()) {
    on<LoadCycleHistory>((event, emit) async {
      emit(CycleHistoryLoading());
      try {
        final history = await _cycleService.fetchHistory();
        emit(CycleHistoryLoaded(history));
      } catch (e) {
        emit(CycleHistoryError(e.toString()));
      }
    });
  }
}
