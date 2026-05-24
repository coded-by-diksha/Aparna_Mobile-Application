import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/health_model.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/services/health_service.dart';
import 'detailed_user_event.dart';
import 'detailed_user_state.dart';

class DetailedUserBloc extends Bloc<DetailedUserEvent, DetailedUserState> {
  final AdminService _adminService;
  final HealthService _healthService;

  DetailedUserBloc({
    required AdminService adminService,
    required HealthService healthService,
  })  : _adminService = adminService,
        _healthService = healthService,
        super(DetailedUserInitial()) {
    on<LoadUserDetail>(_onLoadUserDetail);
    on<DeleteUserFromDetail>(_onDeleteUser);
  }

  Future<void> _onLoadUserDetail(
    LoadUserDetail event,
    Emitter<DetailedUserState> emit,
  ) async {
    emit(DetailedUserLoading());
    try {
      final userId = event.userData['uid'] ?? event.userData['id'];
      HealthModel? healthData;

      if (userId != null) {
        try {
          healthData = await _healthService.fetchHealthData(userId);
        } catch (_) {
          // Health data is optional; proceed without it
        }
      }

      emit(DetailedUserLoaded(
        userData: event.userData,
        healthData: healthData,
      ));
    } catch (e) {
      emit(DetailedUserError(e.toString()));
    }
  }

  Future<void> _onDeleteUser(
    DeleteUserFromDetail event,
    Emitter<DetailedUserState> emit,
  ) async {
    final currentState = state;
    final userData = currentState is DetailedUserLoaded
        ? currentState.userData
        : <String, dynamic>{};
    final healthData =
        currentState is DetailedUserLoaded ? currentState.healthData : null;

    emit(DetailedUserLoading());
    try {
      final success = await _adminService.deleteUserByID(event.userId);
      if (success) {
        emit(const DetailedUserDeleted('User deleted successfully'));
      } else {
        emit(DetailedUserDeleteError(
          message: 'Failed to delete user',
          userData: userData,
          healthData: healthData,
        ));
      }
    } catch (e) {
      emit(DetailedUserDeleteError(
        message: e.toString(),
        userData: userData,
        healthData: healthData,
      ));
    }
  }
}
