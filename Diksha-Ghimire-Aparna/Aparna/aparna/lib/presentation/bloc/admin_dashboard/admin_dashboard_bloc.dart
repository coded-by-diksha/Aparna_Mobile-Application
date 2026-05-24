import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/admin_service.dart';
import 'admin_dashboard_event.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardBloc extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final AdminService _adminService = AdminService();

  AdminDashboardBloc() : super(AdminDashboardInitial()) {
    on<LoadAdminDashboard>(_onLoadAdminDashboard);
  }

  Future<void> _onLoadAdminDashboard(
    LoadAdminDashboard event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(AdminDashboardLoading());
    try {
      final statsFuture = _adminService.fetchStats();
      final usersFuture = _adminService.fetchUsers();
      final blogsFuture = _adminService.fetchBlogs();
      final expertsFuture = _adminService.fetchExperts();

      final results = await Future.wait([
        statsFuture,
        usersFuture,
        blogsFuture,
        expertsFuture,
      ]);

      final stats = results[0] as Map<String, dynamic>;
      final users = results[1] as List<Map<String, dynamic>>;
      final blogs = results[2] as List<Map<String, dynamic>>;
      final experts = results[3] as List<Map<String, dynamic>>;

      final weeklyCounts = _computeWeeklyCounts(users, blogs, experts);
      final recentActivities = _computeRecentActivities(users, blogs, experts);

      emit(AdminDashboardLoaded(
        stats: stats.isNotEmpty ? stats : _defaultStats(),
        weeklyCounts: weeklyCounts,
        recentActivities: recentActivities,
      ));
    } catch (e) {
      emit(AdminDashboardError(e.toString()));
    }
  }

  Map<String, dynamic> _defaultStats() {
    return {
      'userCount': 0,
      'blogCount': 0,
      'clinicCount': 0,
      'activeToday': 0,
    };
  }

  /// Last 7 days (index 0 = 6 days ago, index 6 = today). Count = users + blogs + experts created that day.
  List<int> _computeWeeklyCounts(
    List<Map<String, dynamic>> users,
    List<Map<String, dynamic>> blogs,
    List<Map<String, dynamic>> experts,
  ) {
    final now = DateTime.now();
    final counts = List<int>.filled(7, 0);
    final today = DateTime(now.year, now.month, now.day);

    void addToCount(DateTime? dt) {
      if (dt == null) return;
      final d = DateTime(dt.year, dt.month, dt.day);
      final diff = today.difference(d).inDays;
      if (diff >= 0 && diff < 7) counts[6 - diff]++;
    }

    for (final u in users) addToCount(_parseDate(u['createdat']));
    for (final b in blogs) addToCount(_parseDate(b['createdat']));
    for (final e in experts) addToCount(_parseDate(e['createdat']));

    return counts;
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final dt = DateTime.tryParse(s);
    if (dt != null) return dt;
    final ms = int.tryParse(s);
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    return null;
  }

  List<RecentActivityItem> _computeRecentActivities(
    List<Map<String, dynamic>> users,
    List<Map<String, dynamic>> blogs,
    List<Map<String, dynamic>> experts,
  ) {
    final list = <_DatedItem>[];

    for (final u in users) {
      final dt = _parseDate(u['createdat']);
      if (dt != null) {
        list.add(_DatedItem(
          type: 'user',
          title: 'New user registered',
          createdAt: dt,
          raw: u,
        ));
      }
    }
    for (final b in blogs) {
      final dt = _parseDate(b['createdat']);
      if (dt != null) {
        final title = b['title']?.toString() ?? 'Blog post published';
        list.add(_DatedItem(
          type: 'blog',
          title: title.length > 40 ? '${title.substring(0, 40)}...' : title,
          createdAt: dt,
          raw: b,
        ));
      }
    }
    for (final e in experts) {
      final dt = _parseDate(e['createdat']);
      if (dt != null) {
        final name = e['associatename']?.toString() ?? 'Clinic';
        list.add(_DatedItem(
          type: 'expert',
          title: name.length > 40 ? '${name.substring(0, 40)}...' : name,
          createdAt: dt,
          raw: e,
        ));
      }
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final top = list.take(10).toList();
    final now = DateTime.now();

    return top
        .map((e) => RecentActivityItem(
              type: e.type,
              title: e.type == 'user'
                  ? 'New user registered'
                  : e.type == 'blog'
                      ? (e.raw['title']?.toString() ?? 'Blog post published')
                      : (e.raw['associatename']?.toString() ?? 'New clinic added'),
              timeAgo: _timeAgo(e.createdAt, now),
              createdAt: e.createdAt,
            ))
        .toList();
  }

  String _timeAgo(DateTime then, DateTime now) {
    final diff = now.difference(then);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    return '${then.day}/${then.month}/${then.year}';
  }
}

class _DatedItem {
  final String type;
  final String title;
  final DateTime createdAt;
  final Map<String, dynamic> raw;

  _DatedItem({
    required this.type,
    required this.title,
    required this.createdAt,
    required this.raw,
  });
}
