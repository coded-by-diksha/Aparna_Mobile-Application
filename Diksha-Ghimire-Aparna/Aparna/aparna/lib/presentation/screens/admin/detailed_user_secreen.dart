import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/services/health_service.dart';
import '../../bloc/detailed_user/detailed_user_bloc.dart';
import '../../bloc/detailed_user/detailed_user_event.dart';
import '../../bloc/detailed_user/detailed_user_state.dart';
import '../../bloc/admin_users/admin_users_utils.dart';

class DetailedUserScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DetailedUserScreen({super.key, required this.userData});

  @override
  State<DetailedUserScreen> createState() => _DetailedUserScreenState();
}

class _DetailedUserScreenState extends State<DetailedUserScreen> {
  late final DetailedUserBloc _detailedUserBloc;

  @override
  void initState() {
    super.initState();
    _detailedUserBloc = DetailedUserBloc(
      adminService: AdminService(),
      healthService: HealthService(),
    )..add(LoadUserDetail(widget.userData));
  }

  @override
  void dispose() {
    _detailedUserBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _detailedUserBloc,
      child: _DetailedUserView(userData: widget.userData),
    );
  }
}

class _DetailedUserView extends StatelessWidget {
  final Map<String, dynamic> userData;

  const _DetailedUserView({required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5A9A9),
              Color(0xFFFCE4EC),
              Color(0xFFFFF0F0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: BlocConsumer<DetailedUserBloc, DetailedUserState>(
                  listener: (context, state) {
                    if (state is DetailedUserDeleted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                      Navigator.of(context).pop(true);
                    } else if (state is DetailedUserDeleteError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    } else if (state is DetailedUserError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is DetailedUserLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE91E63),
                        ),
                      );
                    }

                    if (state is DetailedUserError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load user details',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context
                                    .read<DetailedUserBloc>()
                                    .add(LoadUserDetail(userData));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE91E63),
                              ),
                              child: const Text('Retry',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is DetailedUserLoaded) {
                      return _buildContent(context, state);
                    }

                    if (state is DetailedUserDeleteError) {
                      final loadedState = DetailedUserLoaded(
                        userData: state.userData,
                        healthData: state.healthData,
                      );
                      return _buildContent(context, loadedState);
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.chevron_left,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Users detail',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, DetailedUserLoaded state) {
    final isAdminUser = state.isAdmin;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildProfileSection(context, state),
              const SizedBox(height: 24),
              if (isAdminUser) ...[
                _buildDivider(),
                _buildInfoRow(
                  icon: Icons.verified_user_outlined,
                  iconColor: const Color(0xFF5E35B1),
                  iconBgColor: const Color(0xFFEDE7F6),
                  label: 'Role',
                  value: 'Admin',
                ),
                _buildDivider(),
                _buildInfoRow(
                  icon: Icons.article_outlined,
                  iconColor: const Color(0xFF6D4C41),
                  iconBgColor: const Color(0xFFEFEBE9),
                  label: 'Blogs written',
                  value: '${state.blogCount}',
                ),
                _buildDivider(),
                _buildInfoRow(
                  icon: Icons.local_hospital_outlined,
                  iconColor: const Color(0xFF00897B),
                  iconBgColor: const Color(0xFFE0F2F1),
                  label: 'Clinics added/updated',
                  value: '${state.clinicCount}',
                ),
                _buildDivider(),
                _buildInfoRow(
                  icon: Icons.event_outlined,
                  iconColor: const Color(0xFF455A64),
                  iconBgColor: const Color(0xFFECEFF1),
                  label: 'Joined date',
                  value: _formatCreatedDate(state.createdDate).replaceFirst('Created Date :  ', ''),
                ),
                _buildDivider(),
                _buildInfoRow(
                  icon: Icons.schedule,
                  iconColor: const Color(0xFF757575),
                  iconBgColor: const Color(0xFFF5F5F5),
                  label: 'Joined',
                  value: state.createdDate != null ? _getJoinedAgoText(state.createdDate!) : 'Unknown',
                  valueColor: const Color(0xFF4CAF50),
                ),
              ] else ...[
                _buildDivider(),
                _buildInfoRow(
                  icon: Icons.calendar_today_outlined,
                  iconColor: const Color(0xFFE57373),
                  iconBgColor: const Color(0xFFFCE4EC),
                  label: 'Cycles tracked',
                  value: '${state.cycleCount}',
                ),
                _buildDivider(),
                _buildInfoRow(
                  icon: Icons.directions_walk,
                  iconColor: const Color(0xFF455A64),
                  iconBgColor: const Color(0xFFECEFF1),
                  label: 'Steps',
                  value: _formatNumber(
                      state.healthData?.healthDataHistory.steps ?? 0),
                ),
                _buildDivider(),
                _buildInfoRow(
                  icon: Icons.local_fire_department,
                  iconColor: const Color(0xFFFF5722),
                  iconBgColor: const Color(0xFFFBE9E7),
                  label: 'Calories burned',
                  value: _formatNumber(
                      state.healthData?.healthDataHistory.calories ?? 0),
                ),
                _buildDivider(),
                _buildInfoRow(
                  icon: Icons.favorite,
                  iconColor: const Color(0xFFE91E63),
                  iconBgColor: const Color(0xFFFCE4EC),
                  label: 'Heart rate',
                  value: '${state.healthData?.heartRate ?? 0}bpm',
                ),
                _buildDivider(),
                _buildInfoRow(
                  icon: Icons.bar_chart,
                  iconColor: const Color(0xFFE91E63),
                  iconBgColor: const Color(0xFFFCE4EC),
                  label: 'Activity Intensity',
                  value: state.healthData?.activityIntensity ?? '—',
                ),
                _buildDivider(),
                _buildInfoRow(
                  icon: Icons.location_on,
                  iconColor: const Color(0xFFE91E63),
                  iconBgColor: const Color(0xFFFCE4EC),
                  label: 'Location',
                  value: state.healthData?.location.isNotEmpty == true
                      ? state.healthData!.location
                      : '—',
                ),
                _buildDivider(),
                _buildInfoRow(
                  icon: Icons.access_time,
                  iconColor: const Color(0xFF757575),
                  iconBgColor: const Color(0xFFF5F5F5),
                  label: 'Last Updated',
                  value: _getLastUpdatedText(state.healthData?.lastUpdated),
                  valueColor: const Color(0xFF4CAF50),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(
      BuildContext context, DetailedUserLoaded state) {
    final profilePhotoUrl = AdminUsersUtils.getProfilePhotoUrl(state.userData);

    return Stack(
      children: [
        Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 80,
                height: 80,
                color: const Color(0xFFE8F5E9),
                child: profilePhotoUrl != null
                    ? Image.network(
                        profilePhotoUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text('👤', style: TextStyle(fontSize: 36)),
                        ),
                      )
                    : const Center(
                        child: Text('👤', style: TextStyle(fontSize: 36)),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              state.userName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email_outlined,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  state.userEmail,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatCreatedDate(state.createdDate),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: BlocBuilder<DetailedUserBloc, DetailedUserState>(
            buildWhen: (prev, curr) => curr is! DetailedUserDeleteError,
            builder: (context, builderState) {
              return IconButton(
                onPressed: () =>
                    _showDeleteConfirmation(context, state.userId),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.shade100,
      height: 1,
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  String _formatCreatedDate(DateTime? date) {
    if (date == null) return 'Created Date :  Unknown';
    final day = date.day;
    final suffix = _getDaySuffix(day);
    final monthYear = DateFormat('MMMM yyyy').format(date);
    return 'Created Date :  $day$suffix $monthYear';
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _getLastUpdatedText(DateTime? lastUpdated) {
    if (lastUpdated == null) return 'Never';
    final now = DateTime.now();
    final diff = now.difference(lastUpdated);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('dd/MM/yyyy').format(lastUpdated);
  }

  String _getJoinedAgoText(DateTime createdDate) {
    final diff = DateTime.now().difference(createdDate);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('dd/MM/yyyy').format(createdDate);
  }

  void _showDeleteConfirmation(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User'),
        content: const Text(
            'Are you sure you want to delete this user? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context
                  .read<DetailedUserBloc>()
                  .add(DeleteUserFromDetail(userId));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
