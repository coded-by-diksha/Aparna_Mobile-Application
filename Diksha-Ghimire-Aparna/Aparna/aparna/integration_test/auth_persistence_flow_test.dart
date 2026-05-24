import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aparna/data/services/google_auth_service.dart';
import 'package:aparna/data/services/session_manager_service.dart';
import 'package:aparna/domain/repositories/auth_repository.dart';
import 'package:aparna/domain/usecases/login_usecase.dart';
import 'package:aparna/domain/usecases/logout_usecase.dart';
import 'package:aparna/domain/usecases/register_usecase.dart';
import 'package:aparna/presentation/bloc/auth/auth_bloc.dart';
import 'package:aparna/presentation/bloc/auth/auth_event.dart';
import 'package:aparna/presentation/bloc/auth/auth_state.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    required bool tokenValid,
    required bool loggedIn,
  })  : _tokenValid = tokenValid,
        _loggedIn = loggedIn;

  bool _tokenValid;
  bool _loggedIn;
  bool logoutCalled = false;
  Map<String, dynamic> _profile = {
    'uid': 1,
    'username': 'test-user',
    'email': 'test@example.com',
    'role': 'user',
    'token': 'access-token',
    'refreshToken': 'refresh-token',
  };

  @override
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return {'success': true};
  }

  @override
  Future<void> ensureTokenLoaded() async {}

  @override
  Future<Map<String, dynamic>> googleSignIn({
    required String idToken,
    required String email,
    String? displayName,
  }) async {
    return {'success': false};
  }

  @override
  bool get isLoggedIn => _loggedIn;

  @override
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    return {'success': false};
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    _loggedIn = false;
    _profile = {};
  }

  @override
  Future<Map<String, dynamic>> register({
    required String email,
    required String otp,
  }) async {
    return {'success': false};
  }

  @override
  Future<Map<String, dynamic>> sendSignupOTP({
    required String email,
    required String username,
    required String phone,
    required String dateOfBirth,
    required String password,
  }) async {
    return {'success': false};
  }

  @override
  Map<String, dynamic> get userProfile => _profile;

  @override
  Future<Map<String, dynamic>> validateToken() async {
    if (_tokenValid) {
      _loggedIn = true;
      return {
        'success': true,
        'statusCode': 200,
        'user': _profile,
      };
    }

    _loggedIn = false;
    _profile = {};
    return {
      'success': false,
      'statusCode': 401,
      'message': 'Invalid or expired token',
    };
  }
}

class FakeSessionManagerService extends SessionManagerService {
  bool clearCalled = false;

  @override
  Future<void> clearSession() async {
    clearCalled = true;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Persistent auth flow integration', () {
    testWidgets('cold start with valid token emits authenticated state', (_) async {
      final authRepository = FakeAuthRepository(tokenValid: true, loggedIn: true);
      final sessionService = FakeSessionManagerService();
      final bloc = AuthBloc(
        loginUseCase: LoginUseCase(authRepository),
        registerUseCase: RegisterUseCase(authRepository),
        logoutUseCase: LogoutUseCase(authRepository),
        authRepository: authRepository,
        googleAuthService: GoogleAuthService(),
        sessionManagerService: sessionService,
      );

      bloc.add(const AuthCheckRequested());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<AuthAuthenticated>());
      expect(sessionService.clearCalled, false);

      await bloc.close();
    });

    testWidgets('cold start with expired token emits unauthenticated and clears session', (_) async {
      final authRepository = FakeAuthRepository(tokenValid: false, loggedIn: true);
      final sessionService = FakeSessionManagerService();
      final bloc = AuthBloc(
        loginUseCase: LoginUseCase(authRepository),
        registerUseCase: RegisterUseCase(authRepository),
        logoutUseCase: LogoutUseCase(authRepository),
        authRepository: authRepository,
        googleAuthService: GoogleAuthService(),
        sessionManagerService: sessionService,
      );

      bloc.add(const AuthCheckRequested());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<AuthUnauthenticated>());
      expect(sessionService.clearCalled, true);

      await bloc.close();
    });

    testWidgets('logout clears auth state', (_) async {
      final authRepository = FakeAuthRepository(tokenValid: true, loggedIn: true);
      final sessionService = FakeSessionManagerService();
      final bloc = AuthBloc(
        loginUseCase: LoginUseCase(authRepository),
        registerUseCase: RegisterUseCase(authRepository),
        logoutUseCase: LogoutUseCase(authRepository),
        authRepository: authRepository,
        googleAuthService: GoogleAuthService(),
        sessionManagerService: sessionService,
      );

      bloc.add(const LogoutRequested());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(authRepository.logoutCalled, true);
      expect(bloc.state, isA<AuthUnauthenticated>());

      await bloc.close();
    });
  });
}
