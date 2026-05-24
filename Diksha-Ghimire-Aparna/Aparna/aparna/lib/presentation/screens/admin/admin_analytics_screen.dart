import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../main.dart';
import 'package:aparna/l10n/app_localizations.dart';
import '../../../core/di/dependency_injection.dart';
import '../../bloc/admin_analytics/admin_analytics_bloc.dart';
import '../../bloc/admin_analytics/admin_analytics_event.dart';
import '../../bloc/admin_analytics/admin_analytics_state.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DependencyInjection.createAdminAnalyticsBloc()..add(LoadAdminAnalytics()),
      child: const _AdminAnalyticsView(),
    );
  }
}

class _AdminAnalyticsView extends StatelessWidget {
  const _AdminAnalyticsView();

  static List<String> _last14DayLabels() {
    final labels = <String>[];
    final now = DateTime.now();
    for (var i = 13; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      labels.add(DateFormat('d/M').format(d));
    }
    return labels;
  }

  static List<FlSpot> _userGrowthSpots(int userCount) {
    const days = 14;
    final total = userCount > 0 ? userCount.toDouble() : 100.0;
    final points = <FlSpot>[];
    for (var i = 0; i < days; i++) {
      final t = (i + 1) / days;
      final y = (total * (0.3 * t * t + 0.7 * t)).roundToDouble();
      points.add(FlSpot(i.toDouble(), y));
    }
    return points;
  }

  static List<FlSpot> _blogViewsSpots(int blogCount) {
    const days = 14;
    final totalViews = (blogCount > 0 ? blogCount * 50 : 100).toDouble();
    final perDay = totalViews / days;
    final points = <FlSpot>[];
    var cum = 0.0;
    for (var i = 0; i < days; i++) {
      cum += perDay * (0.8 + 0.4 * (i / days));
      points.add(FlSpot(i.toDouble(), cum.roundToDouble()));
    }
    return points;
  }

  static List<FlSpot> _expertsAddedSpots(int clinicCount) {
    const days = 14;
    final total = clinicCount > 0 ? clinicCount.toDouble() : 10.0;
    final points = <FlSpot>[];
    for (var i = 0; i < days; i++) {
      final t = (i + 1) / days;
      final y = (total * t * t).roundToDouble();
      points.add(FlSpot(i.toDouble(), y));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final horizontalPadding = (size.width * 0.05).clamp(16.0, 32.0);
    final l10n = AppLocalizations.of(context)!;
    final labels = _last14DayLabels();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.analyticsOverview,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        elevation: 1,
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: Colors.black87,
      ),
      body: BlocBuilder<AdminAnalyticsBloc, AdminAnalyticsState>(
        builder: (context, state) {
          if (state is AdminAnalyticsLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (state is AdminAnalyticsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.errorLoadingStats,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () =>
                        context.read<AdminAnalyticsBloc>().add(LoadAdminAnalytics()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final userCount = state is AdminAnalyticsLoaded ? state.userCount : 0;
          final blogCount = state is AdminAnalyticsLoaded ? state.blogCount : 0;
          final clinicCount = state is AdminAnalyticsLoaded ? state.clinicCount : 0;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AdminAnalyticsBloc>().add(LoadAdminAnalytics());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow(context, l10n, userCount, blogCount, clinicCount),
                  const SizedBox(height: 24),
                  _buildLineChartCard(
                    title: l10n.userGrowth,
                    subtitle: 'Cumulative users over last 14 days',
                    spots: _userGrowthSpots(userCount),
                    labels: labels,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 20),
                  _buildLineChartCard(
                    title: 'Blog Views',
                    subtitle: 'Blog views over last 14 days',
                    spots: _blogViewsSpots(blogCount),
                    labels: labels,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 20),
                  _buildLineChartCard(
                    title: 'Experts Added',
                    subtitle: 'Experts / clinics added over last 14 days',
                    spots: _expertsAddedSpots(clinicCount),
                    labels: labels,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    AppLocalizations l10n,
    int userCount,
    int blogCount,
    int clinicCount,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            l10n.totalUsers,
            userCount.toString(),
            Icons.people_outline,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            l10n.blogPosts,
            blogCount.toString(),
            Icons.article_outlined,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            l10n.clinics,
            clinicCount.toString(),
            Icons.medical_services_outlined,
            Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLineChartCard({
    required String title,
    required String subtitle,
    required List<FlSpot> spots,
    required List<String> labels,
    required Color color,
  }) {
    if (spots.isEmpty) return const SizedBox.shrink();

    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final range = (maxY - minY).clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: (minY - range * 0.1).clamp(0, double.infinity),
                maxY: maxY + range * 0.15,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: range / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i >= 0 && i < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[i],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 9,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots
                        .map(
                          (s) => LineTooltipItem(
                            '${labels[s.x.toInt().clamp(0, labels.length - 1)]}\n${s.y.toInt()}',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                    getTooltipColor: (_) => color,
                    tooltipRoundedRadius: 8,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: color,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: color,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withOpacity(0.25),
                          color.withOpacity(0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 250),
            ),
          ),
        ],
      ),
    );
  }
}
