/// How a person seems today, from their recovery. Friends see this
/// instead of any sleep or heart numbers.
enum Mood { drained, tired, okay, fresh, great }

extension MoodLabel on Mood {
  /// For example "Fresh".
  String get label => switch (this) {
        Mood.drained => 'Drained',
        Mood.tired => 'Tired',
        Mood.okay => 'Okay',
        Mood.fresh => 'Fresh',
        Mood.great => 'Great',
      };
}

/// What a person can let their friends see.
enum SharedMetric { steps, activeMinutes, mood, sleep }

extension SharedMetricLabel on SharedMetric {
  /// For example "Active minutes".
  String get label => switch (this) {
        SharedMetric.steps => 'Steps',
        SharedMetric.activeMinutes => 'Active minutes',
        SharedMetric.mood => 'Mood',
        SharedMetric.sleep => 'Sleep',
      };
}

/// One friend, with only what they share with you.
///
/// There are no sleep or heart values here on purpose: friends only ever
/// get steps, active minutes and a mood.
class Friend {
  const Friend({
    required this.id,
    required this.name,
    required this.weekSteps,
    required this.usualDailySteps,
    required this.activeMinutesThisWeek,
    required this.recovery,
    required this.colorIndex,
    this.shares = const {
      SharedMetric.steps,
      SharedMetric.activeMinutes,
      SharedMetric.mood,
    },
  });

  final String id;
  final String name;

  /// Steps on each of the last 7 full days, oldest first (ends yesterday).
  final List<int> weekSteps;

  /// Their own usual daily steps, over the last 28 days.
  final int usualDailySteps;

  final int activeMinutesThisWeek;

  /// Recovery score from 0 to 100. Only its [Mood] is ever shown.
  final int recovery;

  /// Picks the avatar color, so every friend looks different.
  final int colorIndex;

  /// What this friend lets you see. Never includes sleep.
  final Set<SharedMetric> shares;

  int get stepsThisWeek => weekSteps.fold<int>(0, (a, b) => a + b);

  bool sharesMetric(SharedMetric metric) => shares.contains(metric);
}

/// A step goal two people work on together over 7 days.
class SharedGoal {
  const SharedGoal({
    required this.friendId,
    required this.targetSteps,
    required this.daysDone,
    this.lengthDays = 7,
  });

  final String friendId;
  final int targetSteps;

  /// Full days already counted, ending yesterday.
  final int daysDone;
  final int lengthDays;
}
