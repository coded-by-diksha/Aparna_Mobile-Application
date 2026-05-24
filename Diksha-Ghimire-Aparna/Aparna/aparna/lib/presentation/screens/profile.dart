import 'package:aparna/presentation/screens/health_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../core/di/dependency_injection.dart';
import '../../core/guards/auth_guard.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../bloc/profile/profile_bloc.dart';
import '../bloc/profile/profile_event.dart';
import '../bloc/profile/profile_state.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import 'change_password.dart';
import 'login.dart';
import 'edit_profile_screen.dart';
import 'expertHelp.dart';
import 'package:aparna/l10n/app_localizations.dart';
import '../../core/constant/apiConstant.dart';
import '../../core/services/notification_preference_service.dart';
import '../../data/services/cycle_service.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;
  final String? userName;

  const ProfileScreen({Key? key, this.userId, this.userName}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedLanguage = 'en';
  bool _notificationEnabled = false;
  int? _daysTracked;
  int _cyclesCount = 0;
  int? _avgCycleLength;
  bool _cycleStatsLoading = true;
  bool _useLocalProfileImage = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _loadProfile();
    _loadCycleStats();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final enabled = await NotificationPreferenceService.isNotificationsEnabled();
    if (mounted) setState(() => _notificationEnabled = enabled);
  }

  Future<void> _loadCycleStats() async {
    setState(() => _cycleStatsLoading = true);
    try {
      final history = await CycleService().fetchHistory();
      if (!mounted) return;
      final cyclesCount = history.length;
      int? daysTracked;
      int? avgCycleLength;
      if (history.isNotEmpty) {
        final oldest = history.last;
        final firstStart = DateTime.tryParse(
          (oldest['period_start_date'] ?? oldest['period_start_date']?.toString() ?? '').toString(),
        );
        if (firstStart != null) {
          daysTracked = DateTime.now().difference(DateTime(firstStart.year, firstStart.month, firstStart.day)).inDays;
          if (daysTracked < 0) daysTracked = 0;
        }
        final lengths = <int>[];
        for (final c in history) {
          final cl = c['cycle_length'];
          if (cl != null) {
            final v = cl is num ? cl.toInt() : int.tryParse(cl.toString());
            if (v != null && v > 0) lengths.add(v);
          }
        }
        if (lengths.isNotEmpty) {
          avgCycleLength = (lengths.reduce((a, b) => a + b) / lengths.length).round();
        }
      }
      if (mounted) {
        setState(() {
          _daysTracked = daysTracked;
          _cyclesCount = cyclesCount;
          _avgCycleLength = avgCycleLength;
          _cycleStatsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _daysTracked = null;
          _cyclesCount = 0;
          _avgCycleLength = null;
          _cycleStatsLoading = false;
        });
      }
    }
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'en';
    });
  }

  Future<void> _setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    setState(() {
      _selectedLanguage = languageCode;
    });
    // Notify main app to rebuild
    if (mounted) {
      MyApp.setLocale(context, Locale(languageCode));
    }
  }

  void _loadProfile() {
    final authRepo = DependencyInjection.authRepository as AuthRepositoryImpl;
    final token = authRepo.getToken();
    final userId = widget.userId ?? authRepo.userProfile['uid'];

    print('Loading profile - Token: ${token.isNotEmpty ? "Present" : "Missing"}');
    print('Loading profile - UserId: $userId');
    print('Loading profile - User Profile: ${authRepo.userProfile}');

    if (userId != null) {
      context.read<ProfileBloc>().add(
            LoadUserProfile(userId: userId, token: token),
          );
    } else {
      print('ERROR: UserId is null, cannot load profile');
      // Use addPostFrameCallback to show SnackBar after widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to load profile: User ID not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
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
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = state is ProfileLoaded ? state.user : 
                        state is ProfileUpdated ? state.user : null;

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
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
                          ],
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.black87),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            if (value == 'change_password') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChangePasswordScreen(),
                                ),
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'change_password',
                              child: Row(
                                children: [
                                  Icon(Icons.lock_outline, size: 20),
                                  SizedBox(width: 10),
                                  Text('Change Password'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _buildProfileAvatar(user?.profilephoto),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.username ?? widget.userName ?? 'User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Stats Row (dynamic from backend via cycle history)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatCard(
                                _cycleStatsLoading ? '—' : (_daysTracked ?? 0).toString(),
                                l10n.days,
                              ),
                              _buildStatCard(
                                _cycleStatsLoading ? '—' : _cyclesCount.toString(),
                                l10n.cycles,
                              ),
                              _buildStatCard(
                                _cycleStatsLoading ? '—' : (_avgCycleLength?.toString() ?? '—'),
                                l10n.avgLength,
                              ),
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
                      () {_navigateToPrivacyAndSecurity(user);},
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
                      () => _showLanguageDialog(l10n),
                      trailing: Text(
                        _selectedLanguage == 'en' ? 'Eng' : 'ने',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                   
                    _buildMenuItem(
                      Icons.watch_outlined,
                      l10n.connectedWatch,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HealthDashboardScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // Data Section                // const SizedBox(height: 12),
                    // _buildMenuItem(
                    //   Icons.file_download_outlined,
                    //   l10n.exportData,
                    //   () {},
                    // ),
                    // const SizedBox(height: 20),
                    // Contact Section
                    _buildSectionTitle(l10n.contact),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      Icons.medical_services_outlined,
                      l10n.contactHealthExpert,
                      () {
                        if (!context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ExpertHelp(),
                          ),
                        );
                      },
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
              fontSize: 24,
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

  Widget _buildProfileAvatar(String? profilePhoto) {
    if (profilePhoto == null || profilePhoto.trim().isEmpty) {
      return Image.asset('assets/aparna.png', fit: BoxFit.cover);
    }

    final normalizedPath = profilePhoto
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/+'), '');

    if (normalizedPath.startsWith('http://') || normalizedPath.startsWith('https://')) {
      return Image.network(
        normalizedPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset('assets/aparna.png', fit: BoxFit.cover),
      );
    }

    final primaryBase = _useLocalProfileImage ? ApiConstant.localBaseUrl : ApiConstant.baseUrl;
    final fallbackBase = _useLocalProfileImage ? ApiConstant.baseUrl : ApiConstant.localBaseUrl;
    final primaryUrl = '$primaryBase$normalizedPath';
    final fallbackUrl = '$fallbackBase$normalizedPath';

    return Image.network(
      primaryUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        if (!_useLocalProfileImage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _useLocalProfileImage = true;
              });
            }
          });
          return Image.network(
            fallbackUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset('assets/aparna.png', fit: BoxFit.cover),
          );
        }
        return Image.asset('assets/aparna.png', fit: BoxFit.cover);
      },
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

  void _showLanguageDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.english),
              trailing: _selectedLanguage == 'en' 
                  ? const Icon(Icons.check, color: AppTheme.primaryColor) 
                  : null,
              onTap: () {
                _setLanguage('en');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(l10n.nepali),
              trailing: _selectedLanguage == 'ne' 
                  ? const Icon(Icons.check, color: AppTheme.primaryColor) 
                  : null,
              onTap: () {
                _setLanguage('ne');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToEditProfile(dynamic user) async {
    final authRepo = DependencyInjection.authRepository as AuthRepositoryImpl;
    final userId = widget.userId ?? authRepo.userProfile['uid'];
    
    // Capture ProfileBloc BEFORE navigation
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

    // Reload profile if changes were saved
    if (result == true) {
      _loadProfile();
    }
  }

  void _handleLogout() async {
    // Clear saved session
    await AuthService.clearSession();
    context.read<AuthBloc>().add(const LogoutRequested());
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _navigateToPrivacyAndSecurity(dynamic user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyAndSecurityScreen()),
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
}
