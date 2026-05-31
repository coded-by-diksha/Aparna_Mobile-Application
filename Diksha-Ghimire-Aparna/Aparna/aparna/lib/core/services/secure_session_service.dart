import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String roleKey = 'user_role';
  static const String userNameKey = 'user_name';
  static const String userIdKey = 'user_id';
  static const String isLoggedInKey = 'is_logged_in';
  static const String savedAtKey = 'session_saved_at_ms';
  static const String languageKey = 'app_language';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String fcmTokenKey = 'fcm_token';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<void> writeString(String key, String? value) async {
    if (value == null) {
      await _secureStorage.delete(key: key);
      return;
    }
    await _secureStorage.write(key: key, value: value);
  }

  static Future<String?> readString(String key) => _secureStorage.read(key: key);

  static Future<void> writeBool(String key, bool? value) async {
    if (value == null) {
      await _secureStorage.delete(key: key);
      return;
    }
    await _secureStorage.write(key: key, value: value.toString());
  }

  static Future<bool?> readBool(String key) async {
    final value = await _secureStorage.read(key: key);
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  static Future<void> writeInt(String key, int? value) async {
    if (value == null) {
      await _secureStorage.delete(key: key);
      return;
    }
    await _secureStorage.write(key: key, value: value.toString());
  }

  static Future<int?> readInt(String key) async {
    final value = await _secureStorage.read(key: key);
    if (value == null) return null;
    return int.tryParse(value);
  }

  static Future<void> saveLanguage(String languageCode) =>
      writeString(languageKey, languageCode);

  static Future<String?> getLanguage() => readString(languageKey);

  static Future<void> saveNotificationsEnabled(bool enabled) =>
      writeBool(notificationsEnabledKey, enabled);

  static Future<bool> getNotificationsEnabled() async =>
      (await readBool(notificationsEnabledKey)) ?? true;

  static Future<void> saveFcmToken(String token) =>
      writeString(fcmTokenKey, token);

  static Future<String?> getSavedFcmToken() => readString(fcmTokenKey);

  Future<void> saveSession({
    required String token,
    String? refreshToken,
    required String role,
    required String userName,
    int? userId,
  }) async {
    print('[SecureSessionService] Saving session for userName=$userName role=$role');

    await _secureStorage.write(key: tokenKey, value: token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secureStorage.write(key: refreshTokenKey, value: refreshToken);
    }

    await writeString(roleKey, role);
    await writeString(userNameKey, userName);
    await writeBool(isLoggedInKey, true);
    await writeInt(savedAtKey, DateTime.now().millisecondsSinceEpoch);
    await writeInt(userIdKey, userId);

    print('[SecureSessionService] Session saved successfully');
  }

  Future<void> clearSession() async {
    print('[SecureSessionService] Clearing session from secure storage');

    await _secureStorage.delete(key: tokenKey);
    await _secureStorage.delete(key: refreshTokenKey);

    await _secureStorage.delete(key: roleKey);
    await _secureStorage.delete(key: userNameKey);
    await _secureStorage.delete(key: userIdKey);
    await _secureStorage.delete(key: isLoggedInKey);
    await _secureStorage.delete(key: savedAtKey);

    print('[SecureSessionService] Session cleared successfully');
  }

  Future<String?> getToken() => _secureStorage.read(key: tokenKey);

  Future<String?> getRefreshToken() => _secureStorage.read(key: refreshTokenKey);

  Future<String?> getUserRole() => readString(roleKey);

  Future<String?> getUserName() => readString(userNameKey);

  Future<int?> getUserId() => readInt(userIdKey);

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

    final isExpired = await _isTokenExpired(token);
    if (isExpired) {
      print('[SecureSessionService] Token found but expired/invalid for session use');
      return SessionStatus(
        isValid: false,
        isExpired: true,
        token: token,
        refreshToken: await getRefreshToken(),
        role: await getUserRole(),
        userName: await getUserName(),
        userId: await getUserId(),
      );
    }

    print('[SecureSessionService] Session is valid');

    return SessionStatus(
      isValid: true,
      isExpired: false,
      token: token,
      refreshToken: await getRefreshToken(),
      role: await getUserRole(),
      userName: await getUserName(),
      userId: await getUserId(),
    );
  }

  Future<bool> _isTokenExpired(String token) async {
    final jwtExp = _extractJwtExpiry(token);
    if (jwtExp != null) {
      return DateTime.now().isAfter(jwtExp);
    }

    // Fallback for non-JWT flows: rely on login flag and saved time.
    final isLoggedIn = await readBool(isLoggedInKey) ?? false;
    if (!isLoggedIn) {
      return true;
    }

    final savedAtMs = await readInt(savedAtKey);
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
