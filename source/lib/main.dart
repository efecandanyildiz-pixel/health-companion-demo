import 'package:flutter/material.dart';

import 'app_state.dart';
import 'data/fake_health_repository.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'ui/palette.dart';
import 'ui/theme.dart';

void main() {
  runApp(const BeFitApp());
}

class BeFitApp extends StatefulWidget {
  const BeFitApp({
    super.key,
    this.repository = const FakeHealthRepository(),
    this.now,
    this.startOnboarded = false,
  });

  final FakeHealthRepository repository;

  /// Fixed "now" for tests. Uses the real time when null.
  final DateTime? now;

  /// Skip the welcome and consent screens (used in tests).
  final bool startOnboarded;

  /// Keeps the app phone-sized when it runs in a wide browser window.
  static const maxAppWidth = 440.0;

  @override
  State<BeFitApp> createState() => _BeFitAppState();
}

class _BeFitAppState extends State<BeFitApp> {
  late final AppState _state = _createState();

  AppState _createState() {
    final now = widget.now ?? DateTime.now();
    return AppState(
      days: widget.repository.recentDays(now: now),
      now: now,
      onboarded: widget.startOnboarded,
    );
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) => MaterialApp(
          title: 'BeFit',
          debugShowCheckedModeBanner: false,
          themeMode: _state.themeMode,
          theme: buildAppTheme(AppPalette.light),
          darkTheme: buildAppTheme(AppPalette.dark),
          builder: (context, child) => ColoredBox(
            color: context.palette.frame,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: BeFitApp.maxAppWidth,
                ),
                child: child,
              ),
            ),
          ),
          home: _state.onboarded ? const HomeShell() : const WelcomeScreen(),
        ),
      ),
    );
  }
}
