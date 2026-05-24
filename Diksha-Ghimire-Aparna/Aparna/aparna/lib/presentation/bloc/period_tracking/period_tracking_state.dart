import 'package:equatable/equatable.dart';

class PeriodTrackingState extends Equatable {
  final bool periodSwitchValue;
  final int periodDurationDays;
  final DateTime? periodStartDate;
  final Set<DateTime> periodDays;
  final Map<DateTime, String> flowLevels;
  final Map<DateTime, List<String>> symptoms;
  final Map<DateTime, String> moods;
  final Map<DateTime, double> weights;
  final bool isLoading;
  final String? errorMessage;

  const PeriodTrackingState({
    this.periodSwitchValue = false,
    this.periodDurationDays = 5,
    this.periodStartDate,
    this.periodDays = const {},
    this.flowLevels = const {},
    this.symptoms = const {},
    this.moods = const {},
    this.weights = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  PeriodTrackingState copyWith({
    bool? periodSwitchValue,
    int? periodDurationDays,
    DateTime? periodStartDate,
    Set<DateTime>? periodDays,
    Map<DateTime, String>? flowLevels,
    Map<DateTime, List<String>>? symptoms,
    Map<DateTime, String>? moods,
    Map<DateTime, double>? weights,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PeriodTrackingState(
      periodSwitchValue: periodSwitchValue ?? this.periodSwitchValue,
      periodDurationDays: periodDurationDays ?? this.periodDurationDays,
      periodStartDate: periodStartDate ?? this.periodStartDate,
      periodDays: periodDays ?? this.periodDays,
      flowLevels: flowLevels ?? this.flowLevels,
      symptoms: symptoms ?? this.symptoms,
      moods: moods ?? this.moods,
      weights: weights ?? this.weights,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        periodSwitchValue,
        periodDurationDays,
        periodStartDate,
        periodDays,
        flowLevels,
        symptoms,
        moods,
        weights,
        isLoading,
        errorMessage,
      ];

  // Helper methods
  Set<DateTime> getPeriodDays(DateTime startDate) {
    DateTime normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    return Set.from(List.generate(periodDurationDays, (i) => DateTime(
      normalizedStart.year,
      normalizedStart.month,
      normalizedStart.day + i,
    )));
  }

  bool isPredictedPeriod(DateTime day) {
    if (periodStartDate == null) return false;
    DateTime nextPeriodStart = periodStartDate!.add(Duration(days: 28));
    return day.isAfter(nextPeriodStart.subtract(Duration(days: 1))) && 
           day.isBefore(nextPeriodStart.add(Duration(days: periodDurationDays)));
  }

  bool isFertileDay(DateTime day) {
    if (periodStartDate == null) return false;
    int dayOfCycle = day.difference(periodStartDate!).inDays + 1;
    return dayOfCycle >= 10 && dayOfCycle <= 17;
  }

  bool isOvulationDay(DateTime day) {
    if (periodStartDate == null) return false;
    int dayOfCycle = day.difference(periodStartDate!).inDays + 1;
    return dayOfCycle == 14;
  }

  String getFlowLevel(DateTime day) {
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    return flowLevels[normalizedDay] ?? 'Medium';
  }

  List<String> getSymptoms(DateTime day) {
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    return symptoms[normalizedDay] ?? [];
  }

  String getMood(DateTime day) {
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    return moods[normalizedDay] ?? '';
  }

  double? getWeight(DateTime day) {
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    return weights[normalizedDay];
  }
}
