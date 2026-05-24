class PeriodStatsEntity {
  final List<MonthStat> monthlyStats;
  final List<PeriodPattern>? _periodPatterns;

  PeriodStatsEntity({
    required this.monthlyStats,
    List<PeriodPattern>? periodPatterns,
  }) : _periodPatterns = periodPatterns;

  List<PeriodPattern> get periodPatterns => _periodPatterns ?? const [];
}

class MonthStat {
  final String month;
  final int days;

  MonthStat({required this.month, required this.days});
}

/// Days between consecutive period starts
class PeriodPattern {
  final String fromDate;
  final String toDate;
  final int days;

  PeriodPattern({
    required this.fromDate,
    required this.toDate,
    required this.days,
  });
}
