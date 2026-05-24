import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../main.dart';
import '../../../core/constant/apiConstant.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../core/guards/auth_guard.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../bloc/profile/profile_state.dart';
import '../../widgets/admin_floating_nav_bar.dart';
import 'admin_users_screen.dart';
import 'admin_blogs_screen.dart';
import 'admin_clinics_screen.dart';
import 'admin_profile_screen.dart';
import 'package:aparna/l10n/app_localizations.dart';
import '../../bloc/admin_dashboard/admin_dashboard_bloc.dart';
import '../../bloc/admin_dashboard/admin_dashboard_event.dart';
import '../../bloc/admin_dashboard/admin_dashboard_state.dart';
import '../../bloc/notification/notification_bloc.dart';
import '../../bloc/notification/notification_event.dart';
import '../../bloc/notification/notification_state.dart';
import '../notification_page.dart';

class AdminDashboard extends StatefulWidget {
  final String? userName;
  final Map<String, dynamic>? userProfile;

  const AdminDashboard({
    Key? key,
    this.userName,
    this.userProfile,
  }) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  /// Profile photo URL loaded from profile API (so header shows image even when login didn't return it).
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    context.read<NotificationBloc>().add(FetchUnreadCount());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadProfile();
    });
  }

  /// Load profile into ProfileBloc (same as admin_profile_screen) so header can use bloc state.
  void _loadProfile() {
    final authRepo = DependencyInjection.authRepository as AuthRepositoryImpl;
    final token = authRepo.getToken();
    final userId = authRepo.userProfile['uid'];
    if (userId != null && token.isNotEmpty) {
      context.read<ProfileBloc>().add(
            LoadUserProfile(userId: userId is int ? userId : int.tryParse(userId.toString()) ?? 0, token: token),
          );
    }
  }

  Future<void> _loadProfileImage() async {
    // First use photo from login if present
    final fromLogin = _getProfileImageUrlFromMap(widget.userProfile);
    if (fromLogin != null && fromLogin.isNotEmpty) {
      if (mounted) setState(() => _profileImageUrl = fromLogin);
      return;
    }
    // Otherwise fetch profile from API (fallback when ProfileBloc not yet loaded)
    final userId = await AuthService.getUserId();
    final token = await AuthService.getToken();
    if (userId == null || token == null || token.isEmpty) return;
    try {
      final user = await DependencyInjection.getUserProfileUseCase(userId, token);
      final photo = user.profilephoto;
      if (photo != null && photo.trim().isNotEmpty && mounted) {
        setState(() => _profileImageUrl = _profilePhotoToFullUrl(photo));
      }
    } catch (e) {
      debugPrint('AdminDashboard: could not load profile image: $e');
    }
  }

  /// Same URL building as admin_profile_screen.
  static String _profilePhotoToFullUrl(String profilephoto) {
    final normalized = profilephoto.replaceAll(r'\', '/').trim();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }

    final path = normalized.replaceFirst(RegExp(r'^/+'), '');
    final base = ApiConstant.baseUrl.endsWith('/') ? ApiConstant.baseUrl : '${ApiConstant.baseUrl}/';
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminDashboardBloc>(
      create: (_) => DependencyInjection.createAdminDashboardBloc()..add(LoadAdminDashboard()),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Stack(
          children: [
            _buildBody(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AdminFloatingNavBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  if (index == 0) _loadProfile();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardHome();
      case 1:
        return const AdminBlogsScreen();
      case 2:
        return const AdminClinicsScreen();
      case 3:
        return const AdminUsersScreen();
      case 4:
        return AdminProfileScreen(
          userName: widget.userName,
          userProfile: widget.userProfile,
        );
      default:
        return _buildDashboardHome();
    }
  }

  Widget _buildDashboardHome() {
    return SafeArea(
      child: BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AdminDashboardBloc>().add(LoadAdminDashboard());
            },
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: (MediaQuery.of(context).size.width * 0.05).clamp(16.0, 32.0), vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  if (state is AdminDashboardLoading || state is AdminDashboardInitial) ...[
                    _buildDashboardSkeleton(),
                  ] else if (state is AdminDashboardError) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        AppLocalizations.of(context)!.dashboardError,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.read<AdminDashboardBloc>().add(LoadAdminDashboard()),
                      child: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ] else if (state is AdminDashboardLoaded) ...[
                    _buildStatsGrid(
                      stats: state.stats,
                      isLoading: false,
                    ),
                    const SizedBox(height: 24),
                    _buildWeeklyActivityChart(state.weeklyCounts),
                    const SizedBox(height: 24),
                    _buildRecentActivity(state.recentActivities),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String? _getProfileImageUrlFromMap(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    final photo = profile['profilephoto'] ?? profile['profile_photo'] as String?;
    if (photo == null || photo.toString().trim().isEmpty) return null;
    return _profilePhotoToFullUrl(photo.toString());
  }

  /// Resolved profile image URL: from ProfileBloc user, then _profileImageUrl, then widget.userProfile.
  String? _getProfileImageUrl(ProfileState? profileState) {
    final user = profileState is ProfileLoaded
        ? (profileState).user
        : profileState is ProfileUpdated
            ? (profileState).user
            : null;
    if (user?.profilephoto != null && user!.profilephoto!.isNotEmpty) {
      return _profilePhotoToFullUrl(user.profilephoto!);
    }
    return _profileImageUrl ?? _getProfileImageUrlFromMap(widget.userProfile);
  }

  /// Display name: from ProfileBloc user, then widget.userName.
  String _getDisplayName(ProfileState? profileState) {
    final user = profileState is ProfileLoaded
        ? (profileState).user
        : profileState is ProfileUpdated
            ? (profileState).user
            : null;
    final l10n = AppLocalizations.of(context)!;
    return user?.username ?? widget.userName ?? l10n.admin;
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (prev, curr) =>
          curr is ProfileLoaded || curr is ProfileUpdated || curr is ProfileInitial || curr is ProfileLoading,
      builder: (context, profileState) {
        final profileImageUrl = _getProfileImageUrl(profileState);
        final displayName = _getDisplayName(profileState);
        return Row(
          children: [
            // User profile image in ellipse (oval) shape (same source as admin_profile_screen)
            Container(
              width: 45,
              height: 52,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: profileImageUrl != null
                    ? Image.network(
                        profileImageUrl,
                        width: 45,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildHeaderAvatarFallback(displayName),
                      )
                    : _buildHeaderAvatarFallback(displayName),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dashboard,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${l10n.welcomeBack}, $displayName',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, notificationState) {
                final unreadCount = notificationState is NotificationCountLoaded
                    ? notificationState.count
                    : 0;

                return IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: Colors.grey.shade700,
                          size: 22,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationPage()),
                    );
                    if (!mounted) return;
                    context.read<NotificationBloc>().add(FetchUnreadCount());
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderAvatarFallback(String displayName) {
    final initial = (displayName.isNotEmpty) ? displayName.substring(0, 1).toUpperCase() : 'A';
    return Container(
      width: 45,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid({
    required Map<String, dynamic> stats,
    required bool isLoading,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.people_outline,
                title: l10n.totalUsers,
                value: isLoading ? '...' : (stats['userCount']?.toString() ?? '0'),
                subtitle: '',
                color: const Color(0xFFE91E63),
                bgColor: const Color(0xFFE91E63).withOpacity(0.1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.article_outlined,
                title: l10n.totalBlogs,
                value: isLoading ? '...' : (stats['blogCount']?.toString() ?? '0'),
                subtitle: '',
                color: const Color(0xFF4CAF50),
                bgColor: const Color(0xFF4CAF50).withOpacity(0.1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_hospital_outlined,
                title: l10n.expertClinics,
                value: isLoading ? '...' : (stats['clinicCount']?.toString() ?? '0'),
                subtitle: '',
                color: const Color(0xFF2196F3),
                bgColor: const Color(0xFF2196F3).withOpacity(0.1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.trending_up,
                title: l10n.activeToday,
                value: isLoading ? '...' : (stats['activeToday']?.toString() ?? '0'),
                subtitle: '',
                color: const Color(0xFFFF9800),
                bgColor: const Color(0xFFFF9800).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSkeleton() {
    return Column(
      children: [
        _buildSkeletonStatsGrid(),
        const SizedBox(height: 24),
        _buildSkeletonChart(),
        const SizedBox(height: 24),
        _buildSkeletonRecentActivity(),
      ],
    );
  }

  Widget _buildSkeletonStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSkeletonStatCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildSkeletonStatCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSkeletonStatCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildSkeletonStatCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonStatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonLine(width: 72, height: 10),
                const SizedBox(height: 10),
                _buildSkeletonLine(width: 52, height: 24),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildSkeletonBox(width: 40, height: 40, radius: 12),
        ],
      ),
    );
  }

  Widget _buildSkeletonChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonLine(width: 140, height: 14),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                _SkeletonBar(height: 34),
                _SkeletonBar(height: 52),
                _SkeletonBar(height: 44),
                _SkeletonBar(height: 68),
                _SkeletonBar(height: 40),
                _SkeletonBar(height: 58),
                _SkeletonBar(height: 46),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonLine(width: 120, height: 14),
          const SizedBox(height: 16),
          _buildSkeletonActivityItem(),
          const SizedBox(height: 12),
          _buildSkeletonActivityItem(),
          const SizedBox(height: 12),
          _buildSkeletonActivityItem(),
        ],
      ),
    );
  }

  Widget _buildSkeletonActivityItem() {
    return Row(
      children: [
        _buildSkeletonBox(width: 36, height: 36, radius: 10),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSkeletonLine(width: 170, height: 12),
              const SizedBox(height: 8),
              _buildSkeletonLine(width: 110, height: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLine({
    required double width,
    required double height,
  }) {
    return _buildSkeletonBox(width: width, height: height, radius: 8);
  }

  Widget _buildSkeletonBox({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF2),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildWeeklyActivityChart(List<int> weeklyCounts) {
    final l10n = AppLocalizations.of(context)!;
    final dayLabels = [l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat, l10n.sun];
    final now = DateTime.now();
    final labels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return dayLabels[d.weekday - 1];
    });
    final maxVal = weeklyCounts.isEmpty ? 0 : weeklyCounts.reduce((a, b) => a > b ? a : b);
    final maxCount = maxVal < 1 ? 1 : maxVal;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.weeklyUserActivity,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final count = i < weeklyCounts.length ? weeklyCounts[i] : 0;
                final height = maxCount > 0 ? (count / maxCount).clamp(0.0, 1.0) : 0.0;
                return _buildBarItem(labels[i], height);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarItem(String day, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 80 * height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.8),
                AppTheme.primaryColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(List<RecentActivityItem> items) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recentActivity,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.noRecentActivity,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            )
          else
            ...items.map((item) {
              final iconData = item.type == 'user'
                  ? Icons.person_add_outlined
                  : item.type == 'blog'
                      ? Icons.article_outlined
                      : Icons.local_hospital_outlined;
              final color = item.type == 'user'
                  ? const Color(0xFFE91E63)
                  : item.type == 'blog'
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF2196F3);
              final title = item.type == 'user'
                  ? l10n.newUserRegistered
                  : item.type == 'blog'
                      ? (item.title.isEmpty ? l10n.blogPostPublished : item.title)
                      : (item.title.isEmpty ? l10n.newClinicAdded : item.title);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildActivityItem(
                  icon: iconData,
                  title: title,
                  subtitle: _timeAgoLocalized(context, item.createdAt),
                  color: color,
                ),
              );
            }),
        ],
      ),
    );
  }

  String _timeAgoLocalized(BuildContext context, DateTime then) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(then);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minsAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return '${then.day}/${then.month}/${then.year}';
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final double height;

  const _SkeletonBar({required this.height});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFE9EDF2),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 18,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFE9EDF2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
