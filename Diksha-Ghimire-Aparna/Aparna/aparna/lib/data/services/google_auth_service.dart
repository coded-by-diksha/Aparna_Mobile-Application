import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthResult {
  final bool success;
  final bool canceled;
  final bool likelySystemInterruption;
  final String? idToken;
  final String? email;
  final String? displayName;
  final String? errorCode;
  final String? errorMessage;
  final String? rawDescription;

  const GoogleAuthResult({
    required this.success,
    required this.canceled,
    this.likelySystemInterruption = false,
    this.idToken,
    this.email,
    this.displayName,
    this.errorCode,
    this.errorMessage,
    this.rawDescription,
  });
}

/// Service to encapsulate Google Sign-In logic
/// Handles initialization, authentication, and error handling
class GoogleAuthService {
  static const String _defaultGoogleWebClientId =
      '124485235213-b9h9a11025htn0gsfqkmh001683qhmus.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isInitialized = false;
  bool _isAuthenticating = false;

  /// Initialize Google Sign-In with server client ID
  /// Must be called before [authenticate]
  Future<void> initialize({String? customClientId}) async {
    if (_isInitialized) return;

    final configuredClientId = customClientId ??
        const String.fromEnvironment(
          'GOOGLE_WEB_CLIENT_ID',
          defaultValue: _defaultGoogleWebClientId,
        );

    await _googleSignIn.initialize(
      serverClientId: configuredClientId.isEmpty ? null : configuredClientId,
    );
    _isInitialized = true;
    print('[GoogleAuthService] Google Sign-In initialized');
  }

  /// Check if Google Sign-In is supported on this platform
  bool isSupported() {
    return _googleSignIn.supportsAuthenticate();
  }

  /// Perform Google authentication
  /// Returns GoogleSignInAccount if successful
  /// Throws GoogleSignInException or Exception on failure
  Future<GoogleSignInAccount> authenticate() async {
    if (!_isInitialized) {
      throw Exception('GoogleAuthService not initialized. Call initialize() first.');
    }

    if (!isSupported()) {
      throw Exception('Google Sign-In is not supported on this platform');
    }

    print('[GoogleAuthService] Starting Google Sign-In authentication');
    try {
      final account = await _googleSignIn.authenticate();
      print('[GoogleAuthService] Authentication successful: ${account.email}');
      return account;
    } on GoogleSignInException catch (e) {
      print('[GoogleAuthService] GoogleSignInException: code=${e.code}, description=${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        print('[GoogleAuthService] User canceled Google Sign-In');
      }
      rethrow;
    } catch (e) {
      print('[GoogleAuthService] Unexpected error during authentication: $e');
      rethrow;
    }
  }

  /// Extract ID token from authenticated account
  Future<String> getIdToken(GoogleSignInAccount account) async {
    print('[GoogleAuthService] Extracting ID token from account');
    try {
      final auth = account.authentication;
      final idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('ID token is null or empty');
      }
      print('[GoogleAuthService] ID token extracted successfully');
      return idToken;
    } catch (e) {
      print('[GoogleAuthService] Error extracting ID token: $e');
      rethrow;
    }
  }

  /// Hardened Google sign-in flow that avoids concurrent auth calls and
  /// returns structured diagnostics for silent cancellation scenarios.
  Future<GoogleAuthResult> signInWithGoogle({String? customClientId}) async {
    if (_isAuthenticating) {
      return const GoogleAuthResult(
        success: false,
        canceled: true,
        errorCode: 'concurrent_sign_in',
        errorMessage: 'A Google sign-in request is already in progress.',
      );
    }

    _isAuthenticating = true;
    final startedAt = DateTime.now();
    try {
      await initialize(customClientId: customClientId);

      if (!isSupported()) {
        return const GoogleAuthResult(
          success: false,
          canceled: false,
          errorCode: 'unsupported_platform',
          errorMessage: 'Google Sign-In is not supported on this device/platform.',
        );
      }

      final GoogleSignInAccount account = await _googleSignIn
          .authenticate()
          .timeout(const Duration(seconds: 45));
      final GoogleSignInAuthentication auth = account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        return const GoogleAuthResult(
          success: false,
          canceled: false,
          errorCode: 'missing_id_token',
          errorMessage:
              'Google returned no ID token. Check web client ID and OAuth configuration.',
        );
      }

      return GoogleAuthResult(
        success: true,
        canceled: false,
        idToken: idToken,
        email: account.email,
        displayName: account.displayName,
      );
    } on GoogleSignInException catch (e) {
      final codeName = e.code.name;
      final raw = e.description;
      final canceled = e.code == GoogleSignInExceptionCode.canceled;

      // Canceled can be surfaced by the plugin for system interruptions
      // (activity recreation, Play Services interruption, task switches).
      final likelyInterrupted = _isLikelySystemInterruption(
        canceled: canceled,
        startedAt: startedAt,
        description: raw,
      );

      if (likelyInterrupted) {
        try {
          await Future<void>.delayed(const Duration(milliseconds: 350));
          final retryAccount = await _googleSignIn
              .authenticate()
              .timeout(const Duration(seconds: 45));
          final retryAuth = retryAccount.authentication;
          final retryToken = retryAuth.idToken;

          if (retryToken != null && retryToken.isNotEmpty) {
            return GoogleAuthResult(
              success: true,
              canceled: false,
              idToken: retryToken,
              email: retryAccount.email,
              displayName: retryAccount.displayName,
            );
          }
        } catch (_) {
          // Fall through to structured error result below.
        }
      }

      return GoogleAuthResult(
        success: false,
        canceled: canceled,
        likelySystemInterruption: likelyInterrupted,
        errorCode: codeName,
        rawDescription: raw,
        errorMessage: canceled
            ? (likelyInterrupted
                ? 'Google sign-in was interrupted by system/activity lifecycle. This is usually configuration or Play Services related, not a user cancel.'
                : 'Google sign-in was canceled by user action.')
            : 'Google sign-in failed with code: $codeName',
      );
    } on TimeoutException {
      return const GoogleAuthResult(
        success: false,
        canceled: false,
        errorCode: 'timeout',
        errorMessage: 'Google sign-in timed out before completion.',
      );
    } catch (e) {
      return GoogleAuthResult(
        success: false,
        canceled: false,
        errorCode: 'unknown',
        errorMessage: 'Unexpected Google sign-in error: $e',
      );
    } finally {
      _isAuthenticating = false;
    }
  }

  bool _isLikelySystemInterruption({
    required bool canceled,
    required DateTime startedAt,
    String? description,
  }) {
    if (!canceled) return false;

    final elapsed = DateTime.now().difference(startedAt);
    final desc = (description ?? '').toLowerCase();

    if (elapsed.inMilliseconds < 1200) {
      return true;
    }

    if (desc.contains('interrupted') ||
        desc.contains('background') ||
        desc.contains('activity') ||
        desc.contains('lifecycle')) {
      return true;
    }

    return false;
  }

  /// Full Google Sign-In flow: initialize → authenticate → get token
  /// Returns map with idToken, email, displayName
  Future<Map<String, dynamic>> performSignIn({String? customClientId}) async {
    try {
      // Initialize if not already done
      if (!_isInitialized) {
        await initialize(customClientId: customClientId);
      }

      // Authenticate
      final account = await authenticate();

      // Get ID token
      final idToken = await getIdToken(account);

      return {
        'idToken': idToken,
        'email': account.email,
        'displayName': account.displayName,
        'success': true,
      };
    } catch (e) {
      print('[GoogleAuthService] performSignIn failed: $e');
      rethrow;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      if (_isInitialized) {
        await _googleSignIn.signOut();
        print('[GoogleAuthService] Signed out from Google');
      }
    } catch (e) {
      print('[GoogleAuthService] Error during sign out: $e');
    }
  }
}
