import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_companion/app_state.dart';
import 'package:health_companion/data/fake_friends_repository.dart';
import 'package:health_companion/data/fake_health_repository.dart';
import 'package:health_companion/logic/friends.dart';
import 'package:health_companion/models/friend.dart';

final now = DateTime(2026, 11, 10, 14, 0);
final sampleDays = const FakeHealthRepository().recentDays(now: now);

LeaderboardEntry entry(String name, int week, int usual) => LeaderboardEntry(
      id: name.toLowerCase(),
      name: name,
      stepsThisWeek: week,
      usualDailySteps: usual,
    );

void main() {
  group('leaderboard', () {
    test('percent of usual compares with 7 usual days', () {
      expect(percentOfUsualWeek(70000, 10000), 100);
      expect(percentOfUsualWeek(60200, 6900), 125);
      expect(percentOfUsualWeek(5000, 0), 0);
    });

    test('ranks by steps or by share of usual, ties by name', () {
      final entries = [
        entry('Big', 90000, 15000), // 86%
        entry('Small', 40000, 4000), // 143%
        entry('Also', 40000, 5000), // 114%
      ];
      expect(
        rankLeaderboard(entries, LeaderboardMode.steps).map((e) => e.name),
        ['Big', 'Also', 'Small'],
      );
      expect(
        rankLeaderboard(entries, LeaderboardMode.vsUsual).map((e) => e.name),
        ['Small', 'Also', 'Big'],
      );
    });

    test('a friend hides their mood unless they share it', () {
      final friends = const FakeFriendsRepository().friends();
      final mert = friends.firstWhere((f) => f.id == 'mert');
      final deniz = friends.firstWhere((f) => f.id == 'deniz');
      expect(LeaderboardEntry.fromFriend(mert).mood, Mood.tired);
      expect(LeaderboardEntry.fromFriend(deniz).mood, Mood.great);

      final hidden = Friend(
        id: 'x',
        name: 'X',
        weekSteps: const [1000],
        usualDailySteps: 1000,
        activeMinutesThisWeek: 0,
        recovery: 90,
        colorIndex: 0,
        shares: const {SharedMetric.steps},
      );
      expect(LeaderboardEntry.fromFriend(hidden).mood, isNull);
    });

    test('your row uses the last 7 full days and your 28-day usual', () {
      final you = LeaderboardEntry.forYou(sampleDays);
      expect(you.isYou, isTrue);
      expect(you.stepsThisWeek, 68421);
      expect(you.usualDailySteps, 9300);
      expect(you.percentOfUsual, 105);
      expect(you.mood, Mood.drained);
    });

    test('the sample friends rank differently in the two modes', () {
      final entries = [
        LeaderboardEntry.forYou(sampleDays),
        ...const FakeFriendsRepository().friends().map(LeaderboardEntry.fromFriend),
      ];
      expect(
        rankLeaderboard(entries, LeaderboardMode.steps).map((e) => e.name),
        ['Mert', 'Deniz', 'You', 'Ece', 'Can'],
      );
      expect(
        rankLeaderboard(entries, LeaderboardMode.vsUsual).map((e) => e.name),
        ['Ece', 'Can', 'You', 'Deniz', 'Mert'],
      );
    });
  });

  test('moodFromRecovery uses five even bands', () {
    expect(moodFromRecovery(0), Mood.drained);
    expect(moodFromRecovery(19), Mood.drained);
    expect(moodFromRecovery(20), Mood.tired);
    expect(moodFromRecovery(40), Mood.okay);
    expect(moodFromRecovery(60), Mood.fresh);
    expect(moodFromRecovery(80), Mood.great);
    expect(moodFromRecovery(100), Mood.great);
  });

  group('shared goal', () {
    const goal = SharedGoal(friendId: 'ece', targetSteps: 100000, daysDone: 5);

    test('adds both people\'s steps for the days done', () {
      final progress = sharedGoalProgress(
        goal,
        yourDailySteps: const [10000, 10000, 10000, 10000, 10000, 99999],
        friendDailySteps: const [8000, 8000, 8000, 8000, 8000, 99999],
      );
      expect(progress.yourSteps, 50000);
      expect(progress.friendSteps, 40000);
      expect(progress.stepsToGo, 10000);
      expect(progress.fraction, closeTo(0.9, 0.0001));
      expect(progress.daysLeft, 2);
      expect(progress.reached, isFalse);
    });

    test('caps at the target', () {
      final progress = sharedGoalProgress(
        goal,
        yourDailySteps: const [60000],
        friendDailySteps: const [60000],
      );
      expect(progress.fraction, 1);
      expect(progress.stepsToGo, 0);
      expect(progress.reached, isTrue);
    });
  });

  test('invite codes look like BEFIT-XXXX', () {
    expect(isValidInviteCode('BEFIT-7K2Q'), isTrue);
    expect(isValidInviteCode('  befit-ab12 '), isTrue);
    expect(isValidInviteCode('BEFIT-7K2'), isFalse);
    expect(isValidInviteCode('BEFIT-7K2QX'), isFalse);
    expect(isValidInviteCode('FIT-7K2Q'), isFalse);
    expect(isValidInviteCode('BEFIT-7K-Q'), isFalse);
  });

  group('AppState friends', () {
    AppState state() => AppState(days: sampleDays, now: now, onboarded: true);

    test('adds Zeynep once, rejects bad codes', () {
      final app = state();
      expect(app.addFriendWithCode('nope'), AddFriendResult.invalidCode);
      expect(app.friends, hasLength(4));
      expect(app.addFriendWithCode('BEFIT-AB12'), AddFriendResult.added);
      expect(app.friends.last.name, 'Zeynep');
      expect(app.addFriendWithCode('BEFIT-CD34'), AddFriendResult.alreadyFriends);
      expect(app.friends, hasLength(5));
    });

    test('cheers and sharing are kept, and reset by deleting all data', () {
      final app = state();
      expect(app.isSharing(SharedMetric.steps), isTrue);
      expect(app.isSharing(SharedMetric.sleep), isFalse);
      expect(app.themeMode, ThemeMode.dark);

      app.cheer('deniz');
      app.setSharing(SharedMetric.sleep, true);
      app.addFriendWithCode('BEFIT-AB12');
      expect(app.hasCheered('deniz'), isTrue);
      expect(app.isSharing(SharedMetric.sleep), isTrue);

      app.deleteAllData();
      expect(app.hasCheered('deniz'), isFalse);
      expect(app.isSharing(SharedMetric.sleep), isFalse);
      expect(app.friends, hasLength(4));
    });
  });
}
