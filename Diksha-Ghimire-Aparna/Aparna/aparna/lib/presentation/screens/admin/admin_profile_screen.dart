import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../main.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../../core/guards/auth_guard.dart';
import '../login.dart';
import 'package:aparna/l10n/app_localizations.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../bloc/profile/profile_state.dart';
import '../edit_profile_screen.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import 'package:aparna/core/constant/apiConstant.dart';
import 'package:aparna/core/services/notification_preference_service.dart';
import 'package:aparna/core/services/secure_session_service.dart';
import 'admin_analytics_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  final String? userName;
  final Map<String, dynamic>? userProfile;

  const AdminProfileScreen({
    Key? key,
    this.userName,
    this.userProfile,
  }) : super(key: key);

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  bool _notificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final enabled = await NotificationPreferenceService.isNotificationsEnabled();
    if (mounted) setState(() => _notificationEnabled = enabled);
  }

  void _loadProfile() {
    final authRepo = DependencyInjection.authRepository as AuthRepositoryImpl;
    final token = authRepo.getToken();
    final userId = authRepo.userProfile['uid'];

    if (userId != null) {
      context.read<ProfileBloc>().add(
            LoadUserProfile(userId: userId, token: token),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final horizontalPadding = (size.width * 0.05).clamp(16.0, 32.0);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is ProfileUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            final user = state is ProfileLoaded ? state.user : 
                        state is ProfileUpdated ? state.user : null;

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.manageYourAccount,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.profile,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Profile Card
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              image: user?.profilephoto != null && user!.profilephoto!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        (() {
                                          final normalized = user.profilephoto!.replaceAll('\\', '/');
                                          if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
                                            return normalized;
                                          }
                                          return '${ApiConstant.baseUrl}${normalized.replaceFirst(RegExp(r'^/+'), '')}';
                                        })()
                                      ),
                                      fit: BoxFit.cover,
                                      onError: (exception, stackTrace) {
                                        print('Error loading profile image: $exception');
                                      },
                                    )
                                  : null,
                            ),
                            child: user?.profilephoto == null || user!.profilephoto!.isEmpty
                                ? const Icon(
                                    Icons.admin_panel_settings,
                                    color: AppTheme.primaryColor,
                                    size: 50,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.username ?? widget.userName ?? 'Admin',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.email ?? widget.userProfile?['email'] ?? 'admin@aparna.com',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Admin Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatCard(l10n.admin, l10n.role),
                              _buildStatCard(l10n.active, l10n.status),
                              _buildStatCard('v1.0', l10n.version),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Account Section
                    _buildSectionTitle(l10n.account),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      Icons.person_outline,
                      l10n.personalInformation,
                      () => _navigateToEditProfile(user),
                    ),
                    _buildMenuItem(
                      Icons.lock_outline,
                      l10n.privacyAndSecurity,
                      () {},
                    ),
                    _buildMenuItem(
                      Icons.notifications_none,
                      l10n.notification,
                      () {},
                      hasSwitch: true,
                      onclick: () => _handleNotificationToggle(l10n),
                      switchValue: _notificationEnabled,
                    ),
                    const SizedBox(height: 20),

                    // Preferences Section
                    _buildSectionTitle(l10n.preferences),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      Icons.language,
                      l10n.language,
                      () => _showLanguageDialog(),
                      trailing: Text(
                        Localizations.localeOf(context).languageCode == 'ne' ? 'नेपाली' : 'Eng',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    _buildMenuItem(
                      Icons.analytics_outlined,
                      l10n.analyticsOverview,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminAnalyticsScreen(),
                          ),
                        );
                      },
                    ),
                   const SizedBox(height: 20),

                    // Support Section
                    _buildSectionTitle(l10n.support),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      Icons.help_outline,
                      l10n.helpCenter,
                      () {},
                    ),
                    _buildMenuItem(
                      Icons.info_outline,
                      l10n.aboutApp,
                      () {},
                    ),
                    const SizedBox(height: 30),

                    // Logout Button
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _handleLogout(),
                        icon: Icon(
                          Icons.logout,
                          color: Colors.red[400],
                        ),
                        label: Text(
                          l10n.logOut,
                          style: TextStyle(
                            color: Colors.red[400],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 100), // Space for navigation bar
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool hasSwitch = false,
    bool switchValue = false,
    Widget? trailing,
    VoidCallback? onclick,
  }) {
    return InkWell(
      onTap: hasSwitch ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (hasSwitch)
              Switch(
                value: switchValue,
                onChanged: onclick != null ? (value) => onclick() : null,
                activeColor: AppTheme.primaryColor,
              )
            else if (trailing != null)
              trailing
            else
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToEditProfile(dynamic user) async {
    final authRepo = DependencyInjection.authRepository as AuthRepositoryImpl;
    final userId = authRepo.userProfile['uid'];
    
    final profileBloc = context.read<ProfileBloc>();
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: profileBloc,
          child: EditProfileScreen(
            user: user,
            userId: userId,
          ),
        ),
      ),
    );

    if (result == true) {
      _loadProfile();
    }
  }

  void _handleLogout() async {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.logout),
          content: Text(l10n.logoutConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel, style: TextStyle(color: Colors.grey.shade600)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await AuthService.clearSession();
                if (mounted) {
                  context.read<AuthBloc>().add(LogoutRequested());
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.logout),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English', 'en'),
            _buildLanguageOption('नेपाली (Nepali)', 'ne'),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNotificationToggle(AppLocalizations l10n) async {
    final newValue = !_notificationEnabled;
    final title = newValue ? l10n.turnOnNotificationsTitle : l10n.turnOffNotificationsTitle;
    final message = newValue ? l10n.turnOnNotificationsMessage : l10n.turnOffNotificationsMessage;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await NotificationPreferenceService.setNotificationsEnabled(newValue);
    if (!mounted) return;

    if (success) {
      setState(() => _notificationEnabled = newValue);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newValue ? l10n.notificationsEnabled : l10n.notificationsDisabled),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (newValue) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.notificationPermissionDenied),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _notificationEnabled = false);
        await NotificationPreferenceService.setNotificationsEnabled(false);
      }
    }
  }

  Widget _buildLanguageOption(String title, String code) {
    final isSelected = Localizations.localeOf(context).languageCode == code;
    return ListTile(
      title: Text(title),
      trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
      onTap: () async {
        await SecureSessionService.saveLanguage(code);
        if (mounted) {
          MyApp.setLocale(context, Locale(code));
          Navigator.pop(context);
        }
      },
    );
  }
}
