import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constant/apiConstant.dart';
import '../guards/auth_guard.dart';

class AuthHttpClient {
  AuthHttpClient._();

  static final AuthHttpClient instance = AuthHttpClient._();
  final http.Client _client = http.Client();
  Future<String?>? _refreshFuture;

  Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _send('GET', uri, headers: headers, requiresAuth: requiresAuth);
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool requiresAuth = true,
  }) async {
    return _send(
      'POST',
      uri,
      headers: headers,
      body: body,
      encoding: encoding,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool requiresAuth = true,
  }) async {
    return _send(
      'PUT',
      uri,
      headers: headers,
      body: body,
      encoding: encoding,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool requiresAuth = true,
  }) async {
    return _send(
      'DELETE',
      uri,
      headers: headers,
      body: body,
      encoding: encoding,
      requiresAuth: requiresAuth,
    );
  }

// For multipart requests, we return the prepared MultipartRequest for the caller to add files/fields before sending
  Future<http.MultipartRequest> authorizedMultipartRequest(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final mergedHeaders = await _buildHeaders(
      headers: headers,
      requiresAuth: requiresAuth,
    );
    final request = http.MultipartRequest(method, uri);
    request.headers.addAll(mergedHeaders);
    return request;
  }

  Future<http.Response> _send(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    required bool requiresAuth,
  }) async {
    final initialHeaders = await _buildHeaders(
      headers: headers,
      requiresAuth: requiresAuth,
    );

    var response = await _execute(
      method,
      uri,
      headers: initialHeaders,
      body: body,
      encoding: encoding,
    );

    if (response.statusCode == 401 && requiresAuth && !_isAuthEndpoint(uri.path)) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        final retryHeaders = await _buildHeaders(
          headers: headers,
          requiresAuth: requiresAuth,
        );
        response = await _execute(
          method,
          uri,
          headers: retryHeaders,
          body: body,
          encoding: encoding,
        );
      }
    }

    return response;
  }

  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? headers,
    required bool requiresAuth,
  }) async {
    final merged = <String, String>{
      if (headers != null) ...headers,
    };
    if (requiresAuth) {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        merged['Authorization'] = 'Bearer $token';
      }
    }
    return merged;
  }

  Future<http.Response> _execute(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    if (!ApiConstant.enableLocalFallback) {
      return _executeRequest(method, uri, headers: headers, body: body, encoding: encoding)
          .timeout(ApiConstant.requestTimeout);
    }

    try {
      // Try primary URL with 30-second timeout
      final response = await _executeRequest(method, uri, headers: headers, body: body, encoding: encoding)
          .timeout(ApiConstant.requestTimeout);
      return response;
    } on TimeoutException {
      print('[AuthHttpClient] Request timeout (${ApiConstant.requestTimeout.inSeconds}s) on $uri. Falling back to localhost...');
      // Fallback to localhost if primary request times out
      final fallbackUri = _getLocalHostUri(uri);
      try {
        final fallbackResponse = await _executeRequest(method, fallbackUri, headers: headers, body: body, encoding: encoding)
            .timeout(const Duration(seconds: 15));
        print('[AuthHttpClient] Fallback request succeeded: $fallbackUri');
        return fallbackResponse;
      } on TimeoutException {
        print('[AuthHttpClient] Fallback request also timed out: $fallbackUri');
        return http.Response('{"error": "Request timeout on both primary and fallback"}', 408);
      } catch (e) {
        print('[AuthHttpClient] Fallback request error: $e');
        return http.Response('{"error": "Fallback request failed: $e"}', 500);
      }
    } catch (e) {
      print('[AuthHttpClient] Primary request error: $e');
      // If primary request fails, also try fallback
      final fallbackUri = _getLocalHostUri(uri);
      try {
        final fallbackResponse = await _executeRequest(method, fallbackUri, headers: headers, body: body, encoding: encoding)
            .timeout(const Duration(seconds: 15));
        print('[AuthHttpClient] Fallback request succeeded after error: $fallbackUri');
        return fallbackResponse;
      } catch (fallbackError) {
        print('[AuthHttpClient] Both primary and fallback failed. Primary: $e, Fallback: $fallbackError');
        throw e; // Re-throw original error
      }
    }
  }

  Future<http.Response> _executeRequest(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    switch (method) {
      case 'GET':
        return _client.get(uri, headers: headers);
      case 'POST':
        return _client.post(uri, headers: headers, body: body, encoding: encoding);
      case 'PUT':
        return _client.put(uri, headers: headers, body: body, encoding: encoding);
      case 'DELETE':
        return _client.delete(uri, headers: headers, body: body, encoding: encoding);
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }
  }

  /// Converts a remote URL to localhost fallback URL
  Uri _getLocalHostUri(Uri originalUri) {
    // Replace the host/path with local fallback host while preserving path/query.
    final path = originalUri.path;
    final query = originalUri.query;

    final localBase = ApiConstant.localBaseUrl.trim();
    final localUri = Uri.parse('$localBase${path.startsWith('/') ? path.substring(1) : path}');
    if (query.isNotEmpty) {
      return localUri.replace(query: query);
    }
    return localUri;
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/google-login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/send-signup-otp') ||
        path.contains('/auth/forgot-password') ||
        path.contains('/auth/verify-otp') ||
        path.contains('/auth/reset-password') ||
        path.contains('/auth/refresh-token');
  }

  Future<bool> _refreshAccessToken() async {
    _refreshFuture ??= _performRefresh();
    final token = await _refreshFuture;
    _refreshFuture = null;
    return token != null && token.isNotEmpty;
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await AuthService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      print('[AuthHttpClient] Refresh skipped: no refresh token');
      return null;
    }

    try {
      final response = await _client.post(
        Uri.parse('${ApiConstant.baseUrl}auth/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode != 200 || response.body.isEmpty) {
        print('[AuthHttpClient] Refresh failed with status=${response.statusCode}; preserving session until explicit logout');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final newAccessToken = data['token']?.toString() ?? '';
      final newRefreshToken = data['refreshToken']?.toString() ?? refreshToken;

      if (newAccessToken.isEmpty) {
        print('[AuthHttpClient] Refresh response missing access token; preserving session until explicit logout');
        return null;
      }

      await AuthService.updateTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      return newAccessToken;
    } catch (_) {
      print('[AuthHttpClient] Refresh failed due to network/exception; preserving session until explicit logout');
      return null;
    }
  }
}
