import '../../core/services/secure_session_service.dart';

/// Service to manage user session after authentication
/// Handles token, role, username, and user ID persistence
class SessionManagerService {
  final SecureSessionService _secureSessionService;

  SessionManagerService({SecureSessionService? secureSessionService})
      : _secureSessionService = secureSessionService ?? SecureSessionService();

  /// Save user session after successful authentication
  /// Called after login/registration/Google Sign-In
  Future<void> saveSession({
    required String token,
    String? refreshToken,
    required String role,
    required String userName,
    int? userId,
  }) async {
    try {
      print('[SessionManagerService] Saving session - role: $role, username: $userName');

      await _secureSessionService.saveSession(
        token: token,
        refreshToken: refreshToken,
        role: role,
        userName: userName,
        userId: userId,
      );
      
      print('[SessionManagerService] Session saved successfully');
    } catch (e) {
      print('[SessionManagerService] Error saving session: $e');
      rethrow;
    }
  }

  /// Retrieve saved session
  /// Returns null if no session exists
  Future<Map<String, dynamic>?> getSession() async {
    try {
      final token = await _secureSessionService.getToken();
      if (token == null) return null;
      final refreshToken = await _secureSessionService.getRefreshToken();

      final role = await _secureSessionService.getUserRole();
      final userName = await _secureSessionService.getUserName();
      final userId = await _secureSessionService.getUserId();

      return {
        'token': token,
        'refreshToken': refreshToken,
        'role': role,
        'userName': userName,
        'userId': userId,
      };
    } catch (e) {
      print('[SessionManagerService] Error retrieving session: $e');
      return null;
    }
  }

  /// Clear user session (logout)
  Future<void> clearSession() async {
    try {
      await _secureSessionService.clearSession();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if session is valid
  Future<bool> isSessionValid() async {
    try {
      return _secureSessionService.isAuthenticated();
    } catch (e) {
      return false;
    }
  }

  /// Returns detailed status for Splash routing decisions.
  Future<SessionStatus> getSessionStatus() {
    return _secureSessionService.getSessionStatus();
  }
}
