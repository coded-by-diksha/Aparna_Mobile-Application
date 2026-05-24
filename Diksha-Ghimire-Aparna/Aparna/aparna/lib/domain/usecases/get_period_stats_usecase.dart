import '../entities/period_stats_entity.dart';
import '../repositories/period_stats_repository.dart';

class GetPeriodStatsUseCase {
  final PeriodStatsRepository repository;

  GetPeriodStatsUseCase(this.repository);

  Future<PeriodStatsEntity> call(int userId, String token) async {
    return await repository.getPeriodStats(userId, token);
  }
}
