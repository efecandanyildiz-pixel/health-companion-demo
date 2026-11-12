import 'dart:math';

import '../models/daily_metrics.dart';

/// Returns made-up health data so we can build screens before the
/// Google Health API connection is ready.
///
/// The data is random but repeatable (fixed seed), and it contains the
/// kinds of links the Patterns screen looks for: late nights are shorter,
/// workout days are followed by more deep sleep, Mondays have a slightly
/// higher resting heart rate.
///
/// Later we will add a real repository with the same method, and the
/// screens will not need to change.
class FakeHealthRepository {
  const FakeHealthRepository();

  static const historyDays = 28;

  /// Share of a day's steps in each hour, starting at midnight.
  static const _hourlyShape = [
    0, 0, 0, 0, 0, 0, 1, 4, 8, 7, 6, 7, //
    9, 7, 6, 6, 7, 9, 8, 5, 4, 3, 2, 1, //
  ];

  /// Today first, followed by the previous 28 days (newest to oldest).
  List<DailyMetrics> recentDays({DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final random = Random(7);

    // Index = days ago. Index 1 (yesterday) always has a workout.
    final workoutDays = List.generate(
      historyDays + 2,
      (daysAgo) => daysAgo == 1 || random.nextDouble() < 0.3,
    );

    final days = <DailyMetrics>[_lastNight(today, current)];

    for (var daysAgo = 1; daysAgo <= historyDays; daysAgo++) {
      final date = today.subtract(Duration(days: daysAgo));
      final isYesterday = daysAgo == 1;

      final late = !isYesterday && random.nextDouble() < 0.33;
      final minutesFromMidnight =
          late ? 50 + random.nextInt(36) : -5 + random.nextInt(46);
      final bedtime = DateTime(date.year, date.month, date.day)
          .add(Duration(minutes: minutesFromMidnight));

      final baseSleep = 415 + random.nextInt(31);
      final asleep = late ? baseSleep - 30 - random.nextInt(16) : baseSleep;
      var deep = (asleep * (0.20 + random.nextDouble() * 0.04)).round();
      // A workout the day before this night adds deep sleep.
      if (workoutDays[daysAgo + 1]) deep += 10 + random.nextInt(5);
      final rem = (asleep * (0.20 + random.nextDouble() * 0.05)).round();
      final awake = 8 + random.nextInt(14);

      final isMonday = date.weekday == DateTime.monday;
      final workout = workoutDays[daysAgo];
      final totalSteps =
          6500 + random.nextInt(4500) + (workout ? 2500 : 0);

      days.add(
        DailyMetrics(
          date: date,
          bedtime: bedtime,
          wakeTime: bedtime.add(Duration(minutes: asleep + awake)),
          sleepStages: SleepStages(
            deep: deep,
            light: asleep - deep - rem,
            rem: rem,
            awake: awake,
          ),
          restingHeartRate: 56 + random.nextInt(4) + (isMonday ? 2 : 0),
          heartRateVariability: 43 + random.nextInt(8) - (late ? 3 : 0),
          stepsByHour: _spreadOverDay(totalSteps, random),
          activeZoneMinutes:
              isYesterday ? 48 : 10 + random.nextInt(26) + (workout ? 10 : 0),
          workoutMinutes: workout ? 40 + random.nextInt(31) : 0,
        ),
      );
    }

    return days;
  }

  /// A late, short night after a workout day, so the screens have
  /// something to explain.
  static DailyMetrics _lastNight(DateTime today, DateTime now) {
    const segments = [
      SleepSegment(SleepStage.awake, 6),
      SleepSegment(SleepStage.light, 30),
      SleepSegment(SleepStage.deep, 40),
      SleepSegment(SleepStage.light, 34),
      SleepSegment(SleepStage.rem, 18),
      SleepSegment(SleepStage.light, 56),
      SleepSegment(SleepStage.deep, 34),
      SleepSegment(SleepStage.rem, 24),
      SleepSegment(SleepStage.awake, 4),
      SleepSegment(SleepStage.light, 48),
      SleepSegment(SleepStage.deep, 22),
      SleepSegment(SleepStage.rem, 31),
      SleepSegment(SleepStage.light, 38),
      SleepSegment(SleepStage.awake, 5),
    ];

    // Steps so far today: full hours, plus part of the current hour.
    const plannedSteps = 10000;
    final shapeTotal = _hourlyShape.reduce((a, b) => a + b);
    final stepsByHour = [
      for (var hour = 0; hour <= now.hour; hour++)
        (plannedSteps *
                _hourlyShape[hour] /
                shapeTotal *
                (hour < now.hour ? 1 : now.minute / 60))
            .round(),
    ];

    return DailyMetrics(
      date: today,
      bedtime: DateTime(today.year, today.month, today.day, 1, 0),
      wakeTime: DateTime(today.year, today.month, today.day, 7, 30),
      sleepStages: const SleepStages(deep: 96, light: 206, rem: 73, awake: 15),
      sleepSegments: segments,
      restingHeartRate: 61,
      heartRateVariability: 42,
      stepsByHour: stepsByHour,
    );
  }

  static List<int> _spreadOverDay(int totalSteps, Random random) {
    final weights = [
      for (final share in _hourlyShape) share * (0.7 + random.nextDouble() * 0.6),
    ];
    final weightTotal = weights.reduce((a, b) => a + b);
    return [for (final w in weights) (totalSteps * w / weightTotal).round()];
  }
}
