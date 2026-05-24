import 'package:aparna/core/services/firebase_messaging_service.dart';

/// Utility class to access FCM token for backend integration
class FCMTokenHelper {
  /// Get the current FCM token
  /// This is the token your Node.js backend will use to send notifications
  static Future<String?> getToken() async {
    // First try to get from saved preferences
    String? savedToken = await FirebaseMessagingService.getSavedToken();
    
    if (savedToken != null && savedToken.isNotEmpty) {
      return savedToken;
    }
    
    // If not saved, get fresh token
    return await FirebaseMessagingService.getToken();
  }
  
  /// Print the FCM token to console (useful for testing)
  static Future<void> printToken() async {
    final token = await getToken();
    if (token != null) {
      print('═══════════════════════════════════════════════════════');
      print('FCM TOKEN FOR BACKEND:');
      print('token:  $token');
      print('═══════════════════════════════════════════════════════');
      print('Save this token to send notifications from your Node.js backend');
    } else {
      print('Failed to get FCM token');
    }
  }
}
