import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../core/guards/auth_guard.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  
  bool _isLoggedIn = false;
  Map<String, dynamic> _userProfile = {};
  String _token = '';
  String _refreshToken = '';

  Map<String, dynamic> _normalizeUserProfile(Map<String, dynamic> raw) {
    final profile = Map<String, dynamic>.from(raw);
    if (profile['uid'] == null && profile['user_id'] != null) {
      profile['uid'] = profile['user_id'];
    }
    if (profile['uid'] == null && profile['id'] != null) {
      profile['uid'] = profile['id'];
    }
    return profile;
  }

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> ensureTokenLoaded() async {
    if (_token.isEmpty || _userProfile.isEmpty) {
      final sessionValid = await AuthService.isAuthenticated();
      if (!sessionValid) {
        _isLoggedIn = false;
        _userProfile = {};
        _token = '';
        _refreshToken = '';
        return;
      }

      _token = await AuthService.getToken() ?? '';
      _refreshToken = await AuthService.getRefreshToken() ?? '';
      final role = await AuthService.getUserRole() ?? '';
      final userName = await AuthService.getUserName() ?? '';
      final userId = await AuthService.getUserId();
      
      if (_token.isNotEmpty) {
        _isLoggedIn = true;
        _userProfile = {
          'token': _token,
          'refreshToken': _refreshToken,
          'role': role,
          'username': userName,
          'uid': userId,
        };
      }
    }
  }

  @override
  Future<Map<String, dynamic>> validateToken() async {
    await ensureTokenLoaded();
    if (_token.isEmpty) {
      return {
        'success': false,
        'statusCode': 401,
        'message': 'No token found',
      };
    }

    final result = await remoteDataSource.validateToken(token: _token);
    if (result['success'] == true) {
      final user = _normalizeUserProfile(Map<String, dynamic>.from(result['user'] ?? {}));
      user['token'] = _token;
      user['refreshToken'] = _refreshToken;
      _userProfile = user;
      _isLoggedIn = true;
      return result;
    }

    print('[AuthRepositoryImpl] validateToken failed; keeping persisted session until explicit logout');
    _isLoggedIn = false;
    _userProfile = {};
    _token = '';
    _refreshToken = '';
    return result;
  }

  @override
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final result = await remoteDataSource.login(
      username: username,
      password: password,
    );

    if (result['success'] == true) {
      _isLoggedIn = true;
      _userProfile = _normalizeUserProfile(Map<String, dynamic>.from(result['user'] ?? {}));
      _token = result['token'] ?? '';
      _refreshToken = result['refreshToken'] ?? '';
      // Inject token into profile so login screen can save it
      _userProfile['token'] = _token;
      _userProfile['refreshToken'] = _refreshToken;
    }

    return result;
  }

  @override
  Future<Map<String, dynamic>> googleSignIn({
    required String idToken,
    required String email,
    String? displayName,
  }) async {
    print('[AUTH_REPO] googleSignIn() called with email: $email, displayName: $displayName');
    final result = await remoteDataSource.googleSignIn(
      idToken: idToken,
      email: email,
      displayName: displayName,
    );
    print('[AUTH_REPO] Remote datasource returned: success=${result['success']}, statusCode=${result['statusCode']}');

    if (result['success'] == true) {
      print('[AUTH_REPO] Setting local state with authenticated user');
      _isLoggedIn = true;
      _userProfile = _normalizeUserProfile(Map<String, dynamic>.from(result['user'] ?? {}));
      _token = result['token'] ?? '';
      _refreshToken = result['refreshToken'] ?? '';
      _userProfile['token'] = _token;
      _userProfile['refreshToken'] = _refreshToken;
    }

    return result;
  }

  @override
  Future<Map<String, dynamic>> sendSignupOTP({
    required String email,
    required String username,
    required String phone,
    required String dateOfBirth,
    required String password,
  }) async {
    return await remoteDataSource.sendSignupOTP(
      email: email,
      username: username,
      phone: phone,
      dateOfBirth: dateOfBirth,
      password: password,
    );
  }

  @override
  Future<Map<String, dynamic>> register({
    required String email,
    required String otp,
  }) async {
    final result = await remoteDataSource.register(
      email: email,
      otp: otp,
    );
    if (result['success'] == true && result['token'] != null) {
      _isLoggedIn = true;
      _userProfile = _normalizeUserProfile(Map<String, dynamic>.from(result['user'] ?? {}));
      _token = result['token'] ?? '';
      _refreshToken = result['refreshToken'] ?? '';
      _userProfile['token'] = _token;
      _userProfile['refreshToken'] = _refreshToken;
    }
    return result;
  }

  @override
  Future<void> logout() async {
    _isLoggedIn = false;
    _userProfile = {};
    _token = '';
    _refreshToken = '';
    await AuthService.clearSession();
  }

  @override
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      token: _token,
    );
  }

  @override
  bool get isLoggedIn {
    // We can't easily wait for _ensureTokenLoaded here as it's a sync getter.
    // However, if _token is not empty, we are logged in.
    return _isLoggedIn || _token.isNotEmpty;
  }

  @override
  Map<String, dynamic> get userProfile => _userProfile;

  String getToken() => _token;

  int? getUserId() {
    if (_userProfile.containsKey('uid')) {
      return _userProfile['uid'] as int?;
    }
    return null;
  }
}
