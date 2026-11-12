import 'package:flutter/material.dart';

import '../ui/components.dart';
import '../ui/palette.dart';
import 'coach_screen.dart';
import 'friends_screen.dart';
import 'patterns_screen.dart';
import 'sleep_screen.dart';
import 'today_screen.dart';
import 'you_screen.dart';

/// The app frame: the current tab on top, the navigation bar at the bottom.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static const todayTab = 0;
  static const patternsTab = 1;
  static const coachTab = 2;
  static const friendsTab = 3;
  static const youTab = 4;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = HomeShell.todayTab;

  void _select(int tab) => setState(() => _tab = tab);

  void _openSleep() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SleepScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final screen = switch (_tab) {
      HomeShell.todayTab => TodayScreen(
          onOpenSleep: _openSleep,
          onOpenPatterns: () => _select(HomeShell.patternsTab),
          onOpenYou: () => _select(HomeShell.youTab),
        ),
      HomeShell.patternsTab => const PatternsScreen(),
      HomeShell.coachTab =>
        CoachScreen(onOpenPatterns: () => _select(HomeShell.patternsTab)),
      HomeShell.friendsTab => const FriendsScreen(),
      _ => const YouScreen(),
    };

    return Scaffold(
      backgroundColor: context.palette.background,
      body: screen,
      bottomNavigationBar: PillNavBar(
        selectedIndex: _tab,
        onSelected: _select,
        items: const [
          PillNavItem(Icons.grid_view_rounded, 'Today'),
          PillNavItem(Icons.insights_rounded, 'Patterns'),
          PillNavItem(Icons.chat_bubble_outline_rounded, 'Coach'),
          PillNavItem(Icons.people_outline_rounded, 'Friends'),
          PillNavItem(Icons.person_outline_rounded, 'You'),
        ],
      ),
    );
  }
}
