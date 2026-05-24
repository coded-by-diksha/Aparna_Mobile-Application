import '../../domain/entities/period_stats_entity.dart';

class PeriodStatsModel {
  final List<MonthStatModel> monthlyStats;
  final List<PeriodPatternModel> periodPatterns;

  PeriodStatsModel({
    required this.monthlyStats,
    this.periodPatterns = const [],
  });

  factory PeriodStatsModel.fromJson(Map<String, dynamic> json) {
    return PeriodStatsModel(
      monthlyStats: (json['monthlyStats'] as List?)
              ?.map((e) => MonthStatModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      periodPatterns: (json['periodPatterns'] as List?)
              ?.map((e) => PeriodPatternModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  PeriodStatsEntity toEntity() {
    return PeriodStatsEntity(
      monthlyStats: monthlyStats.map((stat) => stat.toEntity()).toList(),
      periodPatterns: periodPatterns.map((p) => p.toEntity()).toList(),
    );
  }

  // Generate random stats for demo
  factory PeriodStatsModel.generateRandom() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    final currentMonthIndex = now.month - 1;
    
    // Generate stats for last 7 months
    List<MonthStatModel> stats = [];
    for (int i = 6; i >= 0; i--) {
      int monthIndex = (currentMonthIndex - i) % 12;
      if (monthIndex < 0) monthIndex += 12;
      
      // Generate realistic period days (typically 3-7 days)
      int days = 3 + (i * 3 + monthIndex) % 5; // Varies between 3-7 days
      
      stats.add(MonthStatModel(
        month: months[monthIndex],
        days: days,
      ));
    }
    
    return PeriodStatsModel(monthlyStats: stats);
  }
}

class MonthStatModel {
  final String month;
  final int days;

  MonthStatModel({required this.month, required this.days});

  factory MonthStatModel.fromJson(Map<String, dynamic> json) {
    return MonthStatModel(
      month: json['month'] as String,
      days: json['days'] as int,
    );
  }

  MonthStat toEntity() {
    return MonthStat(month: month, days: days);
  }
}

class PeriodPatternModel {
  final String fromDate;
  final String toDate;
  final int days;

  PeriodPatternModel({
    required this.fromDate,
    required this.toDate,
    required this.days,
  });

  factory PeriodPatternModel.fromJson(Map<String, dynamic> json) {
    return PeriodPatternModel(
      fromDate: json['fromDate'] as String,
      toDate: json['toDate'] as String,
      days: json['days'] as int,
    );
  }

  PeriodPattern toEntity() {
    return PeriodPattern(
      fromDate: fromDate,
      toDate: toDate,
      days: days,
    );
  }
}
