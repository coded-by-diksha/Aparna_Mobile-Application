import 'package:equatable/equatable.dart';

abstract class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object?> get props => [];
}

class SendOTPEvent extends ForgotPasswordEvent {
  final String email;

  const SendOTPEvent({required this.email});

  @override
  List<Object?> get props => [email];
}

class VerifyOTPEvent extends ForgotPasswordEvent {
  final String email;
  final String otp;

  const VerifyOTPEvent({required this.email, required this.otp});

  @override
  List<Object?> get props => [email, otp];
}

class ResetPasswordEvent extends ForgotPasswordEvent {
  final String email;
  final String newPassword;

  const ResetPasswordEvent({required this.email, required this.newPassword});

  @override
  List<Object?> get props => [email, newPassword];
}

class ResendOTPEvent extends ForgotPasswordEvent {
  final String email;

  const ResendOTPEvent({required this.email});

  @override
  List<Object?> get props => [email];
}
