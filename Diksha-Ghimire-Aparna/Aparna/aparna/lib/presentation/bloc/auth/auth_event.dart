import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;

  const LoginRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

class GoogleSignInRequested extends AuthEvent {
  final String idToken;
  final String email;
  final String? displayName;

  const GoogleSignInRequested({
    required this.idToken,
    required this.email,
    this.displayName,
  });

  @override
  List<Object?> get props => [idToken, email, displayName];
}

/// Event to start Google Sign-In flow
/// BLoC will handle full flow: initialization → authentication → token extraction
class GoogleSignInStarted extends AuthEvent {
  const GoogleSignInStarted();

  @override
  List<Object?> get props => [];
}

class SendSignupOTPRequested extends AuthEvent {
  final String email;
  final String username;
  final String phone;
  final String dateOfBirth;
  final String password;

  const SendSignupOTPRequested({
    required this.email,
    required this.username,
    required this.phone,
    required this.dateOfBirth,
    required this.password,
  });

  @override
  List<Object?> get props => [email, username, phone, dateOfBirth, password];
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String otp;

  const RegisterRequested({
    required this.email,
    required this.otp,
  });

  @override
  List<Object?> get props => [email, otp];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class ClearAuthError extends AuthEvent {
  const ClearAuthError();
}
