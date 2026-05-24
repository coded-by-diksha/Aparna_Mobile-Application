import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/admin_service.dart';
import 'admin_analytics_event.dart';
import 'admin_analytics_state.dart';

class AdminAnalyticsBloc extends Bloc<AdminAnalyticsEvent, AdminAnalyticsState> {
  final AdminService _adminService;

  AdminAnalyticsBloc(this._adminService) : super(AdminAnalyticsInitial()) {
    on<LoadAdminAnalytics>(_onLoadAdminAnalytics);
  }

  Future<void> _onLoadAdminAnalytics(
    LoadAdminAnalytics event,
    Emitter<AdminAnalyticsState> emit,
  ) async {
    emit(AdminAnalyticsLoading());
    try {
      final stats = await _adminService.fetchStats();
      if (stats.isEmpty) {
        emit(AdminAnalyticsLoaded(_defaultStats()));
      } else {
        emit(AdminAnalyticsLoaded(stats));
      }
    } catch (e) {
      emit(AdminAnalyticsError(e.toString()));
    }
  }

  static Map<String, dynamic> _defaultStats() {
    return {
      'userCount': 0,
      'blogCount': 0,
      'clinicCount': 0,
      'activeToday': 0,
    };
  }
}
