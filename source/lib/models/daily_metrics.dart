enum SleepStage { deep, light, rem, awake }

/// One stretch of the night spent in a single sleep stage.
class SleepSegment {
  const SleepSegment(this.stage, this.minutes);

  final SleepStage stage;
  final int minutes;
}

/// Minutes spent in each sleep stage during one night.
class SleepStages {
  const SleepStages({
    required this.deep,
    required this.light,
    required this.rem,
    required this.awake,
  });

  final int deep;
  final int light;
  final int rem;
  final int awake;

  /// Time actually asleep. Awake minutes are not counted.
  int get asleep => deep + light + rem;

  int minutesIn(SleepStage stage) => switch (stage) {
        SleepStage.deep => deep,
        SleepStage.light => light,
        SleepStage.rem => rem,
        SleepStage.awake => awake,
      };
}

/// One day of health data for one user.
///
/// [date] is the morning the night ended. Activity values belong to that
/// calendar day. We store daily aggregates, not raw sensor streams.
/// A value is null when the wearable did not report it.
class DailyMetrics {
  const DailyMetrics({
    required this.date,
    this.bedtime,
    this.wakeTime,
    this.sleepStages,
    this.sleepSegments = const [],
    this.restingHeartRate,
    this.heartRateVariability,
    this.stepsByHour = const [],
    this.activeZoneMinutes,
    this.workoutMinutes = 0,
  });

  final DateTime date;

  final DateTime? bedtime;
  final DateTime? wakeTime;
  final SleepStages? sleepStages;

  /// The night in order, for the stage timeline. May be empty.
  final List<SleepSegment> sleepSegments;

  /// Beats per minute (bpm).
  final int? restingHeartRate;

  /// Milliseconds (ms).
  final int? heartRateVariability;

  /// Steps in each hour, starting at midnight. Today only has the hours
  /// that have started so far.
  final List<int> stepsByHour;

  final int? activeZoneMinutes;
  final int workoutMinutes;

  /// Total minutes asleep, or null if no sleep was tracked.
  int? get sleepMinutes => sleepStages?.asleep;

  /// Steps for the whole day (or so far, for today).
  int? get steps =>
      stepsByHour.isEmpty ? null : stepsByHour.fold<int>(0, (a, b) => a + b);

  /// Steps taken before [hour]:[minute] on this day.
  int? stepsUntil(int hour, int minute) {
    if (stepsByHour.isEmpty) return null;
    var total = 0.0;
    for (var h = 0; h < stepsByHour.length && h <= hour; h++) {
      total += h < hour ? stepsByHour[h] : stepsByHour[h] * minute / 60;
    }
    return total.round();
  }

  bool get hadWorkout => workoutMinutes >= 20;
}
