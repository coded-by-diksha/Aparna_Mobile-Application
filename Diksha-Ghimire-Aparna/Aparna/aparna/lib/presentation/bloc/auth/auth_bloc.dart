import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/usecases/register_usecase.dart';
import '../../../domain/usecases/logout_usecase.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../data/services/google_auth_service.dart';
import '../../../data/services/session_manager_service.dart';
import '../../../core/services/firebase_messaging_service.dart';
import '../../../data/services/notification_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final AuthRepository authRepository;
  final GoogleAuthService googleAuthService;
  final SessionManagerService sessionManagerService;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.authRepository,
    required this.googleAuthService,
    required this.sessionManagerService,
  }) : super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<GoogleSignInStarted>(_onGoogleSignInStarted);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<SendSignupOTPRequested>(_onSendSignupOTPRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<ClearAuthError>(_onClearAuthError);
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    
    try {
      final result = await loginUseCase(
        username: event.username,
        password: event.password,
      );

      if (result['statusCode'] == 401) {
        emit(AuthError(
          message: result['message'] ?? 'Invalid credentials',
          statusCode: result['statusCode'],
        ));
        return;
      }

      if (result['success'] == true) {
        // Extract user profile data
        final userProfile = authRepository.userProfile;
        final userRole = userProfile['role']?.toString().toLowerCase() ?? 'user';
        final token = userProfile['token']?.toString() ?? '';
        final refreshToken = userProfile['refreshToken']?.toString();
        final userId = userProfile['uid'] as int?;
        final sessionUserName =
            (userProfile['username']?.toString().isNotEmpty == true
                    ? userProfile['username'].toString()
                    : userProfile['email']?.toString()) ??
                event.username;

        // Save session
        print('[AUTH_BLOC] Saving session for regular login...');
        try {
          await sessionManagerService.saveSession(
            token: token,
            refreshToken: refreshToken,
            role: userRole,
            userName: sessionUserName,
            userId: userId,
          );
          print('[AUTH_BLOC] Session saved successfully');
        } catch (e) {
          print('[AUTH_BLOC] Error saving session: $e');
        }

        // Register device for push notifications
        print('[AUTH_BLOC] Registering device for push notifications...');
        try {
          String? fcmToken = await FirebaseMessagingService.getToken();
          if (fcmToken == null) fcmToken = await FirebaseMessagingService.getSavedToken();
          if (fcmToken != null) {
            await FirebaseMessagingService.saveToken(fcmToken);
            await NotificationService().registerDevice(fcmToken);
            print('[AUTH_BLOC] Device registered for push notifications');
          }
        } catch (e) {
          print('[AUTH_BLOC] Error registering device: $e');
        }

        emit(AuthAuthenticated(
          userProfile: userProfile,
          message: result['message'] ?? 'Login successful',
        ));
      } else {
        emit(AuthError(
          message: result['message'] ?? 'Login failed',
          statusCode: result['statusCode'],
        ));
      }
    } catch (e) {
      emit(AuthError(
        message: 'Network error: ${e.toString()}',
        statusCode: 500,
      ));
    }
  }

  /// Handle GoogleSignInStarted event: orchestrate full Google Sign-In flow
  Future<void> _onGoogleSignInStarted(
    GoogleSignInStarted event,
    Emitter<AuthState> emit,
  ) async {
    print('[AUTH_BLOC] GoogleSignInStarted event received - orchestrating full flow');
    emit(const GoogleSignInInProgress());

    try {
      final result = await googleAuthService.signInWithGoogle();

      if (!result.success) {
        if (result.canceled) {
          emit(AuthError(
            message: result.likelySystemInterruption
                ? '${result.errorMessage ?? 'Google sign-in was interrupted.'} Check SHA-1 in Firebase, refresh google-services.json, and verify Play Services on the device.'
                : (result.errorMessage ?? 'Google sign-in canceled by user.'),
            statusCode: null,
          ));
          return;
        }

        emit(AuthError(
          message: result.errorMessage ?? 'Google sign-in failed.',
          statusCode: null,
        ));
        return;
      }

      add(GoogleSignInRequested(
        idToken: result.idToken!,
        email: result.email!,
        displayName: result.displayName,
      ));
    } catch (e) {
      print('[AUTH_BLOC] Exception in _onGoogleSignInStarted: $e');
      emit(AuthError(
        message: 'Google sign-in failed: ${e.toString()}',
        statusCode: 500,
      ));
    }
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('[AUTH_BLOC] GoogleSignInRequested event received');
    print('[AUTH_BLOC] Email: ${event.email}, DisplayName: ${event.displayName}');
    emit(const AuthLoading());

    try {
      print('[AUTH_BLOC] Calling authRepository.googleSignIn()...');
      final result = await authRepository.googleSignIn(
        idToken: event.idToken,
        email: event.email,
        displayName: event.displayName,
      );
      print('[AUTH_BLOC] Repository returned: success=${result['success']}, statusCode=${result['statusCode']}');
      print('[AUTH_BLOC] Response message: ${result['message']}');

      if (result['success'] == true) {
        print('[AUTH_BLOC] Google sign-in successful');
        
        // Extract user profile data
        final userProfile = authRepository.userProfile;
        final userRole = userProfile['role']?.toString().toLowerCase() ?? 'user';
        final token = userProfile['token']?.toString() ?? '';
        final refreshToken = userProfile['refreshToken']?.toString();
        final userId = userProfile['uid'] as int?;
        final sessionUserName =
            (userProfile['username']?.toString().isNotEmpty == true
                    ? userProfile['username'].toString()
                    : userProfile['email']?.toString()) ??
                event.email;

        // Save session
        print('[AUTH_BLOC] Saving session...');
        try {
          await sessionManagerService.saveSession(
            token: token,
            refreshToken: refreshToken,
            role: userRole,
            userName: sessionUserName,
            userId: userId,
          );
          print('[AUTH_BLOC] Session saved successfully');
        } catch (e) {
          print('[AUTH_BLOC] Error saving session: $e');
          // Continue even if session save fails, but log it
        }

        // Register device for push notifications
        print('[AUTH_BLOC] Registering device for push notifications...');
        try {
          String? fcmToken = await FirebaseMessagingService.getToken();
          if (fcmToken == null) fcmToken = await FirebaseMessagingService.getSavedToken();
          if (fcmToken != null) {
            await FirebaseMessagingService.saveToken(fcmToken);
            await NotificationService().registerDevice(fcmToken);
            print('[AUTH_BLOC] Device registered for push notifications');
          }
        } catch (e) {
          print('[AUTH_BLOC] Error registering device: $e');
          // Continue even if notification registration fails
        }

        print('[AUTH_BLOC] Google sign-in complete, emitting AuthAuthenticated state');
        emit(AuthAuthenticated(
          userProfile: userProfile,
          message: result['message'] ?? 'Google sign-in successful',
        ));
      } else {
        print('[AUTH_BLOC] Google sign-in failed, emitting AuthError state');
        print('[AUTH_BLOC] Error message: ${result['message']}');
        emit(AuthError(
          message: result['message'] ?? 'Google sign-in failed',
          statusCode: result['statusCode'],
        ));
      }
    } catch (e) {
      print('[AUTH_BLOC] Exception in _onGoogleSignInRequested: $e');
      emit(AuthError(
        message: 'Network error: ${e.toString()}',
        statusCode: 500,
      ));
    }
  }

  Future<void> _onSendSignupOTPRequested(SendSignupOTPRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final result = await authRepository.sendSignupOTP(
        email: event.email,
        username: event.username,
        phone: event.phone,
        dateOfBirth: event.dateOfBirth,
        password: event.password,
      );
      if (result['success'] == true) {
        emit(OTPSentForSignup(message: result['message'] ?? 'Verification code sent'));
      } else {
        emit(AuthError(
          message: result['message'] ?? 'Failed to send verification code',
          statusCode: result['statusCode'],
        ));
      }
    } catch (e) {
      emit(AuthError(
        message: 'Network error: ${e.toString()}',
        statusCode: 500,
      ));
    }
  }

  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    
    try {
      final result = await registerUseCase(
        email: event.email,
        otp: event.otp,
      );

      if (result['success'] == true) {
        emit(RegistrationSuccess(
          message: result['message'] ?? 'Registration successful',
        ));
      } else {
        emit(AuthError(
          message: result['message'] ?? 'Registration failed',
          statusCode: result['statusCode'],
        ));
      }
    } catch (e) {
      emit(AuthError(
        message: 'Network error: ${e.toString()}',
        statusCode: 500,
      ));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    try {
      await logoutUseCase();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(
        message: 'Logout failed: ${e.toString()}',
        statusCode: 500,
      ));
    }
  }

  Future<void> _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    try {
      final result = await authRepository.validateToken();
      if (result['success'] == true &&
          authRepository.isLoggedIn &&
          authRepository.userProfile.isNotEmpty) {
        emit(AuthAuthenticated(
          userProfile: authRepository.userProfile,
        ));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  void _onClearAuthError(ClearAuthError event, Emitter<AuthState> emit) {
    if (authRepository.isLoggedIn) {
      emit(AuthAuthenticated(userProfile: authRepository.userProfile));
    } else {
      emit(const AuthUnauthenticated());
    }
  }
}
