import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/health/health_bloc.dart';
import '../screens/homepage.dart';
import '../screens/health.dart';
import '../screens/profile.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/responsive_layout.dart';
import '../../core/di/dependency_injection.dart';

class MainNavigationScreen extends StatefulWidget {
  final String? userName;

  const MainNavigationScreen({Key? key, this.userName}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final ValueNotifier<int> _healthTabRefresh = ValueNotifier<int>(0);
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      BlocProvider(
        create: (context) => DependencyInjection.createPeriodStatsBloc(),
        child: Homepage(userName: widget.userName),
      ),
      BlocProvider<HealthBloc>(
        create: (context) => DependencyInjection.createHealthBloc(),
        child: HealthScreen(
          userName: widget.userName,
          refreshTrigger: _healthTabRefresh,
        ),
      ),
      BlocProvider(
        create: (context) => DependencyInjection.createProfileBloc(),
        child: ProfileScreen(userName: widget.userName),
      ),
    ];
  }

  @override
  void dispose() {
    _healthTabRefresh.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 1) _healthTabRefresh.value++;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1) MOBILE VIEW: Keeps the exact original Stack behavior and design.
    final mobileView = Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 100), // Reserve space for the floating bar
          child: _screens[_currentIndex],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: FloatingNavBar(
            currentIndex: _currentIndex,
            onTap: _onNavTap,
          ),
        ),
      ],
    );

    // 2) DESKTOP/TABLET VIEW: Modern Sidebar layout
    final desktopView = Row(
      children: [
        SideNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 16, right: 16),
            child: ClipRRect(
              // Just in case the inner screens don't have borders, let's round them a bit
              borderRadius: BorderRadius.circular(24),
              child: Container(
                color: Colors.white,
                child: _screens[_currentIndex],
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background works well with sidebars
      body: ResponsiveLayout(
        mobile: mobileView,
        tablet: desktopView, // Use same sidebar for tablet
        desktop: desktopView,
      ),
    );
  }
}
