import 'package:flutter_test/flutter_test.dart';

import 'package:health_companion/data/fake_health_repository.dart';
import 'package:health_companion/logic/coach_answers.dart';
import 'package:health_companion/logic/experiment.dart';
import 'package:health_companion/logic/formatters.dart';
import 'package:health_companion/logic/gauge_reading.dart';
import 'package:health_companion/logic/going_well.dart';
import 'package:health_companion/logic/patterns.dart';
import 'package:health_companion/logic/personal_range.dart';
import 'package:health_companion/logic/sleep_comparison.dart';
import 'package:health_companion/logic/today_summary.dart';
import 'package:health_companion/models/daily_metrics.dart';

const nbsp = ' ';
final now = DateTime(2026, 11, 10, 14, 0);
final sampleDays = const FakeHealthRepository().recentDays(now: now);

/// Builds [count] nights ending on 10 Nov, newest first.
List<DailyMetrics> nights(
  int count, {
  required int Function(int daysAgo) bedtimeMinutes,
  required int Function(int daysAgo) sleepMinutes,
  bool Function(int daysAgo)? workout,
  int Function(int daysAgo)? deep,
}) {
  return [
    for (var daysAgo = 0; daysAgo < count; daysAgo++)
      () {
        final date = DateTime(2026, 11, 10).subtract(Duration(days: daysAgo));
        final asleep = sleepMinutes(daysAgo);
        final deepMinutes = deep?.call(daysAgo) ?? 90;
        return DailyMetrics(
          date: date,
          bedtime: date.add(Duration(minutes: bedtimeMinutes(daysAgo))),
          sleepStages: SleepStages(
            deep: deepMinutes,
            light: asleep - deepMinutes - 90,
            rem: 90,
            awake: 10,
          ),
          restingHeartRate: 58,
          workoutMinutes: workout?.call(daysAgo) ?? false ? 45 : 0,
        );
      }(),
  ];
}

void main() {
  group('PersonalRange', () {
    final values = List.generate(11, (i) => i + 1); // 1..11

    test('uses the middle 70% of past values as normal', () {
      final range = PersonalRange.tryFrom(values)!;
      expect(range.median, 6);
      expect(range.low, closeTo(2.5, 0.001));
      expect(range.high, closeTo(9.5, 0.001));
    });

    test('classifies a value below, within or above normal', () {
      final range = PersonalRange.tryFrom(values)!;
      expect(range.statusOf(1), RangeStatus.below);
      expect(range.statusOf(6), RangeStatus.within);
      expect(range.statusOf(11), RangeStatus.above);
    });

    test('needs at least 7 days and skips missing values', () {
      expect(PersonalRange.tryFrom([1, 2, 3, null, null, 4, 5, 6]), isNull);
      expect(PersonalRange.tryFrom([1, 2, 3, null, 4, 5, 6, 7]), isNotNull);
    });
  });

  group('DailyMetrics', () {
    test('counts steps up to a time of day', () {
      final day = DailyMetrics(
        date: DateTime(2026, 11, 10),
        stepsByHour: [for (var h = 0; h < 24; h++) 100],
      );
      expect(day.steps, 2400);
      expect(day.stepsUntil(14, 0), 1400);
      expect(day.stepsUntil(14, 30), 1450);
    });
  });

  group('GaugeReading', () {
    const range = PersonalRange(low: 50, high: 60, median: 55, min: 45, max: 65);

    test('puts the usual value at three quarters of the arc', () {
      final reading = GaugeReading.from(const MetricSignal(value: 55, range: range))!;
      expect(reading.fraction, closeTo(GaugeReading.usualPosition, 0.001));
    });

    test('fills less than usual when the value is lower', () {
      final reading = GaugeReading.from(const MetricSignal(value: 44, range: range))!;
      expect(reading.fraction, lessThan(GaugeReading.usualPosition));
      expect(reading.status, RangeStatus.below);
      expect(reading.difference, -11);
    });

    test('is missing without a value or a usual range', () {
      expect(GaugeReading.from(const MetricSignal(range: range)), isNull);
      expect(GaugeReading.from(const MetricSignal(value: 40)), isNull);
    });

    test('difference texts', () {
      expect(sleepDifferenceText(-48), '48${nbsp}min less');
      expect(sleepDifferenceText(2), 'About usual');
      expect(heartRateDifferenceText(3), '3 bpm higher');
      expect(stepsDifferenceText(310), '310 more');
      expect(stepsDifferenceText(-1200), '1,200 fewer');
      expect(rangeStatusWithBounds(RangeStatus.above, range), 'above your 50–60 range');
    });
  });

  group('TodaySummary on the sample data', () {
    final summary = TodaySummary.fromDays(sampleDays, now: now);

    test('last night was shorter than usual, with a higher resting HR', () {
      expect(summary.sleep.status, RangeStatus.below);
      expect(summary.restingHeartRate.status, RangeStatus.above);
      expect(summary.heartRateVariability.status, RangeStatus.below);
    });

    test('compares steps so far with the usual steps by this time', () {
      expect(summary.stepsSoFar.value, sampleDays.first.steps);
      expect(summary.stepsSoFar.range, isNotNull);
    });

    test('finds a usual bedtime and how late last night was', () {
      expect(summary.bedtimeShiftMinutes, greaterThan(30));
    });

    test('has 7 recent HRV and active minute values', () {
      expect(summary.recentHrv, hasLength(7));
      expect(summary.recentActiveMinutes, hasLength(7));
    });
  });

  group('bedtimes', () {
    test('treat times after midnight as later than evening times', () {
      expect(minutesAfterEvening(DateTime(2026, 11, 9, 23, 50)), 350);
      expect(minutesAfterEvening(DateTime(2026, 11, 10, 1, 0)), 420);
    });
  });

  group('findGoingWell', () {
    test('mentions the most active day and a complete week of data', () {
      final wins = findGoingWell(TodaySummary.fromDays(sampleDays, now: now));
      expect(wins.map((w) => w.plain), contains(contains('most active day this week')));
      expect(wins.map((w) => w.plain), contains(contains('every night this week')));
      expect(wins.length, lessThanOrEqualTo(2));
    });
  });

  group('findPatterns', () {
    test('needs at least 14 nights', () {
      final few = nights(10, bedtimeMinutes: (_) => 0, sleepMinutes: (_) => 420);
      expect(findPatterns(few), isEmpty);
    });

    test('finds that late nights are shorter', () {
      final days = nights(
        21,
        bedtimeMinutes: (i) => i % 3 == 0 ? 70 : 10, // 01:10 or 00:10
        sleepMinutes: (i) => i % 3 == 0 ? 380 : 430,
      );
      final pattern = findPatterns(days).firstWhere((p) => p.cause == 'Bedtime');
      expect(pattern.title, 'On late nights you slept 50${nbsp}min less');
      expect(pattern.highlight.count, 7);
      expect(pattern.baseline.count, 14);
      expect(pattern.strength, PatternStrength.early); // only 7 late nights
    });

    test('finds more deep sleep after workout days', () {
      final days = nights(
        20,
        bedtimeMinutes: (_) => 10,
        sleepMinutes: (_) => 420,
        workout: (i) => i.isOdd,
        // Night i follows day i + 1, so even nights follow workouts.
        deep: (i) => i.isEven ? 105 : 90,
      );
      final pattern = findPatterns(days).firstWhere((p) => p.cause == 'Workouts');
      expect(pattern.highlight.average, 105);
      expect(pattern.baseline.average, 90);
    });

    test('reports nothing when there is no clear difference', () {
      final days = nights(20, bedtimeMinutes: (_) => 10, sleepMinutes: (_) => 420);
      expect(findPatterns(days), isEmpty);
    });

    test('finds patterns in the sample data, without claiming a cause', () {
      final patterns = findPatterns(sampleDays);
      expect(patterns, isNotEmpty);
      for (final pattern in patterns) {
        expect(pattern.title, isNot(contains('cost')));
        expect(pattern.title, isNot(contains('because')));
      }
    });
  });

  group('compareSleepWeek', () {
    test('compares this week with the usual', () {
      final rows = compareSleepWeek(sampleDays);
      expect(rows.map((r) => r.label), ['Time asleep', 'Bedtime', 'Deep sleep', 'Bedtime shift']);
    });
  });

  group('BedtimeExperiment', () {
    test('counts the nights in bed by the target time', () {
      final days = nights(
        3,
        bedtimeMinutes: (i) => i == 0 ? 60 : 20, // last night 01:00, before that 00:20
        sleepMinutes: (_) => 420,
      );
      final experiment = BedtimeExperiment.sample(days);
      expect(experiment.results, [true, false]);
      expect(experiment.nightsMet, 1);
      expect(experiment.tonight, 3);
      expect(experiment.title, 'In bed by 00:30 for 7 nights');
    });
  });

  group('coach answers', () {
    test('the sleep answer lists the numbers it used', () {
      final answer = answerCoachQuestion(CoachQuestions.sleepWeek, sampleDays);
      expect(answer.text, contains('You averaged'));
      expect(answer.numbersUsed.map((n) => n.$1), contains('Your usual (28 days)'));
      expect(answer.chartNights, hasLength(7));
    });

    test('every suggested question gets an answer with numbers', () {
      for (final question in CoachQuestions.all) {
        final answer = answerCoachQuestion(question, sampleDays);
        expect(answer.numbersUsed, isNotEmpty, reason: question);
      }
    });

    test('says so when there is not enough data', () {
      final answer = answerCoachQuestion(
        CoachQuestions.recovery,
        [DailyMetrics(date: DateTime(2026, 11, 10))],
      );
      expect(answer.text, contains('not enough data'));
      expect(answer.numbersUsed, isEmpty);
    });
  });

  group('formatters', () {
    test('formatHm', () {
      expect(formatHm(375), '6${nbsp}h${nbsp}15');
      expect(formatHm(422), '7${nbsp}h${nbsp}02');
      expect(formatHm(48), '48${nbsp}min');
    });

    test('formatThousands', () => expect(formatThousands(10443), '10,443'));

    test('formatClock wraps around midnight', () {
      expect(formatClock(60), '01:00');
      expect(formatClock(24 * 60 + 20), '00:20');
    });

    test('formatEyebrowDate', () {
      expect(formatEyebrowDate(DateTime(2026, 11, 10)), 'TUESDAY · 10 NOV');
    });
  });
}
