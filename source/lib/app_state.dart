import 'package:flutter/material.dart';

import 'data/fake_friends_repository.dart';
import 'logic/friends.dart';
import 'models/daily_metrics.dart';
import 'models/friend.dart';

/// What happened when the user typed an invite code.
enum AddFriendResult { added, invalidCode, alreadyFriends }

/// App-wide state: the health data, the theme and the user's choices.
///
/// Kept in memory for now. Once the backend exists, consent and settings
/// will be saved there.
class AppState extends ChangeNotifier {
  /// Callers pass `onboarded:`; it sets the private field directly.
  AppState({
    required this.days,
    required this.now,
    bool onboarded = false,
    this.friendsRepository = const FakeFriendsRepository(),
  })  : _onboarded = onboarded,
        _friends = friendsRepository.friends();

  /// Newest first: today, yesterday, then older days.
  final List<DailyMetrics> days;

  /// "Now" for all calculations. Fixed in tests.
  final DateTime now;

  /// Sample friends for now. Later this becomes the friends backend.
  final FakeFriendsRepository friendsRepository;

  static const _defaultSharing = {
    SharedMetric.steps,
    SharedMetric.activeMinutes,
    SharedMetric.mood,
  };

  /// Dark first. Light and automatic stay available in the You tab.
  ThemeMode _themeMode = ThemeMode.dark;
  bool _onboarded;
  bool _coachMayUseData = true;
  bool _bedtimeReminder = false;
  List<Friend> _friends;
  final Set<String> _cheered = {};
  final Set<SharedMetric> _sharing = {..._defaultSharing};

  ThemeMode get themeMode => _themeMode;
  bool get onboarded => _onboarded;
  bool get coachMayUseData => _coachMayUseData;
  bool get bedtimeReminder => _bedtimeReminder;
  List<Friend> get friends => List.unmodifiable(_friends);
  String get inviteCode => FakeFriendsRepository.inviteCode;
  SharedGoal get sharedGoal => friendsRepository.sharedGoal();

  bool hasCheered(String friendId) => _cheered.contains(friendId);

  /// Whether friends can see [metric] of yours.
  bool isSharing(SharedMetric metric) => _sharing.contains(metric);

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void completeOnboarding() {
    _onboarded = true;
    notifyListeners();
  }

  void setCoachMayUseData(bool value) {
    _coachMayUseData = value;
    notifyListeners();
  }

  void setBedtimeReminder(bool value) {
    _bedtimeReminder = value;
    notifyListeners();
  }

  void cheer(String friendId) {
    if (!_cheered.add(friendId)) return;
    notifyListeners();
  }

  void setSharing(SharedMetric metric, bool value) {
    final changed = value ? _sharing.add(metric) : _sharing.remove(metric);
    if (changed) notifyListeners();
  }

  /// Adds the friend behind [code], if the code looks right.
  AddFriendResult addFriendWithCode(String code) {
    if (!isValidInviteCode(code)) return AddFriendResult.invalidCode;
    final friend = friendsRepository.friendForCode(normalizeInviteCode(code));
    if (_friends.any((f) => f.id == friend.id)) {
      return AddFriendResult.alreadyFriends;
    }
    _friends = [..._friends, friend];
    notifyListeners();
    return AddFriendResult.added;
  }

  /// Forgets consent and settings and returns to the welcome screen.
  /// Later this will also delete the user's data on the server.
  void deleteAllData() {
    _onboarded = false;
    _coachMayUseData = true;
    _bedtimeReminder = false;
    _themeMode = ThemeMode.dark;
    _friends = friendsRepository.friends();
    _cheered.clear();
    _sharing
      ..clear()
      ..addAll(_defaultSharing);
    notifyListeners();
  }
}

/// Gives every screen access to [AppState] with `AppScope.of(context)`.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
