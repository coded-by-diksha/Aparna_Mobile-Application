import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/notification_service.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService notificationService;

  NotificationBloc({required this.notificationService}) : super(const NotificationInitial()) {
    on<FetchUnreadCount>(_onFetchUnreadCount);
    on<NotificationMarkAsRead>(_onMarkAsRead);
    on<NotificationMarkAllAsRead>(_onMarkAllAsRead);
  }

  Future<void> _onFetchUnreadCount(FetchUnreadCount event, Emitter<NotificationState> emit) async {
    try {
      final count = await notificationService.getUnreadCount();
      emit(NotificationCountLoaded(count));
    } catch (e) {
      // Fail silently for badges usually, or show 0
      emit(const NotificationCountLoaded(0));
    }
  }

  Future<void> _onMarkAsRead(NotificationMarkAsRead event, Emitter<NotificationState> emit) async {
      if (state is NotificationCountLoaded) {
          final currentCount = (state as NotificationCountLoaded).count;
          if (currentCount > 0) {
              emit(NotificationCountLoaded(currentCount - 1));
          }
      }
      // Re-fetch to be sure
      add(FetchUnreadCount());
  }

  Future<void> _onMarkAllAsRead(NotificationMarkAllAsRead event, Emitter<NotificationState> emit) async {
      emit(const NotificationCountLoaded(0));
      // Re-fetch to be sure
      add(FetchUnreadCount());
  }
}
