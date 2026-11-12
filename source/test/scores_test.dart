import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:health_companion/data/fake_health_repository.dart';
import 'package:health_companion/logic/formatters.dart';
import 'package:health_companion/logic/scores.dart';
import 'package:health_companion/models/daily_metrics.dart';

final now = DateTime(2026, 11, 10, 14, 0);
final sampleDays = const FakeHealthRepository().recentDays(now: now);

/// Today first, then [history] older days. Sleep is light-only minutes.
List<DailyMetrics> days({
  required (int? hrv, int? rhr, int? sleep, int? active, int steps) today,
  required List<(int? hrv, int? rhr, int? sleep, int? active, int steps)> history,
}) {
  DailyMetrics day(int daysAgo, (int?, int?, int?, int?, int) v) => DailyMetrics(
        date: DateTime(2026, 11, 10).subtract(Duration(days: daysAgo)),
        heartRateVariability: v.$1,
        restingHeartRate: v.$2,
        sleepStages: v.$3 == null
            ? null
            : SleepStages(deep: 0, light: v.$3!, rem: 0, awake: 0),
        activeZoneMinutes: v.$4,
        stepsByHour: [v.$5],
      );
  return [day(0, today), for (var i = 0; i < history.length; i++) day(i + 1, history[i])];
}

/// Alternates between two values, so the average is the middle and the
/// standard deviation is half the gap.
List<(int?, int?, int?, int?, int)> alternating(int n) => [
      for (var i = 0; i < n; i++)
        i.isEven ? (40, 60, 400, 20, 8000) : (60, 50, 440, 40, 12000),
    ];

void main() {
  test('zScore', () {
    expect(zScore(60, [40, 60]), closeTo(1, 1e-9));
    expect(zScore(5, [5, 5, 5]), 0);
    expect(zScore(5, []), 0);
  });

  test('score levels', () {
    expect(scoreLevelOf(67), ScoreLevel.high);
    expect(scoreLevelOf(66), ScoreLevel.mid);
    expect(scoreLevelOf(34), ScoreLevel.mid);
    expect(scoreLevelOf(33), ScoreLevel.low);
  });

  group('Recovery', () {
    test('a normal day is 50', () {
      final r = RecoveryScore.fromDays(
        days(today: (50, 55, 420, 30, 10000), history: alternating(28)),
      )!;
      expect(r.score, 50);
      expect(r.reason, 'Close to your normal');
    });

    test('weights HRV 0.45, resting HR 0.25 (lower is better), sleep 0.30', () {
      // z HRV = +1, z RHR = -1 (so +1 after flipping), z sleep = +1.
      final r = RecoveryScore.fromDays(
        days(today: (60, 50, 440, 30, 10000), history: alternating(28)),
      )!;
      expect(r.score, 70);
      final points = {for (final c in r.contributions) c.factor: c.points};
      expect(points[RecoveryFactor.hrv], closeTo(9, 1e-9));
      expect(points[RecoveryFactor.restingHeartRate], closeTo(5, 1e-9));
      expect(points[RecoveryFactor.sleep], closeTo(6, 1e-9));
      expect(r.reason, 'HRV above your normal');
    });

    test('without HRV uses resting HR 0.45 and sleep 0.55', () {
      final r = RecoveryScore.fromDays(
        days(today: (null, 60, 400, 30, 10000), history: alternating(28)),
      )!;
      // 50 + 20 × (0.45 × −1 + 0.55 × −1) = 30
      expect(r.score, 30);
      expect(r.contributions.map((c) => c.weight), [0.45, 0.55]);
      expect(r.level, ScoreLevel.low);
    });

    test('stays between 0 and 100, and only uses 28 past days', () {
      final low = RecoveryScore.fromDays(
        days(today: (10, 90, 100, 30, 10000), history: alternating(40)),
      )!;
      expect(low.score, 0);
      expect(RecoveryScore.fromDays(days(today: (null, null, null, 0, 0), history: [])), isNull);
    });

    test('on the sample data, last night was a hard one', () {
      final r = RecoveryScore.fromDays(sampleDays)!;
      expect(scoreLevelOf(r.score), ScoreLevel.low);
      expect(r.score, greaterThan(0));
      expect(r.reason, 'HRV below your normal');
      expect(r.contributions.every((c) => c.points < 0), isTrue);
    });
  });

  group('Effort', () {
    test('a usual day gives 50, twice the usual gives 75', () {
      final history = [for (var i = 0; i < 28; i++) (50, 55, 420, 30, 10000)];
      final usual = EffortScore.fromDays(days(today: (50, 55, 420, 30, 0), history: history))!;
      expect(usual.score, 50);
      expect(usual.reason, 'About your usual day');
      final double = EffortScore.fromDays(days(today: (50, 55, 420, 60, 0), history: history))!;
      expect(double.score, 75);
    });

    test('uses steps ÷ 100 for both the day and the usual when active minutes are missing', () {
      final history = [for (var i = 0; i < 28; i++) (50, 55, 420, 30, 10000)];
      final e = EffortScore.fromDays(days(today: (50, 55, 420, null, 5000), history: history))!;
      expect(e.usesSteps, isTrue);
      expect(e.load, 50);
      expect(e.usualLoad, 100);
      expect(e.score, (100 * (1 - math.exp(-math.ln2 * 0.5))).round());
      expect(e.reason, 'Steps below your usual so far');
    });

    test('falls back to a usual of 120 without history', () {
      final e = EffortScore.fromDays(days(today: (50, 55, 420, 120, 0), history: []))!;
      expect(e.usualLoad, fallbackUsualLoad);
      expect(e.score, 50);
    });
  });

  test('Sleep performance is asleep ÷ need, capped at 100', () {
    final short = SleepPerformance.fromDays(days(today: (50, 55, 360, 30, 0), history: []))!;
    expect(short.percent, 75);
    expect(short.reason, '${formatHm(360)} of your ${formatHm(480)} need');
    final long = SleepPerformance.fromDays(days(today: (50, 55, 600, 30, 0), history: []))!;
    expect(long.percent, 100);
    expect(SleepPerformance.fromDays(days(today: (50, 55, null, 30, 0), history: [])), isNull);
  });

  group('dailyBriefing', () {
    test('mentions recovery and a short night', () {
      final text = dailyBriefing(DailyScores.fromDays(sampleDays));
      expect(text, startsWith('Your body is still catching up.'));
      expect(text, contains('78% of your sleep need'));
    });

    test('a good day with enough sleep is one sentence', () {
      final text = dailyBriefing(DailyScores.fromDays(
        days(today: (60, 50, 440, 30, 10000), history: alternating(28)),
      ));
      expect(text, 'You are well recovered today. A good day to push a little harder.');
    });

    test('says so without data', () {
      expect(dailyBriefing(const DailyScores()), startsWith('Not enough data'));
    });
  });
}
