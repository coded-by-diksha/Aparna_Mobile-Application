import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aparna/l10n/app_localizations.dart';
import '../../main.dart';
import '../../core/di/dependency_injection.dart';
import '../../data/models/health_model.dart';
import 'aama_screen_with_bloc.dart';
import 'user_blogs_screen.dart';
import 'blog_details_screen.dart';
import 'cycle_history_screen.dart';
import 'cycle_prediction_screen.dart';
import 'health_dashboard_screen.dart';
import '../../data/services/blog_service.dart';
import '../../data/models/blog_model.dart';
import '../bloc/health/health_bloc.dart';
import '../bloc/health/health_event.dart';
import '../bloc/health/health_state.dart';

class HealthScreen extends StatefulWidget {
  final String? userName;
  final ValueNotifier<int>? refreshTrigger;

  const HealthScreen({Key? key, this.userName, this.refreshTrigger}) : super(key: key);

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with WidgetsBindingObserver {
  static const _syncInterval = Duration(minutes: 15);
  static const _syncDebounce = Duration(seconds: 30);

  final BlogService _blogService = BlogService();
  List<Blog> _randomBlogs = [];
  bool _isLoadingBlogs = true;
  HealthModel? _healthData;
  bool _isLoadingHealth = true;
  Timer? _autoSyncTimer;
  DateTime? _lastBackgroundSync;

  bool get isWatchConnected =>
      _healthData != null && _healthData!.deviceName.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRandomBlogs();
    _loadCachedHealthData();
    widget.refreshTrigger?.addListener(_onRefreshTrigger);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HealthBloc>().add(LoadHealthCycleData());
        _syncHealthConnectInBackground();
      }
    });
    _startAutoSyncTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _syncHealthConnectInBackground();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSyncTimer?.cancel();
    widget.refreshTrigger?.removeListener(_onRefreshTrigger);
    super.dispose();
  }

  void _startAutoSyncTimer() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(_syncInterval, (_) {
      if (mounted) _syncHealthConnectInBackground();
    });
  }

  void _onRefreshTrigger() {
    if (mounted) _syncAndLoadHealthData();
  }

  /// Fast path: fetch cached data from the backend only (no Health Connect
  /// calls) so the UI can paint immediately.
  Future<void> _loadCachedHealthData() async {
    final userId = DependencyInjection.authRepository.userProfile['uid'];
    if (userId == null) {
      if (mounted) setState(() => _isLoadingHealth = false);
      return;
    }
    try {
      final data =
          await DependencyInjection.healthService.fetchHealthData(userId);
      if (mounted) {
        setState(() {
          _healthData = data;
          _isLoadingHealth = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHealth = false);
    }
  }

  /// Background sync: reads from Health Connect and pushes to backend, then
  /// refreshes the UI. Does NOT set the loading spinner so the user sees the
  /// existing data while the sync runs. Debounced to avoid rapid duplicate calls.
  Future<void> _syncHealthConnectInBackground() async {
    final userId = DependencyInjection.authRepository.userProfile['uid'];
    if (userId == null) return;
    if (_lastBackgroundSync != null &&
        DateTime.now().difference(_lastBackgroundSync!) < _syncDebounce) {
      return;
    }

    try {
      _lastBackgroundSync = DateTime.now();
      final healthService = DependencyInjection.healthService;
      final data = await healthService.fetchHealthData(userId);

      if (data != null && data.deviceName.isNotEmpty) {
        final synced = await healthService.syncHealthDataFromDevice(
          userId,
          deviceName: data.deviceName,
          deviceType: data.deviceType,
          deviceToken: data.deviceToken,
        );
        if (mounted) {
          setState(() {
            _healthData = synced ?? data;
          });
        }
      }
    } catch (_) {
      // Silently ignore — cached data is still visible.
    }
  }

  /// Full sync with loading indicator (used on explicit refresh triggers).
  Future<void> _syncAndLoadHealthData() async {
    final userId = DependencyInjection.authRepository.userProfile['uid'];
    if (userId == null) {
      if (mounted) setState(() => _isLoadingHealth = false);
      return;
    }

    if (mounted && !_isLoadingHealth) {
      setState(() => _isLoadingHealth = true);
    }

    try {
      final healthService = DependencyInjection.healthService;

      var data = await healthService.fetchHealthData(userId);

      if (data != null && data.deviceName.isNotEmpty) {
        final synced = await healthService.syncHealthDataFromDevice(
          userId,
          deviceName: data.deviceName,
          deviceType: data.deviceType,
          deviceToken: data.deviceToken,
        );
        if (synced != null) data = synced;
      }

      if (mounted) {
        setState(() {
          _healthData = data;
          _isLoadingHealth = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHealth = false);
    }
  }

  Future<void> _loadRandomBlogs() async {
    try {
      final blogs = await _blogService.fetchRandomBlogs(limit: 2);
      if (mounted) {
        setState(() {
          _randomBlogs = blogs;
          _isLoadingBlogs = false;
        });
      }
    } catch (e) {
      print('Error loading random blogs: $e');
      if (mounted) {
        setState(() {
          _isLoadingBlogs = false;
        });
      }
    }
  }

  Future<void> _handleBlogTap(Blog blog) async {
    // Record view in background
    _blogService.recordBlogView(blog.id!);
    
    // Navigate to details
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlogDetailsScreen(blog: blog),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final horizontalPadding = (size.width * 0.05).clamp(16.0, 32.0);
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = l10n.goodMorning;
    } else if (hour < 17) {
      greeting = l10n.goodAfternoon;
    } else {
      greeting = l10n.goodEvening;
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/aparna_logo.png',
              height: 60,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.woman_rounded, size: 40),
            ),
            Spacer(),
            GestureDetector(

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AamaScreen(userName: widget.userName),
                  ),
                );
              },
              child: Image.asset(
                'assets/aama.png',
                height: 40,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.chat_bubble_outline, size: 40, color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _syncAndLoadHealthData,
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(greeting),
              const SizedBox(height: 20),
              _buildHealthSync(l10n),
              const SizedBox(height: 20),
              _buildCycleInfo(l10n),
              const SizedBox(height: 20),
              _buildHealthArticles(l10n),
              const SizedBox(height: 100), // Space for navigation bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(String greeting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${AppLocalizations.of(context)!.trackYourHealth}, ${widget.userName ?? 'user'}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthSync(AppLocalizations l10n) {
    final sleepHours = isWatchConnected && _healthData != null
        ? '${_healthData!.healthDataHistory.sleepHours.toStringAsFixed(1)}h'
        : '—';
    final steps = isWatchConnected && _healthData != null
        ? '${_healthData!.healthDataHistory.steps}'
        : '—';
    final calories = isWatchConnected && _healthData != null
        ? '${_healthData!.healthDataHistory.calories}'
        : '—';
    final hasAnyData = isWatchConnected && _healthData != null &&
        (_healthData!.healthDataHistory.steps > 0 ||
            _healthData!.healthDataHistory.calories > 0 ||
            _healthData!.healthDataHistory.sleepHours > 0);
    final deviceLabel = isWatchConnected && _healthData != null
        ? '${_healthData!.deviceName}'
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.healthSync,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.watch_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingHealth)
            Text(
              'Loading...',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          else
            Text(
              isWatchConnected
                  ? (deviceLabel != null
                      ? 'Connected to $deviceLabel'
                      : 'Connected to your device')
                  : 'Not connected',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          if (!_isLoadingHealth && !isWatchConnected) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HealthDashboardScreen(),
                    ),
                  );
                  _syncAndLoadHealthData();
                },
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Connect device'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ],
          if (isWatchConnected) ...[
            if (!hasAnyData) ...[
              const SizedBox(height: 6),
              Text(
                'Data will appear after sync. Pull down to refresh. Water: tap Log in dashboard (wearables rarely sync water).',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HealthDashboardScreen(),
                  ),
                );
                _syncAndLoadHealthData();
              },
              child: Text(
                'View full dashboard',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHealthStat(l10n.sleep, sleepHours),
              _buildHealthStat(l10n.steps, steps),
              _buildHealthStat(l10n.calories, calories),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStat(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleInfo(AppLocalizations l10n) {
    return BlocListener<HealthBloc, HealthState>(
      listenWhen: (previous, current) => current is HealthCycleError,
      listener: (context, state) {
        if (state is HealthCycleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () =>
                    context.read<HealthBloc>().add(LoadHealthCycleData()),
              ),
            ),
          );
        }
      },
      //using blocselector to build the cycle info card
      child: BlocSelector<HealthBloc, HealthState, HealthState?>(
        selector: (state) => state,
        builder: (context, state) {
          if (state is HealthCycleLoading) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.primaryColor),
                ),
              ),
            );
          }
          if (state is HealthCycleError) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.message,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => context.read<HealthBloc>().add(LoadHealthCycleData()),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is HealthCycleLoaded) {
          return Column(
            children: [
              _buildCycleCard(
                icon: Icons.calendar_today,
                title: l10n.cycleTracking,
                value: state.cyclesTracked > 0 ? state.cyclesTracked.toString() : '0',
                color: AppTheme.secondaryColor,
                l10n: l10n,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CycleHistoryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildCycleCard(
                icon: Icons.water_drop_outlined,
                title: l10n.nextPeriodIn,
                value: state.nextPeriodDays != null
                    ? '${state.nextPeriodDays} ${l10n.days.toLowerCase()}'
                    : '—',
                color: AppTheme.secondaryColor,
                l10n: l10n,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CyclePredictionScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildCycleCard(
                icon: Icons.favorite_outline,
                title: l10n.currentPhase,
                value: state.currentPhase,
                color: AppTheme.secondaryColor,
                isPhase: true,
                l10n: l10n,
              ),
            ],
          );
        }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCycleCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required AppLocalizations l10n,
    bool isPhase = false,
    VoidCallback? onTap,
  }) {
    final content = Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildHealthArticles(AppLocalizations l10n) {
    if (_isLoadingBlogs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_randomBlogs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.healthArticles,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserBlogsScreen()),
                );
              },
              child: Text(
                l10n.seeMore,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: _randomBlogs.asMap().entries.map((entry) {
            int idx = entry.key;
            Blog b = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: idx == 0 ? 0 : 6, right: idx == 0 ? 6 : 0),
                child: _buildArticleCard(
                  blog: b,
                  color: idx % 2 == 0 
                      ? AppTheme.secondaryColor.withOpacity(0.4) 
                      : AppTheme.backgroundColor.withOpacity(0.6),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildArticleCard({
    required Blog blog,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _handleBlogTap(blog),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          // image: blog.imageUrl != null 
          //   ? DecorationImage(
          //       image: NetworkImage(
          //         '${ApiConstant.baseUrl}${blog.imageUrl!.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '')}'
          //       ),
          //       fit: BoxFit.cover,
          //       opacity: 0.3,
          //     )
          //   : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (blog.imageUrl == null)
              Text(
                blog.categoryIcon ?? '🌸',
                style: const TextStyle(fontSize: 40),
              ),
            const SizedBox(height: 8),
            Text(
              blog.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              blog.categoryName ?? '',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
