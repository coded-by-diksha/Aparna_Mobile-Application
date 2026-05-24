import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../di/dependency_injection.dart';
import '../../data/services/notification_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'period_tracker_notifications',
    'Aparna Notifications',
    description: 'Push notifications for blogs, reminders and updates',
    importance: Importance.high,
    
    playSound: true,
  );

  /// Initialize Firebase Messaging and request permissions
  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
    // Request permission for iOS
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Get the FCM token
    final token = await getToken();
    
    if (token != null) {
      print('FCM Token: $token');
      await saveToken(token);
      
      // Attempt device registration if user is logged in
      try {
         if (DependencyInjection.authRepository.isLoggedIn) {
             print('User is logged in, registering device...');
             await NotificationService().registerDevice(token);
         }
      } catch (e) {
         print('Error auto-registering device: $e');
      }
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      saveToken(newToken);
    });
  }

  /// Get the current FCM token
  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Save the FCM token to SharedPreferences
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      print('FCM Token saved successfully');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Retrieve the saved FCM token from SharedPreferences
  static Future<String?> getSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      print('Error retrieving saved FCM token: $e');
      return null;
    }
  }

  /// Setup foreground message handler (show a visible notification when app is open)
  static void setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      final notification = message.notification;
      final title = notification?.title ?? 'Aparna';
      final body = notification?.body ?? 'New notification';

      // Show a local notification so the user sees it when app is in foreground
      _localNotifications.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            playSound: true,
          ),
        ),
      );
    });
  }

  /// Setup background message handler (must be top-level function)
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
    print('Message data: ${message.data}');
  }
}


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseMessagingService.backgroundMessageHandler(message);
}
