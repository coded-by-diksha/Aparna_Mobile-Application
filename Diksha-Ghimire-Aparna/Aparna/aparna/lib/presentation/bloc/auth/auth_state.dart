import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State indicating Google Sign-In flow is in progress
class GoogleSignInInProgress extends AuthState {
  const GoogleSignInInProgress();
}

class AuthAuthenticated extends AuthState {
  final Map<String, dynamic> userProfile;
  final String? message;

  const AuthAuthenticated({
    required this.userProfile,
    this.message,
  });

  @override
  List<Object?> get props => [userProfile, message];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  final int? statusCode;

  const AuthError({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

class OTPSentForSignup extends AuthState {
  final String message;

  const OTPSentForSignup({required this.message});

  @override
  List<Object?> get props => [message];
}

class RegistrationSuccess extends AuthState {
  final String message;

  const RegistrationSuccess({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}
