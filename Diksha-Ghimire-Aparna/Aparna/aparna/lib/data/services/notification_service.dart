import 'dart:convert';
import '../../core/constant/apiConstant.dart';
import '../../core/network/auth_http_client.dart';
import '../models/notification_model.dart';
import '../../core/di/dependency_injection.dart';
import '../repositories/auth_repository_impl.dart';

class NotificationService {
  static const String baseUrl = '${ApiConstant.baseUrl}notifications';

  Future<void> registerDevice(String fcmToken) async {
    final authRepo = DependencyInjection.authRepository as AuthRepositoryImpl;
    final userId = authRepo.userProfile['uid']?.toString();

    if (userId == null) {
        print('Warning: User not logged in, cannot register device');
        return;
    }

    print('📱 Registering device for user: $userId with token: $fcmToken');

    try {
        final response = await AuthHttpClient.instance.post(
            Uri.parse('$baseUrl/device'),
            headers: {
            'Content-Type': 'application/json',
            },
            body: json.encode({
                'userId': userId,
                'fcmToken': fcmToken,
                'deviceType': 'android', // You might want to detect this dynamically
            }),
        );

        print('📱 Device registration response: ${response.statusCode} ${response.body}');
    } catch (e) {
        print('Error registering device: $e');
    }
  }

  /// Unregister device (disable push notifications for current user)
  Future<void> unregisterDevice(String userId) async {
    try {
      final response = await AuthHttpClient.instance.delete(
        Uri.parse('$baseUrl/device'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      print('📱 Device unregistration response: ${response.statusCode}');
    } catch (e) {
      print('Error unregistering device: $e');
    }
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    final authRepo = DependencyInjection.authRepository as AuthRepositoryImpl;
    final userId = authRepo.userProfile['uid']?.toString();

    if (userId == null) {
      throw Exception('User not logged in');
    }

    print('🔔 Fetching notifications for user: $userId');
    print('🔗 URL: $baseUrl?userId=$userId');

    final response = await AuthHttpClient.instance.get(
      Uri.parse('$baseUrl?userId=$userId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    
    print('📥 Response status: ${response.statusCode}');
    print('📦 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> list = data['notifications'];
      return list.map((e) => NotificationModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<int> getUnreadCount() async {
    final authRepo = DependencyInjection.authRepository as AuthRepositoryImpl;
    final userId = authRepo.userProfile['uid']?.toString();

    if (userId == null) return 0;

    try {
      final response = await AuthHttpClient.instance.get(
        Uri.parse('$baseUrl/unread-count?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      }
    } catch (e) {
      print('Error fetching unread count: $e');
    }
    return 0;
  }

  Future<void> markAsRead(int id) async {
    final authRepo = DependencyInjection.authRepository as AuthRepositoryImpl;
    final userId = authRepo.userProfile['uid']?.toString();

    if (userId == null) return;

    await AuthHttpClient.instance.put(
      Uri.parse('$baseUrl/$id/read'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({'userId': userId}),
    );
  }

  Future<void> markAllAsRead() async {
    final authRepo = DependencyInjection.authRepository as AuthRepositoryImpl;
    final userId = authRepo.userProfile['uid']?.toString();

    if (userId == null) return;

    await AuthHttpClient.instance.put(
      Uri.parse('$baseUrl/mark-all-read'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({'userId': userId}),
    );
  }
}
