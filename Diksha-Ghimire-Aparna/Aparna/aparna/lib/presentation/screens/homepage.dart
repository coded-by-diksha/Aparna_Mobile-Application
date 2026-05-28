import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:aparna/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../bloc/period_tracking/period_tracking_bloc.dart';
import '../bloc/period_tracking/period_tracking_event.dart';
import '../bloc/period_tracking/period_tracking_state.dart';
import '../bloc/period_stats/period_stats_bloc.dart';
import '../bloc/period_stats/period_stats_event.dart';
import '../widgets/period_stats_widget.dart';
import '../../core/di/dependency_injection.dart';
import '../bloc/notification/notification_bloc.dart';
import '../bloc/notification/notification_state.dart';
import '../bloc/notification/notification_event.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../core/guards/auth_guard.dart';
import 'notification_page.dart';
import '../../data/services/cycle_service.dart';
import '../../main.dart';
import '../widgets/responsive_wrapper.dart';

class Homepage extends StatefulWidget {
  final String? userName;

  const Homepage({super.key, this.userName});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // All state is now managed by BLoC. No direct service or local state.
  late CycleService _cycleService;
  final List<DateTime> _historyDays = [];
  final List<DateTime> _predictedDays = [];
  DateTime _focusedDay = DateTime.now();
  bool _isHomeLoading = true;

  @override
  void initState() {
    _cycleService = CycleService();
    super.initState();
    final authRepo = DependencyInjection.authRepository as AuthRepositoryImpl;
    final token = authRepo.getToken();
    final userId = authRepo.userProfile['uid'] ?? 0;
    context.read<PeriodStatsBloc>().add(LoadPeriodStats(userId: userId, token: token));
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    try {
      final currentUserId = await AuthService.getUserId();
      final historyRaw = await _cycleService.fetchHistory();
      print('[Calendar] Loaded ${historyRaw.length} history records');
      
      Map<String, dynamic> prediction = {};
      try {
        prediction = await _cycleService.fetchPrediction();
        print('[Calendar] Prediction: ${prediction.keys.join(", ")}');
      } catch (e) {
        print('[Calendar] Prediction fetch failed: $e');
      }
      if (!mounted) return;

      final history = currentUserId == null
          ? historyRaw
          : historyRaw.where((cycle) {
              if (cycle is! Map) return false;
              final dynamic uid = cycle['user_id'] ?? cycle['userId'] ?? cycle['uid'];
              if (uid is int) return uid == currentUserId;
              return int.tryParse(uid?.toString() ?? '') == currentUserId;
            }).toList();

      final List<DateTime> histDays = [];
      for (final cycle in history) {
        final startStr = cycle['period_start_date'];
        final mensesLen = int.tryParse(cycle['menses_length']?.toString() ?? '') ?? 0;
        if (startStr == null || mensesLen <= 0) continue;
        final start = DateTime.tryParse(startStr.toString());
        if (start == null) continue;
        for (int i = 0; i < mensesLen; i++) {
          histDays.add(DateTime(start.year, start.month, start.day + i));
        }
      }

      // Estimate menses length from history for painting prediction ranges
      int avgMenses = 5;
      if (history.isNotEmpty) {
        final lens = history
            .map<int>((c) => int.tryParse(c['menses_length']?.toString() ?? '') ?? 0)
            .where((len) => len > 0)
            .toList();
        if (lens.isNotEmpty) {
          avgMenses = (lens.reduce((a, b) => a + b) / lens.length).round();
        }
      }

      final List<DateTime> predDays = [];
      if (prediction.isNotEmpty && prediction['predictedDates'] != null) {
        final List dates = prediction['predictedDates'] as List;
        
        for (final entry in dates) {
          final dateStr = entry is Map ? entry['date'] : entry.toString();
          print('[Calendar] Parsing prediction date: $dateStr');
          final start = DateTime.tryParse(dateStr.toString());
          if (start == null) {
            print('[Calendar] Failed to parse: $dateStr');
            continue;
          }

          for (int i = 0; i < avgMenses; i++) {
            predDays.add(DateTime(start.year, start.month, start.day + i));
          }
        }
      }

      if (predDays.isEmpty && history.isNotEmpty) {
        // Local fallback prediction from cycle history when API data is missing.
        final List<DateTime> starts = history
            .map<DateTime?>((cycle) => DateTime.tryParse((cycle['period_start_date'] ?? '').toString()))
            .where((d) => d != null)
            .cast<DateTime>()
            .toList()
          ..sort();

        if (starts.isNotEmpty) {
          int avgCycleLen = 28;
          if (starts.length >= 2) {
            final gaps = <int>[];
            for (int i = 1; i < starts.length; i++) {
              final gap = DateTime(starts[i].year, starts[i].month, starts[i].day)
                  .difference(DateTime(starts[i - 1].year, starts[i - 1].month, starts[i - 1].day))
                  .inDays;
              if (gap > 15 && gap < 60) gaps.add(gap);
            }
            if (gaps.isNotEmpty) {
              avgCycleLen = (gaps.reduce((a, b) => a + b) / gaps.length).round();
            }
          }

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final lastStart = starts.last;
          DateTime predictedStart = DateTime(lastStart.year, lastStart.month, lastStart.day + avgCycleLen);
          while (predictedStart.isBefore(today)) {
            predictedStart = predictedStart.add(Duration(days: avgCycleLen));
          }

          for (int i = 0; i < avgMenses; i++) {
            predDays.add(DateTime(predictedStart.year, predictedStart.month, predictedStart.day + i));
          }
        }
      }

      print('[Calendar] Final state: ${histDays.length} hist, ${predDays.length} pred');
      setState(() {
        _historyDays.clear();
        _historyDays.addAll(histDays);
        _predictedDays.clear();
        _predictedDays.addAll(predDays);
        _focusedDay = _predictedDays.isNotEmpty ? _predictedDays.first : DateTime.now();
        _isHomeLoading = false;
      });
    } catch (e) {
      print('[Calendar] ERROR loading calendar: $e');
      if (mounted) {
        setState(() {
          _isHomeLoading = false;
        });
      }
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isCurrentlyMenstruating(PeriodTrackingState state) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final hasActivePeriodInState =
        state.periodSwitchValue && state.periodDays.any((d) => _isSameDate(d, today));
    final hasActivePeriodInHistory = _historyDays.any((d) => _isSameDate(d, today));

    return hasActivePeriodInState || hasActivePeriodInHistory;
  }

  /// Responsive text scale: smaller on narrow screens so full text fits
  double _textScale(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w / 380).clamp(0.8, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final textScale = _textScale(context);
    final horizontalPadding = (size.width * 0.04).clamp(12.0, 24.0);
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<PeriodTrackingBloc, PeriodTrackingState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: ResponsiveWrapper(
        child: BlocBuilder<PeriodTrackingBloc, PeriodTrackingState>(
          builder: (context, state) {
            final isCurrentlyMenstruating = _isCurrentlyMenstruating(state);
            return Scaffold(
              backgroundColor: const Color(0xFFFAFAFA),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/aparna_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.spa, color: Colors.pink, size: 30),
                      ),
                    ),
                  ],
                ),
                actions: [
                  BlocListener<NotificationBloc, NotificationState>(
                    listener: (context, state) {
                      if (state is NotificationError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: BlocBuilder<NotificationBloc, NotificationState>(
                      builder: (context, state) {
                        int unreadCount = 0;
                        if (state is NotificationCountLoaded) {
                          unreadCount = state.count;
                        }
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none_outlined,
                                  color: Colors.black54, size: 30),
                              onPressed: () {
                                context.read<NotificationBloc>().add(NotificationMarkAllAsRead());
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const NotificationPage()),
                                );
                              },
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              body: ResponsiveWrapper(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isHomeLoading) ...[
                        _buildHomepageSkeleton(textScale),
                      ] else ...[
                        _buildWelcomeSection(context, widget.userName, l10n),
                        const SizedBox(height: 32),
                        if (isCurrentlyMenstruating) ...[
                          _buildFeltSomethingCard(context, isCurrentlyMenstruating),
                          const SizedBox(height: 32),
                        ],
                        _buildPeriodTrackerCard(context, state, l10n, textScale),
                        const SizedBox(height: 32),
                        _buildCalendarSection(context, state, textScale),
                        const SizedBox(height: 32),
                        const PeriodStatsWidget(),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
}

  Widget _buildHomepageSkeleton(double textScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeSkeleton(),
        const SizedBox(height: 32),
        _buildSkeletonCard(height: 92, radius: 20),
        const SizedBox(height: 32),
        _buildSkeletonCard(height: 120, radius: 20),
        const SizedBox(height: 32),
        _buildCalendarSkeleton(textScale),
        const SizedBox(height: 32),
        _buildStatsSkeleton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildWelcomeSkeleton() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSkeletonBox(width: 180, height: 28, radius: 10),
              const SizedBox(height: 12),
              _buildSkeletonBox(width: 220, height: 16, radius: 8),
              const SizedBox(height: 8),
              _buildSkeletonBox(width: 160, height: 16, radius: 8),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildSkeletonBox(width: 100, height: 80, radius: 14),
      ],
    );
  }

  Widget _buildCalendarSkeleton(double textScale) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 350),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildSkeletonBox(width: 150, height: 18, radius: 8),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 10,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: 35,
              itemBuilder: (_, __) => _buildSkeletonBox(width: 24, height: 24, radius: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSkeleton() {
    return _buildSkeletonCard(
      height: 160,
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonBox(width: 130, height: 16, radius: 8),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSkeletonBox(width: double.infinity, height: 88, radius: 12)),
              const SizedBox(width: 12),
              Expanded(child: _buildSkeletonBox(width: double.infinity, height: 88, radius: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard({
    required double height,
    required double radius,
    Widget? child,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child ?? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonBox(width: 130, height: 14, radius: 8),
          const SizedBox(height: 12),
          _buildSkeletonBox(width: 220, height: 14, radius: 8),
        ],
      ),
    );
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

  Widget _buildWelcomeSection(BuildContext context, String? name, AppLocalizations l10n) {
    final scale = _textScale(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.welcome} ${name ?? "user"}!',
                style: TextStyle(
                  fontSize: (32 * scale).roundToDouble(),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: (12 * scale).roundToDouble()),
              Text(
                l10n.summaryRecentActivity,
                style: TextStyle(
                  fontSize: (18 * scale).roundToDouble(),
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Character Image
        Container(
          width: 100,
          height: 80,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/welcome.png'), // Swapped image
              fit: BoxFit.contain,
              alignment: Alignment.centerRight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodTrackerCard(BuildContext context, PeriodTrackingState state, AppLocalizations l10n, double textScale) {
    bool isPeriodStarted = state.periodSwitchValue;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (18 * textScale).clamp(16.0, 24.0).roundToDouble(),
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.pink.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.water_drop,
              color: Colors.pink[300],
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          // Text - allow wrap for complete display
          Expanded(
            child: Text(
              l10n.periodStarted,
              style: TextStyle(
                fontSize: (18 * textScale).roundToDouble(),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A4A4A),
              ),
              maxLines: 2,
              overflow: TextOverflow.visible,
            ),
          ),
          const SizedBox(width: 12),
          // Toggle: segmented control (Yes / No)
          Material(
            color: Colors.transparent,
            child: Container(
              width: 120,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildPeriodToggleSegment(
                    context: context,
                    label: l10n.yes,
                    textScale: textScale,
                    isSelected: isPeriodStarted,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                    onTap: () async {
                      if (!isPeriodStarted) {
                        final DateTime? picked = await _showDatePicker(context);
                        if (picked != null) {
                          final moodData = await _showMoodDialog(context);
                          if (moodData != null) {
                            final days = moodData['mensesLength'] as int? ?? 5;
                            final success = await _cycleService.recordPeriod(
                              startDate: picked.toIso8601String().split('T')[0],
                              mensesLength: days,
                              moodScore: moodData['score'],
                              emotions: moodData['emotions'],
                              flowLevel: moodData['flowLevel'],
                            );
                            if (success && context.mounted) {
                              context.read<PeriodTrackingBloc>().add(const TogglePeriodSwitch(true));
                              context.read<PeriodTrackingBloc>().add(UpdatePeriodDuration(days));
                              context.read<PeriodTrackingBloc>().add(SetPeriodStartDate(picked));
                              _loadCycleData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Period and mood recorded!'), backgroundColor: Colors.green),
                              );
                            }
                          }
                        }
                      }
                    },
                    selectedColor: AppTheme.secondaryColor,
                  ),
                  _buildPeriodToggleSegment(
                    context: context,
                    label: l10n.no,
                    textScale: textScale,
                    isSelected: !isPeriodStarted,
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
                    onTap: () {
                      if (isPeriodStarted) {
                        context.read<PeriodTrackingBloc>().add(const TogglePeriodSwitch(false));
                      }
                    },
                    selectedColor: Colors.grey[600]!,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggleSegment({
    required BuildContext context,
    required String label,
    required double textScale,
    required bool isSelected,
    required BorderRadius borderRadius,
    required VoidCallback onTap,
    required Color selectedColor,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? selectedColor : Colors.transparent,
              borderRadius: borderRadius,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: selectedColor.withOpacity(0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: (14 * textScale).roundToDouble(),
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarSection(BuildContext context, PeriodTrackingState state, double textScale) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 350), // Limit calendar width
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: TableCalendar(
        focusedDay: _focusedDay,
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: (17 * textScale).roundToDouble(),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4A4A4A),
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.pink),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.pink),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: Colors.brown[300],
            fontWeight: FontWeight.bold,
            fontSize: (12 * textScale).roundToDouble(),
          ),
          weekendStyle: TextStyle(
            color: Colors.brown[300],
            fontWeight: FontWeight.bold,
            fontSize: (12 * textScale).roundToDouble(),
          ),
        ),
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return _buildCalendarDay(day, state, textScale: textScale, isSelected: false, isToday: false);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildCalendarDay(day, state, textScale: textScale, isSelected: false, isToday: true);
          },
          selectedBuilder: (context, day, focusedDay) {
            return _buildCalendarDay(day, state, textScale: textScale, isSelected: true, isToday: false);
          },
        ),
        onDaySelected: (selectedDay, focusedDay) {
           _handleCalendarTap(context, selectedDay);
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
      ),
    );
  }

  Widget _buildCalendarDay(DateTime day, PeriodTrackingState state,
      {double textScale = 1.0, required bool isSelected, required bool isToday}) {
    
    // Check if day is part of the CURRENT period from state OR historical days
    bool isPeriodDay = state.periodDays.any((d) => 
      d.year == day.year && d.month == day.month && d.day == day.day
    ) || _historyDays.any((d) => 
      d.year == day.year && d.month == day.month && d.day == day.day
    );

    // Styling logic mimicking the mockup's strip
    if (isPeriodDay) {
       // Check connectivity for strip effect (we combine state and history here for visual consistency)
       final combinedDays = {...state.periodDays, ..._historyDays};
       DateTime nextDay = day.add(const Duration(days: 1));
       DateTime prevDay = day.subtract(const Duration(days: 1));
       bool isNextPeriod = combinedDays.any((d) => d.year == nextDay.year && d.month == nextDay.month && d.day == nextDay.day);
       bool isPrevPeriod = combinedDays.any((d) => d.year == prevDay.year && d.month == prevDay.month && d.day == prevDay.day);
       
       BorderRadius borderRadius;
       if (!isPrevPeriod && !isNextPeriod) {
         borderRadius = BorderRadius.circular(8); // Single day
       } else if (!isPrevPeriod) {
         borderRadius = const BorderRadius.horizontal(left: Radius.circular(20)); // Start
       } else if (!isNextPeriod) {
         borderRadius = const BorderRadius.horizontal(right: Radius.circular(20)); // End
       } else {
         borderRadius = BorderRadius.zero; // Middle
       }

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEF5350), // Red color for period
          borderRadius: borderRadius,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Check if day is a predicted period day
    bool isPredictedDay = _predictedDays.any((d) => 
      d.year == day.year && d.month == day.month && d.day == day.day
    );

    if (isPredictedDay) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.purple.shade50.withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.purple.shade200, style: BorderStyle.solid, width: 1),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: Colors.purple.shade700,
                fontWeight: FontWeight.bold,
                fontSize: (13 * textScale).roundToDouble(),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 4, 
              height: 4, 
              decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
            ),
          ],
        ),
      );
    }

    return Container(
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: isToday ? Colors.black : Colors.black87,
          fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
          fontSize: (15 * textScale).roundToDouble(),
        ),
      ),
    );
  }

  Widget _buildFeltSomethingCard(BuildContext context, bool isCurrentlyMenstruating) {
    final scale = _textScale(context);
    return GestureDetector(
      onTap: isCurrentlyMenstruating ? () => _showFeltSomethingDialog(context) : null,
      child: Container(
        padding: EdgeInsets.all((16 * scale).roundToDouble()),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFF8A5A5).withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFEEEE), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.psychology_outlined, color: Color(0xFFF8A5A5), size: 28),
            ),
            SizedBox(width: (16 * scale).roundToDouble()),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Felt something...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: (17 * scale).roundToDouble(),
                    ),
                  ),
                  SizedBox(height: (4 * scale).roundToDouble()),
                  Text(
                    'Log your mood or symptoms today',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: (13 * scale).roundToDouble(),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline, color: Color(0xFFF8A5A5), size: 28),
          ],
        ),
      ),
    );
  }

  void _showFeltSomethingDialog(BuildContext context) {
    final state = context.read<PeriodTrackingBloc>().state;
    if (!_isCurrentlyMenstruating(state)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily check-in is available only during menstruation.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final TextEditingController textController = TextEditingController();
    int selectedMood = 3;
    int selectedFlow = 0; // 0 means not recorded or no flow
    const List<String> emojis = ['😫', '😟', '😐', '😊', '😁'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily Check-in', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF8A5A5))),
            const SizedBox(height: 20),
            const Text('How are you feeling?', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            StatefulBuilder(
              builder: (context, setDialogState) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(emojis.length, (index) {
                  final isSelected = selectedMood == index + 1;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedMood = index + 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF8A5A5).withOpacity(0.1) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? const Color(0xFFF8A5A5) : Colors.transparent, width: 2),
                      ),
                      child: Text(emojis[index], style: const TextStyle(fontSize: 32)),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 25),
            const Text('Flow:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            StatefulBuilder(
              builder: (context, setFlowState) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final isActive = index < selectedFlow;
                  return GestureDetector(
                    onTap: () => setFlowState(() {
                      selectedFlow = index + 1;
                    }),
                    child: Container(
                      width: 45,
                      height: 15,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFF8A5A5) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isActive ? const Color(0xFFF8A5A5).withOpacity(0.8) : Colors.transparent),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Add a note (optional)...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8A5A5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () async {
                  final success = await CycleService().addDailyLog(
                    logDate: DateTime.now().toIso8601String().split('T')[0],
                    feeling: textController.text.isEmpty ? 'Logged a mood' : textController.text,
                    moodScore: selectedMood,
                    flowLevel: selectedFlow > 0 ? selectedFlow : null,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Log saved successfully!' : 'Failed to log.'),
                        backgroundColor: success ? const Color(0xFFF8A5A5) : Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Save Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _showDatePicker(BuildContext context) async {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'When did your period start?',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.pink.shade300,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  void _loadCycleData() {
    final authRepo = DependencyInjection.authRepository as AuthRepositoryImpl;
    final token = authRepo.getToken();
    final userId = authRepo.userProfile['uid'] ?? 0;
    context.read<PeriodStatsBloc>().add(LoadPeriodStats(userId: userId, token: token));
    _loadCalendarData();
  }

  void _handleCalendarTap(BuildContext context, DateTime selectedDay) {
    DateTime today = DateTime.now();
    DateTime normalizedToday = DateTime(today.year, today.month, today.day);
    DateTime normalizedSelectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);

    if (normalizedSelectedDay.isAfter(normalizedToday)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot select future dates'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DateFormat('MMM dd, yyyy').format(selectedDay)),
        content: const Text('Would you like to start your period on this date?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade300),
            onPressed: () async {
              Navigator.pop(context); // Close confirmation
              final moodData = await _showMoodDialog(context);
              if (moodData != null) {
                final days = moodData['mensesLength'] as int? ?? 5;
                final success = await _cycleService.recordPeriod(
                  startDate: normalizedSelectedDay.toIso8601String().split('T')[0],
                  mensesLength: days,
                  moodScore: moodData['score'],
                  emotions: moodData['emotions'],
                  flowLevel: moodData['flowLevel'],
                );
                
                if (success) {
                  if (context.mounted) {
                    context.read<PeriodTrackingBloc>().add(const TogglePeriodSwitch(true));
                    context.read<PeriodTrackingBloc>().add(UpdatePeriodDuration(days));
                    context.read<PeriodTrackingBloc>().add(SetPeriodStartDate(normalizedSelectedDay));
                    _loadCycleData(); // Refresh UI and Stats
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Period and mood recorded!'), backgroundColor: Colors.green),
                    );
                  }
                }
              }
            },
            child: const Text('Start Period', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showMoodDialog(BuildContext context) async {
    int selectedScore = 3;
    int flowLevel = 3;
    int periodDays = 5; // User chooses; default 5 for picker only
    final List<String> symptoms = ['Cramps', 'Headache', 'Mood Swings', 'Fatigue', 'Bloating', 'Acne'];
    final List<String> selectedSymptoms = [];

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('How are you feeling today?', 
            style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('How many days does your period last?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
                const SizedBox(height: 8),
                StatefulBuilder(
                  builder: (context, setDaysState) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Days:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: periodDays.clamp(1, 10),
                        items: List.generate(10, (i) => i + 1).map((d) => DropdownMenuItem(value: d, child: Text('$d'))).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDaysState(() => periodDays = value);
                            setDialogState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Mood (1=Sad, 5=Happy)', style: TextStyle(fontSize: 14, color: Colors.grey)),
                Slider(
                  value: selectedScore.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: Colors.pink,
                  label: selectedScore.toString(),
                  onChanged: (value) => setDialogState(() => selectedScore = value.toInt()),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('😫'), Text('😐'), Text('😊')],
                ),
                const SizedBox(height: 25),
                const Text('Flow Level:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
                const SizedBox(height: 10),
                StatefulBuilder(
                  builder: (context, setFlowState) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final isActive = index < flowLevel;
                      return GestureDetector(
                        onTap: () => setFlowState(() {
                             flowLevel = index + 1;
                             setDialogState(() {}); // Sync with main state
                        }),
                        child: Container(
                          width: 40,
                          height: 20,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.pink.shade300 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isActive ? Colors.pink.shade400 : Colors.transparent),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Select up to 3 Symptoms:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: symptoms.map((symptom) {
                    final isSelected = selectedSymptoms.contains(symptom);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(symptom),
                      selectedColor: Colors.pink.shade100,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            if (selectedSymptoms.length < 3) selectedSymptoms.add(symptom);
                          } else {
                            selectedSymptoms.remove(symptom);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade300),
              onPressed: () => Navigator.pop(context, {
                'score': selectedScore, 
                'emotions': selectedSymptoms,
                'flowLevel': flowLevel,
                'mensesLength': periodDays,
              }),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
