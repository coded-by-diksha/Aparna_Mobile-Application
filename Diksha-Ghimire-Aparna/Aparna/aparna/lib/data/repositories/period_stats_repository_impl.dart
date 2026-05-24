import '../../domain/entities/period_stats_entity.dart';
import '../../domain/repositories/period_stats_repository.dart';
import '../models/period_stats_model.dart';
import '../services/cycle_service.dart';
import 'package:intl/intl.dart';

class PeriodStatsRepositoryImpl implements PeriodStatsRepository {
  final CycleService _cycleService = CycleService();

  @override
  Future<PeriodStatsEntity> getPeriodStats(int userId, String token) async {
    try {
      final history = await _cycleService.fetchHistory();
      
      // Bar chart: show cycle_length (days between period starts), not menses_length
      List<MonthStatModel> monthlyStats = [];
      final sortedHistory = List.from(history)..sort((a, b) =>
          DateTime.parse(a['period_start_date']).compareTo(DateTime.parse(b['period_start_date']))
      );

      // Only rows with cycle_length (oldest has null); take last 7
      final withCycleLength = sortedHistory
          .where((c) => c['cycle_length'] != null)
          .toList();
      final recentHistory = withCycleLength.length > 7
          ? withCycleLength.sublist(withCycleLength.length - 7)
          : withCycleLength;

      for (var cycle in recentHistory) {
        final date = DateTime.parse(cycle['period_start_date']);
        final cycleLengthRaw = cycle['cycle_length'];
        final days = cycleLengthRaw is num
            ? cycleLengthRaw.toInt()
            : int.tryParse(cycleLengthRaw?.toString() ?? '0') ?? 0;
        monthlyStats.add(MonthStatModel(
          month: DateFormat('MMM').format(date),
          days: days,
        ));
      }

      // Period pattern: days from prev period_start_date to new period_start_date (aligns with backend cycle_length)
      final patternList = <PeriodPatternModel>[];
      for (int i = 0; i < sortedHistory.length - 1; i++) {
        final prevStart = DateTime.parse(sortedHistory[i]['period_start_date'] as String);
        final newStart = DateTime.parse(sortedHistory[i + 1]['period_start_date'] as String);
        final cycleLengthRaw = sortedHistory[i + 1]['cycle_length'];
        final daysBetween = cycleLengthRaw != null
            ? (cycleLengthRaw is num ? cycleLengthRaw.toInt() : int.tryParse(cycleLengthRaw.toString()) ?? newStart.difference(prevStart).inDays)
            : newStart.difference(prevStart).inDays;
        patternList.add(PeriodPatternModel(
          fromDate: sortedHistory[i]['period_start_date'] as String,
          toDate: sortedHistory[i + 1]['period_start_date'] as String,
          days: daysBetween,
        ));
      }
      // Show most recent patterns first (reverse so newest gap is first)
      patternList.sort((a, b) => b.toDate.compareTo(a.toDate));

      if (monthlyStats.isEmpty && patternList.isEmpty) {
        return PeriodStatsModel(monthlyStats: []).toEntity();
      }

      return PeriodStatsModel(
        monthlyStats: monthlyStats,
        periodPatterns: patternList,
      ).toEntity();
    } catch (e) {
      print('Error in PeriodStatsRepositoryImpl: $e');
      return PeriodStatsModel(monthlyStats: []).toEntity();
    }
  }
}
