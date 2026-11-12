import 'dart:math' as math;

import '../models/daily_metrics.dart';
import 'formatters.dart';
import 'stats.dart';
import 'today_summary.dart';

enum PatternCategory { sleep, heart, activity }

/// "early" = seen, but on few days or with a small difference.
/// "consistent" = seen on enough days, with a clear difference.
/// Neither means proof of cause; the screen says so.
enum PatternStrength { early, consistent }

/// One side of a comparison, for example "nights in bed after 00:45".
class PatternGroup {
  const PatternGroup({
    required this.name,
    required this.average,
    required this.count,
  });

  final String name;
  final double average;
  final int count;
}

/// Something that tends to happen together in the user's own data.
class FoundPattern {
  const FoundPattern({
    required this.cause,
    required this.causeCategory,
    required this.effect,
    required this.effectCategory,
    required this.title,
    required this.highlight,
    required this.baseline,
    required this.strength,
    required this.countNoun,
    required this.format,
  });

  final String cause;
  final PatternCategory causeCategory;
  final String effect;
  final PatternCategory effectCategory;

  /// A plain description of what was seen, without claiming a cause.
  final String title;

  /// The group the pattern is about, for example late nights.
  final PatternGroup highlight;

  /// The group it is compared with, for example all other nights.
  final PatternGroup baseline;

  final PatternStrength strength;

  /// "nights" or "days", for "Based on 28 nights".
  final String countNoun;

  final String Function(double value) format;

  int get totalCount => highlight.count + baseline.count;

  bool involves(PatternCategory category) =>
      causeCategory == category || effectCategory == category;
}

/// Patterns based on fewer nights than this would mostly be luck.
const minimumNightsForPatterns = 14;

/// In bed after 00:45 counts as a late night (minutes after 18:00).
const lateBedtimeAfterEvening = 6 * 60 + 45;

bool isLateNight(DailyMetrics night) {
  final bedtime = night.bedtime;
  return bedtime != null && minutesAfterEvening(bedtime) > lateBedtimeAfterEvening;
}

int trackedNights(List<DailyMetrics> days) =>
    days.where((day) => day.sleepMinutes != null).length;

/// [days] newest first. Returns an empty list until there is enough data.
List<FoundPattern> findPatterns(List<DailyMetrics> days) {
  if (trackedNights(days) < minimumNightsForPatterns) return const [];
  return [
    _bedtimeAndSleep(days),
    _workoutAndDeepSleep(days),
    _weekdayAndHeartRate(days),
  ].whereType<FoundPattern>().toList();
}

PatternStrength _strength(int smallerGroup, double difference, double clear) =>
    smallerGroup >= 8 && difference >= clear
        ? PatternStrength.consistent
        : PatternStrength.early;

FoundPattern? _bedtimeAndSleep(List<DailyMetrics> days) {
  final late = <int>[];
  final early = <int>[];
  for (final night in days) {
    final sleep = night.sleepMinutes;
    if (night.bedtime == null || sleep == null) continue;
    (isLateNight(night) ? late : early).add(sleep);
  }
  if (late.length < 3 || early.length < 3) return null;

  final difference = mean(early) - mean(late);
  if (difference < 15) return null;

  return FoundPattern(
    cause: 'Bedtime',
    causeCategory: PatternCategory.sleep,
    effect: 'Sleep',
    effectCategory: PatternCategory.sleep,
    title: 'On late nights you slept ${formatHm(difference.round())} less',
    highlight: PatternGroup(
      name: 'In bed after 00:45',
      average: mean(late),
      count: late.length,
    ),
    baseline: PatternGroup(
      name: 'In bed before 00:45',
      average: mean(early),
      count: early.length,
    ),
    strength: _strength(math.min(late.length, early.length), difference, 20),
    countNoun: 'nights',
    format: (value) => formatHm(value.round()),
  );
}

FoundPattern? _workoutAndDeepSleep(List<DailyMetrics> days) {
  final afterWorkout = <int>[];
  final afterRest = <int>[];
  // days[i] is a night; days[i + 1] is the day before that night.
  for (var i = 0; i + 1 < days.length; i++) {
    final deep = days[i].sleepStages?.deep;
    if (deep == null) continue;
    (days[i + 1].hadWorkout ? afterWorkout : afterRest).add(deep);
  }
  if (afterWorkout.length < 3 || afterRest.length < 3) return null;

  final difference = mean(afterWorkout) - mean(afterRest);
  if (difference < 5) return null;

  return FoundPattern(
    cause: 'Workouts',
    causeCategory: PatternCategory.activity,
    effect: 'Deep sleep',
    effectCategory: PatternCategory.sleep,
    title: 'After workouts you got ${formatHm(difference.round())} '
        'more deep sleep',
    highlight: PatternGroup(
      name: 'After a workout day',
      average: mean(afterWorkout),
      count: afterWorkout.length,
    ),
    baseline: PatternGroup(
      name: 'After a rest day',
      average: mean(afterRest),
      count: afterRest.length,
    ),
    strength: _strength(
      math.min(afterWorkout.length, afterRest.length),
      difference,
      10,
    ),
    countNoun: 'nights',
    format: (value) => formatHm(value.round()),
  );
}

FoundPattern? _weekdayAndHeartRate(List<DailyMetrics> days) {
  final byWeekday = <int, List<int>>{};
  for (final day in days) {
    final rate = day.restingHeartRate;
    if (rate == null) continue;
    byWeekday.putIfAbsent(day.date.weekday, () => []).add(rate);
  }

  int? highestDay;
  var highestAverage = double.negativeInfinity;
  byWeekday.forEach((weekday, rates) {
    if (rates.length < 2) return;
    final average = mean(rates);
    if (average > highestAverage) {
      highestAverage = average;
      highestDay = weekday;
    }
  });
  final weekday = highestDay;
  if (weekday == null) return null;

  final others = [
    for (final entry in byWeekday.entries)
      if (entry.key != weekday) ...entry.value,
  ];
  if (others.length < 3) return null;

  final difference = highestAverage - mean(others);
  if (difference < 1.5) return null;

  final name = weekdayName(weekday);
  return FoundPattern(
    cause: '${name}s',
    causeCategory: PatternCategory.heart,
    effect: 'Resting HR',
    effectCategory: PatternCategory.heart,
    title: 'On ${name}s your resting HR was ${difference.round()} bpm higher',
    highlight: PatternGroup(
      name: '${name}s',
      average: highestAverage,
      count: byWeekday[weekday]!.length,
    ),
    baseline: PatternGroup(
      name: 'Other days',
      average: mean(others),
      count: others.length,
    ),
    strength: _strength(byWeekday[weekday]!.length, difference, 2),
    countNoun: 'days',
    format: (value) => '${value.round()} bpm',
  );
}
