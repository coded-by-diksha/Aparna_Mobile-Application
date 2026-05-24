import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/change_password_usecase.dart';
import 'change_password_event.dart';
import 'change_password_state.dart';

class ChangePasswordBloc
    extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  final ChangePasswordUseCase changePasswordUseCase;

  ChangePasswordBloc({required this.changePasswordUseCase})
      : super(ChangePasswordInitial()) {
    on<ChangePasswordSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    ChangePasswordSubmitted event,
    Emitter<ChangePasswordState> emit,
  ) async {
    emit(ChangePasswordLoading());
    try {
      final result = await changePasswordUseCase(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );

      if (result['success'] == true) {
        emit(ChangePasswordSuccess(
          message: result['message'] ?? 'Password changed successfully',
        ));
      } else {
        emit(ChangePasswordFailure(
          message: result['message'] ?? 'Failed to change password',
        ));
      }
    } catch (e) {
      emit(ChangePasswordFailure(message: e.toString()));
    }
  }
}
