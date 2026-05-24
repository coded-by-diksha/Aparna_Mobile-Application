import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/notification_service.dart';
import '../di/dependency_injection.dart';
import 'firebase_messaging_service.dart';

/// Service to manage notification preferences and permissions.
/// Handles enabling/disabling notifications with permission requests.
class NotificationPreferenceService {
  static const String _keyNotificationsEnabled = 'notifications_enabled';

  /// Get whether notifications are enabled (user preference).
  static Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  /// Set notification preference and apply (request permission / unregister).
  static Future<bool> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);

    if (enabled) {
      return await _enableNotifications();
    } else {
      return await _disableNotifications();
    }
  }

  static Future<bool> _enableNotifications() async {
    if (kIsWeb) return true;

    try {
      // Request notification permission
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        if (!status.isGranted) {
          return false;
        }
      }

      // Request Firebase permission (iOS)
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return false;
      }

      // Get FCM token and register device
      final token = await FirebaseMessagingService.getToken();
      if (token != null && DependencyInjection.authRepository.isLoggedIn) {
        await FirebaseMessagingService.saveToken(token);
        await NotificationService().registerDevice(token);
      }
      return true;
    } catch (e) {
      debugPrint('Error enabling notifications: $e');
      return false;
    }
  }

  static Future<bool> _disableNotifications() async {
    try {
      // Delete FCM token so we stop receiving push notifications
      await FirebaseMessaging.instance.deleteToken();

      // Unregister device from backend
      if (DependencyInjection.authRepository.isLoggedIn) {
        final userId = DependencyInjection.authRepository.userProfile['uid']?.toString();
        if (userId != null) {
          await NotificationService().unregisterDevice(userId);
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error disabling notifications: $e');
      return false;
    }
  }
}
