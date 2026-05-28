import 'dart:convert';
import 'package:aparna/core/utils/fcm_token_helper.dart';
import 'package:aparna/core/constant/apiConstant.dart';
import 'package:aparna/core/network/auth_http_client.dart';

/// Service to sync FCM token with backend
class FCMTokenSyncService {
  static final String baseUrl = ApiConstant.baseUrl;
  
  /// for sending FCM token to backend after user login
  static Future<bool> syncTokenWithBackend(String userId, {String? authToken}) async {
    try {
      // to get the FCM token
      final fcmToken = await FCMTokenHelper.getToken();
      
      if (fcmToken == null || fcmToken.isEmpty) {
        print('FCM token not available');
        return false;
      }
      
      // Prepare headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // Add authorization header if provided
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      // Send token to backend
      final response = await AuthHttpClient.instance.post(
        Uri.parse('$baseUrl/fcm/token'),
        headers: headers,
        body: json.encode({
          'userId': userId,
          'fcmToken': fcmToken,
        }),
        requiresAuth: authToken != null && authToken.isNotEmpty,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('FCM token synced with backend: ${data['message']}');
        return true;
      } else {
        print('Failed to sync FCM token: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
      
    } catch (e) {
      print('Error syncing FCM token with backend: $e');
      return false;
    }
  }
  
  /// Delete FCM token from backend (call on logout)
  static Future<bool> deleteTokenFromBackend(String userId, {String? authToken}) async {
    try {
      // Prepare headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // Add authorization header if provided
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      // Delete token from backend
      final response = await AuthHttpClient.instance.delete(
        Uri.parse('$baseUrl/fcm/token/$userId'),
        headers: headers,
        requiresAuth: authToken != null && authToken.isNotEmpty,
      );
      
      if (response.statusCode == 200) {
        print('FCM token deleted from backend');
        return true;
      } else {
        print('Failed to delete FCM token: ${response.statusCode}');
        return false;
      }
      
    } catch (e) {
      print('Error deleting FCM token from backend: $e');
      return false;
    }
  }
}
