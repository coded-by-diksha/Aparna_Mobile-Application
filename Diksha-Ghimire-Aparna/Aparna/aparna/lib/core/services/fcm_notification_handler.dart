import 'package:aparna/presentation/screens/blog_details_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../data/services/blog_service.dart';

/// Handler for FCM notification actions
/// Call this to handle notification taps and navigate to appropriate screens
class FCMNotificationHandler {
  static final BlogService _blogService = BlogService();

  /// Handle notification tap when app is in foreground, background, or terminated
  static void handleNotification(RemoteMessage message, BuildContext context) {
    final data = message.data;
    final type = data['type'];

    print('Handling notification of type: $type');

    switch (type) {
      case 'new_blog':
        _handleNewBlog(data, context);
        break;
      case 'new_story':
        _handleNewStory(data, context);
        break;
      case 'period_reminder':
        _handlePeriodReminder(data, context);
        break;
      case 'ovulation_reminder':
        _handleOvulationReminder(data, context);
        break;
      case 'health_tip':
        _handleHealthTip(data, context);
        break;
      case 'symptom_reminder':
        _handleSymptomReminder(data, context);
        break;
      case 'new_clinic':
        handleNewClinicNotification(data, context);
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  static void handleNewClinicNotification(Map<String, dynamic> data, BuildContext context) {
    final clinicId = data['clinicId'];
    final clinicName = data['clinicName'];

    print('Opening clinic: $clinicName (ID: $clinicId)');

  }

  /// Handle new blog notification - navigate to blog details
  static Future<void> _handleNewBlog(Map<String, dynamic> data, BuildContext context) async {
    final blogId = data['blogId'];
    final title = data['title'];

    print('Opening blog: $title (ID: $blogId)');

    //  Navigate to blog details screen
    final blog = await _blogService.fetchBlogById(int.parse(blogId));
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BlogDetailsScreen(blog: blog)),
    );
  }

  /// Handle new story notification - navigate to stories screen
  static void _handleNewStory(Map<String, dynamic> data, BuildContext context) {
    final storyId = data['storyId'];
    final title = data['title'];

    print('Opening story: $title (ID: $storyId)');

  }

  /// Handle period reminder - navigate to cycle tracker
  static void _handlePeriodReminder(Map<String, dynamic> data, BuildContext context) {
    final daysUntil = data['daysUntil'];

    print('Period reminder: $daysUntil days until period');

  }

  /// Handle ovulation reminder - navigate to fertility tracker
  static void _handleOvulationReminder(Map<String, dynamic> data, BuildContext context) {
    print('Ovulation reminder received');

  }

  /// Handle health tip - show dialog or navigate to tips screen
  static void _handleHealthTip(Map<String, dynamic> data, BuildContext context) {
    print('Health tip received');

  }

  /// Handle symptom reminder - navigate to symptom tracker
  static void _handleSymptomReminder(Map<String, dynamic> data, BuildContext context) {
    print('Symptom tracking reminder received');

  }

  /// Setup notification listeners
  /// Call this in your main app initialization
  static void setupNotificationListeners(BuildContext context) {
    // Handle notification when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground notification received');
      
      if (message.notification != null) {
        // Show in-app notification or snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification!.body ?? 'New notification'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                handleNotification(message, context);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Background notification tapped');
      handleNotification(message, context);
    });

    // Handle notification tap when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('Terminated notification tapped');
        handleNotification(message, context);
      }
    });
  }
}
