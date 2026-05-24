import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import 'forgot_password_event.dart';
import 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final AuthRemoteDataSource authRemoteDataSource;

  ForgotPasswordBloc({required this.authRemoteDataSource}) : super(ForgotPasswordInitial()) {
    on<SendOTPEvent>(_onSendOTP);
    on<VerifyOTPEvent>(_onVerifyOTP);
    on<ResetPasswordEvent>(_onResetPassword);
    on<ResendOTPEvent>(_onResendOTP);
  }

  Future<void> _onSendOTP(SendOTPEvent event, Emitter<ForgotPasswordState> emit) async {
    emit(ForgotPasswordLoading());
    
    try {
      final result = await authRemoteDataSource.sendPasswordResetOTP(email: event.email);
      
      if (result['success'] == true) {
        emit(OTPSentSuccess(email: event.email, message: result['message'] ?? 'OTP sent successfully'));
      } else {
        emit(ForgotPasswordError(message: result['message'] ?? 'Failed to send OTP'));
      }
    } catch (e) {
      emit(ForgotPasswordError(message: e.toString()));
    }
  }

  Future<void> _onVerifyOTP(VerifyOTPEvent event, Emitter<ForgotPasswordState> emit) async {
    emit(ForgotPasswordLoading());
    
    try {
      final result = await authRemoteDataSource.verifyOTP(
        email: event.email,
        otp: event.otp,
      );
      
      if (result['success'] == true) {
        emit(OTPVerifiedSuccess(email: event.email));
      } else {
        emit(ForgotPasswordError(message: result['message'] ?? 'Invalid OTP'));
      }
    } catch (e) {
      emit(ForgotPasswordError(message: e.toString()));
    }
  }

  Future<void> _onResetPassword(ResetPasswordEvent event, Emitter<ForgotPasswordState> emit) async {
    emit(ForgotPasswordLoading());
    
    try {
      final result = await authRemoteDataSource.resetPassword(
        email: event.email,
        newPassword: event.newPassword,
      );
      
      if (result['success'] == true) {
        emit(PasswordResetSuccess());
      } else {
        emit(ForgotPasswordError(message: result['message'] ?? 'Failed to reset password'));
      }
    } catch (e) {
      emit(ForgotPasswordError(message: e.toString()));
    }
  }

  Future<void> _onResendOTP(ResendOTPEvent event, Emitter<ForgotPasswordState> emit) async {
    emit(ForgotPasswordLoading());
    
    try {
      final result = await authRemoteDataSource.sendPasswordResetOTP(email: event.email);
      
      if (result['success'] == true) {
        emit(OTPSentSuccess(email: event.email, message: 'OTP resent successfully'));
      } else {
        emit(ForgotPasswordError(message: result['message'] ?? 'Failed to resend OTP'));
      }
    } catch (e) {
      emit(ForgotPasswordError(message: e.toString()));
    }
  }
}
