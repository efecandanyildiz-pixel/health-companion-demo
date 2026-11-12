# BeFit: changes on the `befit-v2` branch

Built on top of the original Health Companion prototype. The app still runs on sample data; nothing connects to Google Health yet.

## What changed

**Name.** The app is now called BeFit (app title, web title, manifest, welcome screen wordmark). The Dart package name is still `health_companion`, so imports are unchanged. `HealthCompanionApp` is now `BeFitApp`.

**No visible Google connection.** The consent screen button says "Continue", the "Connect Google Health" card on the You tab is gone, and the welcome footer no longer mentions the Google Health app. Real data will be added later.

**Dark, dashboard-style look.** Dark theme is the default (Light and Automatic still work from the You tab). The Today screen opens with three score rings:

- Recovery (0–100%): last night's HRV, resting heart rate and sleep compared with the previous 28 days. Tap it to see how many points each one added or took away.
- Effort (0–100): today's active minutes compared with your usual day. A usual day is 50.
- Sleep (%): minutes asleep out of an 8-hour need.

Under the rings there is a short daily briefing. The formulas are in `lib/logic/scores.dart` and tested in `test/scores_test.dart`.

**Friends tab** (new, between Coach and You), sample friends only:

- Weekly leaderboard, ranked by steps or by steps compared with each person's own usual.
- Mood badge per friend, Cheer button, friend detail sheet.
- Shared goal card (You + Ece, 100,000 steps this week).
- Invite code BEFIT-7K2Q with Copy, and "Add with a code" (any BEFIT-XXXX code adds a sample friend).
- On the You tab, "What friends can see": steps, active minutes and mood are on, sleep is off. Friends never see sleep or heart data.

New files: `lib/models/friend.dart`, `lib/data/fake_friends_repository.dart`, `lib/logic/friends.dart`, `lib/logic/scores.dart`, `lib/screens/friends_screen.dart`, `test/friends_test.dart`, `test/scores_test.dart`.

**Coach answers** now show a title line, the explanation, then the numbers used.

**Sample data.** Last night's HRV went from 39 to 42 so the Recovery score is low but not zero.

## Flutter version

These changes were made with Flutter 3.38.10 (Dart 3.10), because one of our Macs runs macOS 13 and newer Flutter needs macOS 14. To build on both:

- `pubspec.yaml`: SDK constraint `^3.10.0` (was `^3.13.7`), `google_fonts: ^8.2.1` (was `^9.0.0`).
- `lib/app_state.dart`: the constructor takes `bool onboarded` and sets `_onboarded` in the initializer list, instead of the Dart 3.13 `this._onboarded` form.

Both still work on newer Flutter.

## Checks

- `flutter analyze`: no issues
- `flutter test`: 72 tests pass
- Web demo: https://efecandanyildiz-pixel.github.io/health-companion-demo/
