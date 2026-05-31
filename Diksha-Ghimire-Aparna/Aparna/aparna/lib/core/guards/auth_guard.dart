import 'package:flutter/material.dart';
import '../../presentation/screens/login.dart';
import '../../presentation/screens/main_navigation_screen.dart';
import '../../presentation/screens/admin/admin_dashboard.dart';
import '../services/secure_session_service.dart';

/// AuthGuard widget that checks authentication status and user role
/// Redirects to appropriate screen based on login status and role
class AuthGuard extends StatefulWidget {
  final Widget? child;

  const AuthGuard({Key? key, this.child}) : super(key: key);

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _userRole;
  String? _userName;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isAuthenticated = await AuthService.isAuthenticated();
      final role = await AuthService.getUserRole();
      final userName = await AuthService.getUserName();

      setState(() {
        _isAuthenticated = isAuthenticated;
        _userRole = role;
        _userName = userName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If not authenticated, show login page
    if (!_isAuthenticated) {
      return const LoginPage();
    }

    // If authenticated as admin, show admin dashboard
    if (_userRole == 'admin') {
      return AdminDashboard(
        userName: _userName,
        userProfile: _userProfile,
      );
    }

    // If authenticated as regular user, show main navigation
    return MainNavigationScreen(userName: _userName);
  }
}

/// Helper class to manage authentication state
class AuthService {
  static final SecureSessionService _sessionService = SecureSessionService();

  /// Save user session after successful login
  static Future<void> saveSession({
    required String token,
    String? refreshToken,
    required String role,
    required String userName,
    int? userId,
  }) async {
    await _sessionService.saveSession(
      token: token,
      refreshToken: refreshToken,
      role: role,
      userName: userName,
      userId: userId,
    );
  }

  /// Clear user session on logout
  static Future<void> clearSession() async {
    await _sessionService.clearSession();
  }

  static Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final role = await getUserRole() ?? 'user';
    final userName = await getUserName() ?? '';
    final userId = await getUserId();

    await _sessionService.saveSession(
      token: accessToken,
      refreshToken: refreshToken,
      role: role,
      userName: userName,
      userId: userId,
    );
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return _sessionService.isAuthenticated();
  }

  /// Get user role
  static Future<String?> getUserRole() async {
    return _sessionService.getUserRole();
  }

  /// Check if user is admin
  static Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'admin';
  }

  /// Get stored token
  static Future<String?> getToken() async {
    return _sessionService.getToken();
  }

  static Future<String?> getRefreshToken() async {
    return _sessionService.getRefreshToken();
  }

  /// Get stored user name
  static Future<String?> getUserName() async {
    return _sessionService.getUserName();
  }

  /// Get stored user ID
  static Future<int?> getUserId() async {
    return _sessionService.getUserId();
  }
}
