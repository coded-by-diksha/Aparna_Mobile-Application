import '../entities/period_stats_entity.dart';

abstract class PeriodStatsRepository {
  Future<PeriodStatsEntity> getPeriodStats(int userId, String token);
}
