import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/blog_service.dart';
import 'blog_details_screen.dart';
import 'user_stories_screen.dart';
import 'homepage.dart';
import 'aama_screen_with_bloc.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();
  final BlogService _blogService = BlogService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final list = await _notificationService.fetchNotifications();
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Show snackbar or empty state on error
        print('Error loading notifications: $e');
      }
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // 1. Mark as read immediately in UI
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id); // Fire and forget
      setState(() {
        // Ideally update list locally to show as read
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          // simple rebuild to refresh UI if we tracked isRead locally better
        }
      });
    }

    // 2. Navigation Logic
    switch (notification.type) {
      case 'new_blog':
        if (notification.data != null && notification.data!['blogId'] != null) {
          _navigateToBlog(notification.data!['blogId'].toString());
        }
        break;
      case 'new_story':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserStoriesScreen()),
        );
        break;
      case 'period_reminder':
        // Pop until we are at root or just navigate to Homepage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Homepage()),
              (route) => false,
        );
        break;
      case 'remedy_reminder':
      case 'health_tip':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AamaScreen()),
        );
        break;
      default:
        // Just stay on page or show details dialog
        break;
    }
  }

  Future<void> _navigateToBlog(String blogId) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.pink)),
    );

    try {
      final blog = await _blogService.fetchBlogById(int.parse(blogId));
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BlogDetailsScreen(blog: blog)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load blog: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final horizontalPadding = (size.width * 0.05).clamp(16.0, 32.0);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.pink),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await _notificationService.markAllAsRead();
              _loadNotifications();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: Colors.pink,
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(_notifications[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final bool isRead = notification.isRead;
    
    return Container(
      color: isRead ? Colors.white : Colors.pink.withOpacity(0.05),
      child: ListTile(
        onTap: () => _handleNotificationTap(notification),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getIconColor(notification.type).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIcon(notification.type),
            color: _getIconColor(notification.type),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'new_blog': return Icons.article;
      case 'new_story': return Icons.auto_stories;
      case 'period_reminder': return Icons.water_drop;
      case 'remedy_reminder': return Icons.healing;
      case 'health_tip': return Icons.lightbulb;
      default: return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'new_blog': return Colors.purple;
      case 'new_story': return Colors.orange;
      case 'period_reminder': return Colors.red;
      case 'remedy_reminder': return Colors.green;
      case 'health_tip': return Colors.amber;
      default: return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    // Simple mock formatting, consider using intl package properly if context allows
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}
