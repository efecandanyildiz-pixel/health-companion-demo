import '../models/daily_metrics.dart';
import '../models/friend.dart';
import 'scores.dart';

/// How the weekly leaderboard is sorted.
enum LeaderboardMode {
  /// Most steps this week first.
  steps,

  /// Highest share of each person's own usual week first.
  vsUsual,
}

/// One row of the weekly leaderboard: a friend or you.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.stepsThisWeek,
    required this.usualDailySteps,
    this.mood,
    this.isYou = false,
  });

  final String id;
  final String name;
  final int stepsThisWeek;
  final int usualDailySteps;

  /// Null when the person does not share their mood.
  final Mood? mood;
  final bool isYou;

  /// A friend's row. Their mood only shows when they share it.
  factory LeaderboardEntry.fromFriend(Friend friend) => LeaderboardEntry(
        id: friend.id,
        name: friend.name,
        stepsThisWeek: friend.stepsThisWeek,
        usualDailySteps: friend.usualDailySteps,
        mood: friend.sharesMetric(SharedMetric.mood)
            ? moodFromRecovery(friend.recovery)
            : null,
      );

  /// Your row, from your own days (newest first, today first).
  ///
  /// The week is the last 7 full days, ending yesterday, like your
  /// friends' weeks. Your usual is the average full day of the last
  /// [scoreHistoryDays] days. Your mood comes from today's recovery score.
  factory LeaderboardEntry.forYou(List<DailyMetrics> days) {
    final fullDays = yourFullDaySteps(days);
    final history = fullDays.take(scoreHistoryDays).toList();
    final recovery = RecoveryScore.fromDays(days);
    return LeaderboardEntry(
      id: youId,
      name: 'You',
      stepsThisWeek: fullDays.take(7).fold<int>(0, (a, b) => a + b),
      usualDailySteps: history.isEmpty
          ? 0
          : (history.fold<int>(0, (a, b) => a + b) / history.length).round(),
      mood: recovery == null ? null : moodFromRecovery(recovery.score),
      isYou: true,
    );
  }

  static const youId = 'you';

  /// This week's steps as a percentage of this person's usual week.
  int get percentOfUsual => percentOfUsualWeek(stepsThisWeek, usualDailySteps);
}

/// Steps of each full day, newest first, starting yesterday. Days without
/// steps count as 0.
List<int> yourFullDaySteps(List<DailyMetrics> days) =>
    days.skip(1).map((day) => day.steps ?? 0).toList();

/// [weekSteps] as a percentage of 7 usual days, rounded. 0 without a usual.
int percentOfUsualWeek(int weekSteps, int usualDailySteps) {
  if (usualDailySteps <= 0) return 0;
  return (weekSteps * 100 / (usualDailySteps * 7)).round();
}

/// Sorts [entries] for the leaderboard, best first. Ties go by name, so the
/// order never jumps around.
List<LeaderboardEntry> rankLeaderboard(
  Iterable<LeaderboardEntry> entries,
  LeaderboardMode mode,
) {
  int score(LeaderboardEntry e) => switch (mode) {
        LeaderboardMode.steps => e.stepsThisWeek,
        LeaderboardMode.vsUsual => e.percentOfUsual,
      };
  final list = entries.toList();
  list.sort((a, b) {
    final byScore = score(b).compareTo(score(a));
    return byScore != 0 ? byScore : a.name.compareTo(b.name);
  });
  return list;
}

/// Turns a recovery score (0 to 100) into one of five moods.
Mood moodFromRecovery(int recovery) {
  if (recovery < 20) return Mood.drained;
  if (recovery < 40) return Mood.tired;
  if (recovery < 60) return Mood.okay;
  if (recovery < 80) return Mood.fresh;
  return Mood.great;
}

/// Where a shared step goal stands.
class SharedGoalProgress {
  const SharedGoalProgress({
    required this.targetSteps,
    required this.yourSteps,
    required this.friendSteps,
    required this.daysLeft,
  });

  final int targetSteps;
  final int yourSteps;
  final int friendSteps;

  /// Days still to go, including today.
  final int daysLeft;

  int get totalSteps => yourSteps + friendSteps;

  int get stepsToGo => (targetSteps - totalSteps).clamp(0, targetSteps);

  /// From 0 to 1, for the progress bar.
  double get fraction =>
      targetSteps <= 0 ? 0 : (totalSteps / targetSteps).clamp(0.0, 1.0);

  bool get reached => totalSteps >= targetSteps;
}

/// Adds up both people's steps for the days of [goal] done so far.
///
/// [yourDailySteps] and [friendDailySteps] are full days, newest first,
/// ending yesterday.
SharedGoalProgress sharedGoalProgress(
  SharedGoal goal, {
  required List<int> yourDailySteps,
  required List<int> friendDailySteps,
}) {
  int sumFirst(List<int> values) =>
      values.take(goal.daysDone).fold<int>(0, (a, b) => a + b);
  return SharedGoalProgress(
    targetSteps: goal.targetSteps,
    yourSteps: sumFirst(yourDailySteps),
    friendSteps: sumFirst(friendDailySteps),
    daysLeft: (goal.lengthDays - goal.daysDone).clamp(0, goal.lengthDays),
  );
}

final _inviteCodePattern = RegExp(r'^BEFIT-[A-Z0-9]{4}$');

/// Cleans up a typed invite code: no spaces around it, capital letters.
String normalizeInviteCode(String code) => code.trim().toUpperCase();

/// True for codes like "BEFIT-7K2Q": four letters or digits after "BEFIT-".
bool isValidInviteCode(String code) =>
    _inviteCodePattern.hasMatch(normalizeInviteCode(code));
