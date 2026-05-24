import 'dart:async';
import 'dart:convert';
import '../../core/constant/apiConstant.dart';
import '../../core/network/auth_http_client.dart';

class AuthRemoteDataSource {
  static const String baseUrl = ApiConstant.baseUrl;
  static const Duration _defaultRequestTimeout = Duration(seconds: 30);
  static const Duration _googleLoginTimeout = Duration(seconds: 75);

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      print('Username: $username');
      
      final response = await AuthHttpClient.instance.post(
        Uri.parse('${baseUrl}auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'identifier': username,
          'password': password,
        }),
        requiresAuth: false,
      ).timeout(const Duration(seconds: 60));
      
      print('Response status code: ${response.statusCode}');
      
      
      if (response.body.isEmpty) {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": "Empty response from server"
        };
      }
      
      final data = json.decode(response.body);
      if (response.statusCode == 404) {
        return {
          "success": false,
          "statusCode": 404,
          "message": "Google sign-in is not enabled on the server yet."
        };
      }

      if (response.statusCode == 200 && data['token'] != null) {
        return {
          "success": true,
          "statusCode": 200,
          "token": data['token'],
          "refreshToken": data['refreshToken'],
          "user": data['user'] ?? {},
          "message": data['message'] ?? "Login successful"
        };
      } else {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": data['message'] ?? 'Login failed'
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        "success": false,
        "statusCode": 500,
        "message": "Network error: ${e.toString()}"
      };
    }
  }

  Future<Map<String, dynamic>> validateToken({required String token}) async {
    try {
      final response = await AuthHttpClient.instance
          .get(
            Uri.parse('${baseUrl}auth/validate-token'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            requiresAuth: true,
          )
          .timeout(_defaultRequestTimeout);

      if (response.body.isEmpty) {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Empty response from server',
        };
      }

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['valid'] == true) {
        return {
          'success': true,
          'statusCode': 200,
          'message': data['message'] ?? 'Token is valid',
          'user': data['user'] ?? {},
        };
      }

      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': data['message'] ?? 'Invalid token',
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> googleSignIn({
    required String idToken,
    required String email,
    String? displayName,
  }) async {
    print('[AUTH_DATASOURCE] googleSignIn() called');
    print('[AUTH_DATASOURCE] URL: ${baseUrl}auth/google-login');
    print('[AUTH_DATASOURCE] Email: $email, DisplayName: $displayName');
    print('[AUTH_DATASOURCE] ID Token preview: ${idToken.substring(0, 20)}...');

    final uri = Uri.parse('${baseUrl}auth/google-login');
    final body = json.encode({
      'idToken': idToken,
      'email': email,
      'displayName': displayName,
    });

    // Retry once for timeouts because hosted backends can be cold-started.
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        print('[AUTH_DATASOURCE] googleSignIn attempt $attempt/2');
        final requestStartedAt = DateTime.now();

        final response = await AuthHttpClient.instance
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: body,
              requiresAuth: false,
            )
            .timeout(_googleLoginTimeout);

        final elapsedMs = DateTime.now().difference(requestStartedAt).inMilliseconds;
        print('[AUTH_DATASOURCE] Response status code: ${response.statusCode} (${elapsedMs}ms)');
        print('[AUTH_DATASOURCE] Response body (first 200 chars): ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

        if (response.body.isEmpty) {
          print('[AUTH_DATASOURCE] Empty response body received');
          return {
            "success": false,
            "statusCode": response.statusCode,
            "message": "Empty response from server"
          };
        }

        if (response.body.trim().startsWith('<')) {
          print('[AUTH_DATASOURCE] HTML response received (possible server error page)');
          return {
            "success": false,
            "statusCode": response.statusCode,
            "message": "Server error"
          };
        }

        final data = json.decode(response.body);
        print('[AUTH_DATASOURCE] Parsed response data: $data');
        if (response.statusCode == 200 && data['token'] != null) {
          print('[AUTH_DATASOURCE] Google sign-in successful');
          return {
            "success": true,
            "statusCode": 200,
            "token": data['token'],
            "refreshToken": data['refreshToken'],
            "user": data['user'] ?? {},
            "message": data['message'] ?? "Google sign-in successful"
          };
        }

        print('[AUTH_DATASOURCE] Authentication failed: statusCode=${response.statusCode}');
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": data['message'] ?? 'Google sign-in failed'
        };
      } on TimeoutException catch (e) {
        print('[AUTH_DATASOURCE] Timeout on attempt $attempt: $e');
        if (attempt < 2) {
          await Future<void>.delayed(const Duration(seconds: 2));
          continue;
        }
        return {
          "success": false,
          "statusCode": 504,
          "message": "Google sign-in request timed out. Server may be waking up; please retry."
        };
      } catch (e) {
        print('[AUTH_DATASOURCE] Exception caught on attempt $attempt: $e');
        return {
          "success": false,
          "statusCode": 500,
          "message": "Network error: ${e.toString()}"
        };
      }
    }

    return {
      "success": false,
      "statusCode": 500,
      "message": "Google sign-in failed due to an unexpected retry flow error"
    };
  }

  Future<Map<String, dynamic>> sendSignupOTP({
    required String email,
    required String username,
    required String phone,
    required String dateOfBirth,
    required String password,
  }) async {
    try {
      final response = await AuthHttpClient.instance.post(
        Uri.parse('${baseUrl}auth/send-signup-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'username': username,
          'phone': phone,
          'dateofbirth': dateOfBirth,
          'password': password,
        }),
        requiresAuth: false,
      ).timeout(const Duration(seconds: 60));

      if (response.body.isEmpty) {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": "Empty response from server"
        };
      }
      if (response.body.trim().startsWith('<')) {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": "Server error"
        };
      }
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "statusCode": 200,
          "message": data['message'] ?? "Verification code sent"
        };
      }
      return {
        "success": false,
        "statusCode": response.statusCode,
        "message": data['message'] ?? 'Failed to send verification code'
      };
    } catch (e) {
      return {
        "success": false,
        "statusCode": 500,
        "message": "Network error: ${e.toString()}"
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await AuthHttpClient.instance.post(
        Uri.parse('${baseUrl}auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'otp': otp,
        }),
        requiresAuth: false,
      ).timeout(const Duration(seconds: 60));
      
      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');
      
      if (response.body.isEmpty) {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": "Empty response from server"
        };
      }
      
      // Check if response is HTML (error page)
      if (response.body.trim().startsWith('<')) {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": "Server error: Invalid response format (received HTML)"
        };
      }
      
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "statusCode": response.statusCode,
          "message": data['message'] ?? "Registration successful",
          "token": data['token'],
          "refreshToken": data['refreshToken'],
          "user": data['user'] ?? {},
        };
      } else {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": data['message'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      print('Registration error: $e');
      return {
        "success": false,
        "statusCode": 500,
        "message": "Network error: ${e.toString()}"
      };
    }
  }

  Future<Map<String, dynamic>> sendPasswordResetOTP({
    required String email,
  }) async {
    try {
      print('Sending OTP to: $email');
      
      final response = await AuthHttpClient.instance.post(
        Uri.parse('${baseUrl}auth/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
        }),
        requiresAuth: false,
      ).timeout(const Duration(seconds: 60));
      
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.body.isEmpty) {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": "Empty response from server"
        };
      }
      
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "statusCode": 200,
          "message": data['message'] ?? "OTP sent successfully"
        };
      } else {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": data['message'] ?? 'Failed to send OTP'
        };
      }
    } catch (e) {
      print('Send OTP error: $e');
      return {
        "success": false,
        "statusCode": 500,
        "message": "Network error: ${e.toString()}"
      };
    }
  }

  Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      print('Verifying OTP for: $email');
      
      final response = await AuthHttpClient.instance.post(
        Uri.parse('${baseUrl}auth/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'otp': otp,
        }),
        requiresAuth: false,
      ).timeout(const Duration(seconds: 60));
      
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.body.isEmpty) {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": "Empty response from server"
        };
      }
      
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "statusCode": 200,
          "message": data['message'] ?? "OTP verified successfully"
        };
      } else {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": data['message'] ?? 'Invalid OTP'
        };
      }
    } catch (e) {
      print('Verify OTP error: $e');
      return {
        "success": false,
        "statusCode": 500,
        "message": "Network error: ${e.toString()}"
      };
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String token,
  }) async {
    try {
      final response = await AuthHttpClient.instance.post(
        Uri.parse('${baseUrl}auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
        requiresAuth: true,
      ).timeout(const Duration(seconds: 60));

      if (response.body.isEmpty) {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": "Empty response from server"
        };
      }

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "statusCode": 200,
          "message": data['message'] ?? "Password changed successfully"
        };
      } else {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": data['message'] ?? 'Failed to change password'
        };
      }
    } catch (e) {
      return {
        "success": false,
        "statusCode": 500,
        "message": "Network error: ${e.toString()}"
      };
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      print('Resetting password for: $email');
      
      final response = await AuthHttpClient.instance.post(
        Uri.parse('${baseUrl}auth/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'newPassword': newPassword,
        }),
        requiresAuth: false,
      ).timeout(const Duration(seconds: 60));
      
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.body.isEmpty) {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": "Empty response from server"
        };
      }
      
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "statusCode": 200,
          "message": data['message'] ?? "Password reset successfully"
        };
      } else {
        return {
          "success": false,
          "statusCode": response.statusCode,
          "message": data['message'] ?? 'Failed to reset password'
        };
      }
    } catch (e) {
      print('Reset password error: $e');
      return {
        "success": false,
        "statusCode": 500,
        "message": "Network error: ${e.toString()}"
      };
    }
  }
}
