import 'package:equatable/equatable.dart';

/// One entry for "Recent Activity" list (user signup, blog published, clinic added).
class RecentActivityItem extends Equatable {
  final String type; // 'user' | 'blog' | 'expert'
  final String title;
  final String timeAgo;
  final DateTime createdAt;

  const RecentActivityItem({
    required this.type,
    required this.title,
    required this.timeAgo,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [type, title, timeAgo, createdAt];
}

abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();

  @override
  List<Object?> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {}

class AdminDashboardLoading extends AdminDashboardState {}

class AdminDashboardLoaded extends AdminDashboardState {
  final Map<String, dynamic> stats;
  /// Last 7 days (oldest to newest): count of new users + blogs + experts per day.
  /// Index 0 = 6 days ago, index 6 = today.
  final List<int> weeklyCounts;
  final List<RecentActivityItem> recentActivities;

  const AdminDashboardLoaded({
    required this.stats,
    required this.weeklyCounts,
    required this.recentActivities,
  });

  int get userCount => (stats['userCount'] is int)
      ? stats['userCount'] as int
      : int.tryParse(stats['userCount']?.toString() ?? '0') ?? 0;
  int get blogCount => (stats['blogCount'] is int)
      ? stats['blogCount'] as int
      : int.tryParse(stats['blogCount']?.toString() ?? '0') ?? 0;
  int get clinicCount => (stats['clinicCount'] is int)
      ? stats['clinicCount'] as int
      : int.tryParse(stats['clinicCount']?.toString() ?? '0') ?? 0;

  @override
  List<Object?> get props => [stats, weeklyCounts, recentActivities];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;

  const AdminDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
