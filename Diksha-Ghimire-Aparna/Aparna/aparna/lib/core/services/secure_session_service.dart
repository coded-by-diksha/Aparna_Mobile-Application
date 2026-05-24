import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStatus {
  final bool isValid;
  final bool isExpired;
  final String? token;
  final String? refreshToken;
  final String? role;
  final String? userName;
  final int? userId;

  const SessionStatus({
    required this.isValid,
    required this.isExpired,
    this.token,
    this.refreshToken,
    this.role,
    this.userName,
    this.userId,
  });
}

/// Handles secure persistence of session and JWT expiry checks.
class SecureSessionService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _roleKey = 'user_role';
  static const String _userNameKey = 'user_name';
  static const String _userIdKey = 'user_id';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _savedAtKey = 'session_saved_at_ms';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> saveSession({
    required String token,
    String? refreshToken,
    required String role,
    required String userName,
    int? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    print('[SecureSessionService] Saving session for userName=$userName role=$role');

    await _secureStorage.write(key: _tokenKey, value: token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    }

    await prefs.setString(_roleKey, role);
    await prefs.setString(_userNameKey, userName);
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setInt(_savedAtKey, DateTime.now().millisecondsSinceEpoch);
    if (userId != null) {
      await prefs.setInt(_userIdKey, userId);
    } else {
      await prefs.remove(_userIdKey);
    }

    print('[SecureSessionService] Session saved successfully');
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    print('[SecureSessionService] Clearing session from secure storage and preferences');

    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);

    await prefs.remove(_roleKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_savedAtKey);

    print('[SecureSessionService] Session cleared successfully');
  }

  Future<String?> getToken() => _secureStorage.read(key: _tokenKey);

  Future<String?> getRefreshToken() => _secureStorage.read(key: _refreshTokenKey);

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<bool> isAuthenticated() async {
    final status = await getSessionStatus();
    return status.isValid;
  }

  Future<SessionStatus> getSessionStatus() async {
    print('[SecureSessionService] Running splash session status check');
    final token = await getToken();
    if (token == null || token.isEmpty) {
      print('[SecureSessionService] No token found in secure storage');
      return const SessionStatus(isValid: false, isExpired: false);
    }

    final prefs = await SharedPreferences.getInstance();

    final isExpired = _isTokenExpired(token, prefs: prefs);
    if (isExpired) {
      print('[SecureSessionService] Token found but expired/invalid for session use');
      return SessionStatus(
        isValid: false,
        isExpired: true,
        token: token,
        refreshToken: await getRefreshToken(),
        role: prefs.getString(_roleKey),
        userName: prefs.getString(_userNameKey),
        userId: prefs.getInt(_userIdKey),
      );
    }

    print('[SecureSessionService] Session is valid');

    return SessionStatus(
      isValid: true,
      isExpired: false,
      token: token,
      refreshToken: await getRefreshToken(),
      role: prefs.getString(_roleKey),
      userName: prefs.getString(_userNameKey),
      userId: prefs.getInt(_userIdKey),
    );
  }

  bool _isTokenExpired(String token, {required SharedPreferences prefs}) {
    final jwtExp = _extractJwtExpiry(token);
    if (jwtExp != null) {
      return DateTime.now().isAfter(jwtExp);
    }

    // Fallback for non-JWT flows: rely on login flag and saved time.
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    if (!isLoggedIn) {
      return true;
    }

    final savedAtMs = prefs.getInt(_savedAtKey);
    if (savedAtMs == null) {
      return false;
    }

    final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtMs);
    return DateTime.now().difference(savedAt) > const Duration(days: 30);
  }

  DateTime? _extractJwtExpiry(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }

    try {
      final normalized = base64Url.normalize(parts[1]);
      final payloadJson = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(payloadJson);

      if (payloadMap is! Map<String, dynamic>) {
        return null;
      }

      final expSeconds = payloadMap['exp'];
      if (expSeconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000, isUtc: true)
            .toLocal();
      }
      if (expSeconds is String) {
        final parsed = int.tryParse(expSeconds);
        if (parsed != null) {
          return DateTime.fromMillisecondsSinceEpoch(parsed * 1000, isUtc: true)
              .toLocal();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
