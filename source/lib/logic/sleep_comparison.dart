import '../models/daily_metrics.dart';
import 'formatters.dart';
import 'personal_range.dart';
import 'stats.dart';
import 'today_summary.dart';

/// One row of the "This week vs your usual" table.
class ComparisonRow {
  const ComparisonRow({
    required this.label,
    required this.current,
    required this.usual,
    required this.outsideUsual,
  });

  final String label;
  final String current;
  final String usual;

  /// True when this week is outside the usual range; the screen highlights it.
  final bool outsideUsual;
}

/// Compares the last 7 nights with the user's usual (the previous 28 days).
/// [days] newest first.
List<ComparisonRow> compareSleepWeek(List<DailyMetrics> days) {
  final week = days.take(7).toList();
  final history = days.skip(1).toList();
  final rows = <ComparisonRow>[];

  final weekSleep = presentValues(week.map((d) => d.sleepMinutes));
  final sleepRange = PersonalRange.tryFrom(history.map((d) => d.sleepMinutes));
  if (weekSleep.isNotEmpty && sleepRange != null) {
    final average = mean(weekSleep);
    rows.add(
      ComparisonRow(
        label: 'Time asleep',
        current: formatHm(average.round()),
        usual: formatHm(sleepRange.median.round()),
        outsideUsual: sleepRange.statusOf(average) != RangeStatus.within,
      ),
    );
  }

  List<int> bedtimes(List<DailyMetrics> nights) => nights
      .map((d) => d.bedtime)
      .whereType<DateTime>()
      .map(minutesAfterEvening)
      .toList();
  final weekBedtimes = bedtimes(week);
  final pastBedtimes = bedtimes(history);
  final bedtimeRange = PersonalRange.tryFrom(pastBedtimes);
  if (weekBedtimes.isNotEmpty && bedtimeRange != null) {
    final average = mean(weekBedtimes);
    rows.add(
      ComparisonRow(
        label: 'Bedtime',
        current: formatClock(average.round() + 18 * 60),
        usual: formatClock(bedtimeRange.median.round() + 18 * 60),
        outsideUsual: (average - bedtimeRange.median).abs() >= 30,
      ),
    );
  }

  final weekDeep = presentValues(week.map((d) => d.sleepStages?.deep));
  final deepRange =
      PersonalRange.tryFrom(history.map((d) => d.sleepStages?.deep));
  if (weekDeep.isNotEmpty && deepRange != null) {
    final average = mean(weekDeep);
    rows.add(
      ComparisonRow(
        label: 'Deep sleep',
        current: formatHm(average.round()),
        usual: formatHm(deepRange.median.round()),
        outsideUsual: deepRange.statusOf(average) != RangeStatus.within,
      ),
    );
  }

  if (weekBedtimes.length >= 2 && pastBedtimes.length >= 7) {
    final weekSpread = meanAbsoluteDeviation(weekBedtimes);
    final usualSpread = meanAbsoluteDeviation(pastBedtimes);
    rows.add(
      ComparisonRow(
        label: 'Bedtime shift',
        current: '± ${weekSpread.round()} min',
        usual: '± ${usualSpread.round()} min',
        outsideUsual: weekSpread > usualSpread + 15,
      ),
    );
  }

  return rows;
}
