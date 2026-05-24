import 'package:equatable/equatable.dart';

abstract class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordInitial extends ForgotPasswordState {}

class ForgotPasswordLoading extends ForgotPasswordState {}

class OTPSentSuccess extends ForgotPasswordState {
  final String email;
  final String message;

  const OTPSentSuccess({required this.email, required this.message});

  @override
  List<Object?> get props => [email, message];
}

class OTPVerifiedSuccess extends ForgotPasswordState {
  final String email;

  const OTPVerifiedSuccess({required this.email});

  @override
  List<Object?> get props => [email];
}

class PasswordResetSuccess extends ForgotPasswordState {}

class ForgotPasswordError extends ForgotPasswordState {
  final String message;

  const ForgotPasswordError({required this.message});

  @override
  List<Object?> get props => [message];
}
