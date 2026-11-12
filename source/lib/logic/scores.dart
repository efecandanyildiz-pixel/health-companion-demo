/// The three daily scores at the top of Today: Recovery, Effort and Sleep.
///
/// Every score is a short, open formula on the user's own data, so the app
/// can always show how a number was made.
library;

import 'dart:math' as math;

import '../models/daily_metrics.dart';
import 'formatters.dart';
import 'stats.dart';

/// How many past days count as "your normal".
const scoreHistoryDays = 28;

/// Default sleep need, in minutes (8 hours).
const defaultSleepNeedMinutes = 8 * 60;

/// Effort's usual daily load when there is no history yet.
const fallbackUsualLoad = 120.0;

/// Low, middle or high, for the colour of a score.
enum ScoreLevel { low, mid, high }

/// 67 and up is high, 34 to 66 is middle, below 34 is low.
ScoreLevel scoreLevelOf(int score) {
  if (score >= 67) return ScoreLevel.high;
  if (score >= 34) return ScoreLevel.mid;
  return ScoreLevel.low;
}

/// How far [value] is from the average of [history], in standard
/// deviations. 0 when the history is empty or never changes.
double zScore(num value, List<num> history) {
  if (history.isEmpty) return 0;
  final average = mean(history);
  final variance = mean(history.map((v) => (v - average) * (v - average)));
  if (variance <= 0) return 0;
  return (value - average) / math.sqrt(variance);
}

enum RecoveryFactor { hrv, restingHeartRate, sleep }

extension RecoveryFactorLabel on RecoveryFactor {
  String get label => switch (this) {
        RecoveryFactor.hrv => 'HRV',
        RecoveryFactor.restingHeartRate => 'Resting HR',
        RecoveryFactor.sleep => 'Sleep',
      };
}

/// One part of the recovery score.
class RecoveryContribution {
  const RecoveryContribution({
    required this.factor,
    required this.z,
    required this.weight,
  });

  final RecoveryFactor factor;

  /// "Better than usual" is positive. For resting HR the sign is already
  /// flipped, because a lower resting HR is better.
  final double z;
  final double weight;

  /// Points this part adds to (or takes from) the base of 50.
  double get points => 20 * weight * z;

  /// For example "HRV below your normal".
  String get reason {
    final better = z >= 0;
    return switch (factor) {
      RecoveryFactor.hrv => better ? 'HRV above your normal' : 'HRV below your normal',
      RecoveryFactor.restingHeartRate =>
        better ? 'Resting HR below your normal' : 'Resting HR above your normal',
      RecoveryFactor.sleep => better ? 'Slept more than usual' : 'Slept less than usual',
    };
  }
}

/// Recovery from 0 to 100: 50 is a normal day for you.
class RecoveryScore {
  const RecoveryScore({required this.score, required this.contributions});

  /// Recovery = 50 + 20 × (0.45·z HRV + 0.25·z resting HR + 0.30·z sleep),
  /// kept between 0 and 100. Each z compares last night with the previous
  /// [scoreHistoryDays] days. Without HRV the weights become resting HR 0.45
  /// and sleep 0.55. If another value is missing, the weights left are
  /// scaled up so they still add up to 1. Null when nothing was measured.
  static RecoveryScore? fromDays(List<DailyMetrics> days) {
    if (days.isEmpty) return null;
    final today = days.first;
    final history = days.skip(1).take(scoreHistoryDays).toList();

    final hrv = today.heartRateVariability;
    final rhr = today.restingHeartRate;
    final sleep = today.sleepMinutes;

    final weights = <RecoveryFactor, double>{
      if (hrv != null) RecoveryFactor.hrv: 0.45,
      if (rhr != null) RecoveryFactor.restingHeartRate: hrv == null ? 0.45 : 0.25,
      if (sleep != null) RecoveryFactor.sleep: hrv == null ? 0.55 : 0.30,
    };
    if (weights.isEmpty) return null;
    final total = weights.values.fold<double>(0, (a, b) => a + b);

    double z(RecoveryFactor factor) => switch (factor) {
          RecoveryFactor.hrv =>
            zScore(hrv!, presentValues(history.map((d) => d.heartRateVariability))),
          RecoveryFactor.restingHeartRate =>
            -zScore(rhr!, presentValues(history.map((d) => d.restingHeartRate))),
          RecoveryFactor.sleep =>
            zScore(sleep!, presentValues(history.map((d) => d.sleepMinutes))),
        };

    final contributions = [
      for (final entry in weights.entries)
        RecoveryContribution(
          factor: entry.key,
          z: z(entry.key),
          weight: entry.value / total,
        ),
    ];
    final points = contributions.fold<double>(0, (a, c) => a + c.points);
    return RecoveryScore(
      score: (50 + points).round().clamp(0, 100),
      contributions: contributions,
    );
  }

  final int score;
  final List<RecoveryContribution> contributions;

  ScoreLevel get level => scoreLevelOf(score);

  /// The part that moved the score the most, in plain words.
  String get reason {
    if (contributions.every((c) => c.points.abs() < 2)) {
      return 'Close to your normal';
    }
    final biggest = contributions.reduce(
      (a, b) => a.points.abs() >= b.points.abs() ? a : b,
    );
    return biggest.reason;
  }
}

/// Effort from 0 to 100: a usual day for you gives 50.
class EffortScore {
  const EffortScore({
    required this.score,
    required this.load,
    required this.usualLoad,
    required this.usesSteps,
  });

  /// Effort = 100 × (1 − e^(−ln2 × L / usual L)).
  ///
  /// L is the day's active minutes. When the day has no active minutes,
  /// L is steps ÷ 100, and the usual is worked out the same way so both
  /// are in the same unit. The usual is the median of the previous
  /// [scoreHistoryDays] days, or [fallbackUsualLoad] without history.
  static EffortScore? fromDays(List<DailyMetrics> days) {
    if (days.isEmpty) return null;
    final today = days.first;
    final usesSteps = today.activeZoneMinutes == null;
    double? loadOf(DailyMetrics day) => usesSteps
        ? (day.steps == null ? null : day.steps! / 100)
        : day.activeZoneMinutes?.toDouble();

    final load = loadOf(today);
    if (load == null) return null;
    final history = days
        .skip(1)
        .take(scoreHistoryDays)
        .map(loadOf)
        .whereType<double>()
        .toList();
    final median = _median(history);
    final usual = median == null || median <= 0 ? fallbackUsualLoad : median;
    final score = 100 * (1 - math.exp(-math.ln2 * load / usual));
    return EffortScore(
      score: score.round().clamp(0, 100),
      load: load,
      usualLoad: usual,
      usesSteps: usesSteps,
    );
  }

  final int score;
  final double load;
  final double usualLoad;

  /// True when [load] comes from steps instead of active minutes.
  final bool usesSteps;

  ScoreLevel get level => scoreLevelOf(score);

  String get reason {
    final ratio = load / usualLoad;
    final what = usesSteps ? 'Steps' : 'Active minutes';
    if (ratio >= 1.2) return '$what above your usual';
    if (ratio <= 0.8) return '$what below your usual so far';
    return 'About your usual day';
  }
}

/// Minutes asleep as a share of your sleep need, up to 100%.
class SleepPerformance {
  const SleepPerformance({
    required this.percent,
    required this.asleepMinutes,
    required this.needMinutes,
  });

  static SleepPerformance? fromDays(
    List<DailyMetrics> days, {
    int needMinutes = defaultSleepNeedMinutes,
  }) {
    final asleep = days.isEmpty ? null : days.first.sleepMinutes;
    if (asleep == null || needMinutes <= 0) return null;
    return SleepPerformance(
      percent: (asleep * 100 / needMinutes).round().clamp(0, 100),
      asleepMinutes: asleep,
      needMinutes: needMinutes,
    );
  }

  final int percent;
  final int asleepMinutes;
  final int needMinutes;

  ScoreLevel get level => scoreLevelOf(percent);

  /// For example "6 h 22 of your 8 h 00 need".
  String get reason =>
      '${formatHm(asleepMinutes)} of your ${formatHm(needMinutes)} need';
}

/// All three scores for the newest day in [days] (newest first).
class DailyScores {
  const DailyScores({this.recovery, this.effort, this.sleep});

  factory DailyScores.fromDays(List<DailyMetrics> days) => DailyScores(
        recovery: RecoveryScore.fromDays(days),
        effort: EffortScore.fromDays(days),
        sleep: SleepPerformance.fromDays(days),
      );

  final RecoveryScore? recovery;
  final EffortScore? effort;
  final SleepPerformance? sleep;
}

double? _median(List<double> values) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) / 2;
}

/// One or two plain sentences about today, from the three scores. Shown
/// as the coach's note under the rings.
String dailyBriefing(DailyScores scores) {
  final recovery = scores.recovery;
  if (recovery == null) {
    return 'Not enough data for a briefing yet. Keep wearing your Fitbit Air.';
  }
  final first = switch (recovery.level) {
    ScoreLevel.high => 'You are well recovered today. A good day to push a little harder.',
    ScoreLevel.mid => 'Your recovery is close to your normal. A steady day suits you.',
    ScoreLevel.low => 'Your body is still catching up. Keep today light.',
  };

  final sleep = scores.sleep;
  final effort = scores.effort;
  String? second;
  if (sleep != null && sleep.percent < 85) {
    second = 'Last night covered ${sleep.percent}% of your sleep need, '
        'so an earlier bedtime would help.';
  } else if (effort != null &&
      recovery.level != ScoreLevel.low &&
      effort.load < effort.usualLoad * 0.8) {
    second = 'You are behind your usual activity so far. A walk would help.';
  }
  return second == null ? first : '$first $second';
}
