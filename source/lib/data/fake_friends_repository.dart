import '../models/friend.dart';

/// Made-up friends so we can build the Friends tab before there is a
/// backend. Everything stays in memory.
///
/// The numbers are picked so the two leaderboards differ: Mert walks the
/// most, but Ece is furthest above her own normal.
class FakeFriendsRepository {
  const FakeFriendsRepository();

  /// The code friends type to add you.
  static const inviteCode = 'BEFIT-7K2Q';

  static const _friends = [
    Friend(
      id: 'deniz',
      name: 'Deniz',
      weekSteps: [9800, 11200, 10100, 10900, 9600, 10700, 10500],
      usualDailySteps: 10000,
      activeMinutesThisWeek: 212,
      recovery: 82,
      colorIndex: 0,
    ),
    Friend(
      id: 'mert',
      name: 'Mert',
      weekSteps: [12400, 10900, 11800, 11100, 12200, 10600, 11500],
      usualDailySteps: 13800,
      activeMinutesThisWeek: 168,
      recovery: 35,
      colorIndex: 1,
      shares: {SharedMetric.steps, SharedMetric.mood},
    ),
    Friend(
      id: 'ece',
      name: 'Ece',
      weekSteps: [7900, 8400, 9100, 8200, 8800, 9300, 8500],
      usualDailySteps: 6900,
      activeMinutesThisWeek: 145,
      recovery: 68,
      colorIndex: 2,
    ),
    Friend(
      id: 'can',
      name: 'Can',
      weekSteps: [5400, 6300, 5900, 6600, 5800, 6200, 5800],
      usualDailySteps: 5200,
      activeMinutesThisWeek: 96,
      recovery: 15,
      colorIndex: 3,
    ),
  ];

  /// The friend added with any valid invite code, for the demo.
  static const _newFriend = Friend(
    id: 'zeynep',
    name: 'Zeynep',
    weekSteps: [7200, 7800, 7100, 7900, 7400, 7600, 7500],
    usualDailySteps: 8000,
    activeMinutesThisWeek: 120,
    recovery: 55,
    colorIndex: 4,
  );

  List<Friend> friends() => List.of(_friends);

  /// Who an invite code belongs to. The demo always returns Zeynep.
  Friend friendForCode(String code) => _newFriend;

  /// You and Ece, 100,000 steps together over 7 days.
  SharedGoal sharedGoal() =>
      const SharedGoal(friendId: 'ece', targetSteps: 100000, daysDone: 5);
}
