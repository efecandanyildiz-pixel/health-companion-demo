import '../models/daily_metrics.dart';
import 'personal_range.dart';

/// Minutes after 18:00, so bedtimes like 23:50 and 00:20 sit next to each
/// other instead of being 23 hours apart.
int minutesAfterEvening(DateTime time) =>
    ((time.hour * 60 + time.minute) - 18 * 60) % (24 * 60);

/// Everything the Today screen needs, calculated once from the raw days.
///
/// All math happens here, in code. The AI coach will later receive these
/// results and only explain them in words.
class TodaySummary {
  const TodaySummary({
    required this.today,
    required this.yesterday,
    required this.lastNights,
    required this.sleep,
    required this.restingHeartRate,
    required this.heartRateVariability,
    required this.stepsSoFar,
    required this.activeZoneMinutes,
    required this.recentHrv,
    required this.recentActiveMinutes,
    this.usualBedtimeAfterEvening,
    this.bedtimeShiftMinutes,
  });

  /// [days] must be newest first: today, yesterday, then older days.
  ///
  /// Sleep and recovery come from last night. Steps so far are compared
  /// with what you usually have by this time of day. Active minutes come
  /// from yesterday, because today is not finished yet.
  factory TodaySummary.fromDays(List<DailyMetrics> days, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = days.first;
    final history = days.skip(1).toList();
    final yesterday = history.isEmpty ? null : history.first;
    final olderDays = history.skip(1).toList();

    final pastBedtimes = history
        .map((day) => day.bedtime)
        .whereType<DateTime>()
        .map(minutesAfterEvening)
        .toList();
    final usualBedtime = PersonalRange.tryFrom(pastBedtimes)?.median.round();
    final todayBedtime =
        today.bedtime == null ? null : minutesAfterEvening(today.bedtime!);

    return TodaySummary(
      today: today,
      yesterday: yesterday,
      lastNights: days.take(7).toList().reversed.toList(),
      sleep: MetricSignal.of(
        today.sleepMinutes,
        history.map((day) => day.sleepMinutes),
      ),
      restingHeartRate: MetricSignal.of(
        today.restingHeartRate,
        history.map((day) => day.restingHeartRate),
      ),
      heartRateVariability: MetricSignal.of(
        today.heartRateVariability,
        history.map((day) => day.heartRateVariability),
      ),
      stepsSoFar: MetricSignal.of(
        today.steps,
        history.map((day) => day.stepsUntil(current.hour, current.minute)),
      ),
      activeZoneMinutes: MetricSignal.of(
        yesterday?.activeZoneMinutes,
        olderDays.map((day) => day.activeZoneMinutes),
      ),
      recentHrv: days
          .take(7)
          .toList()
          .reversed
          .map((day) => day.heartRateVariability)
          .toList(),
      recentActiveMinutes: history
          .take(7)
          .toList()
          .reversed
          .map((day) => day.activeZoneMinutes)
          .toList(),
      usualBedtimeAfterEvening: usualBedtime,
      bedtimeShiftMinutes: usualBedtime == null || todayBedtime == null
          ? null
          : todayBedtime - usualBedtime,
    );
  }

  final DailyMetrics today;
  final DailyMetrics? yesterday;

  /// Up to 7 nights, oldest first, ending with last night.
  final List<DailyMetrics> lastNights;

  final MetricSignal sleep;
  final MetricSignal restingHeartRate;
  final MetricSignal heartRateVariability;

  /// Steps so far today, against your usual steps by this time.
  final MetricSignal stepsSoFar;

  /// Yesterday's active zone minutes.
  final MetricSignal activeZoneMinutes;

  /// HRV of the last 7 nights, oldest first.
  final List<int?> recentHrv;

  /// Active minutes of the last 7 full days, oldest first (ends yesterday).
  final List<int?> recentActiveMinutes;

  /// The user's usual bedtime, as minutes after 18:00.
  final int? usualBedtimeAfterEvening;

  /// Positive when the user went to bed later than usual.
  final int? bedtimeShiftMinutes;
}
