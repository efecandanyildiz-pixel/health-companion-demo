import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_companion/logic/coach_answers.dart';
import 'package:health_companion/main.dart';
import 'package:health_companion/screens/home_shell.dart';
import 'package:health_companion/ui/components.dart';
import 'package:health_companion/ui/app_font.dart';

final now = DateTime(2026, 11, 10, 14, 0);

/// Phone-sized test screen, tall enough to show most of a screen.
Future<void> pumpApp(WidgetTester tester, {bool onboarded = true}) async {
  tester.view.physicalSize = const Size(440 * 3, 1400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BeFitApp(now: now, startOnboarded: onboarded));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => AppFont.useGoogleFonts = false);

  testWidgets('A new user must give consent before seeing Today', (tester) async {
    await pumpApp(tester, onboarded: false);

    expect(find.textContaining('finally explained'), findsOneWidget);
    expect(find.bySemanticsLabel('BeFit'), findsOneWidget);
    expect(find.textContaining('Google'), findsNothing);
    expect(find.textContaining('Not a medical device'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Before you start'), findsOneWidget);
    expect(find.text('What BeFit uses'), findsOneWidget);
    expect(find.textContaining('Google'), findsNothing);
    expect(find.textContaining('Step'), findsNothing);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tick the box'), findsOneWidget);
    expect(find.text('Today vs your usual'), findsNothing);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Today vs your usual'), findsOneWidget);
  });

  testWidgets('Today shows the three gauges and what is going well', (tester) async {
    await pumpApp(tester);

    expect(find.text('Today vs your usual'), findsOneWidget);
    expect(find.text('Sleep ›'), findsOneWidget);
    expect(find.text('Resting HR'), findsOneWidget);
    expect(find.text('Steps'), findsOneWidget);
    expect(find.text('3 bpm higher'), findsOneWidget);
    expect(find.text('Going well'), findsOneWidget);
    expect(find.text('HRV'), findsOneWidget);
  });

  testWidgets('Tapping the sleep gauge opens sleep details', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Sleep ›'));
    await tester.pumpAndSettle();

    expect(find.text('Average this week'), findsOneWidget);
    expect(find.text('This week vs your usual'), findsOneWidget);

    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    expect(find.text('Last night'), findsOneWidget);
    expect(find.text('Average this week'), findsNothing);
  });

  testWidgets('Patterns can be filtered by area', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Patterns'));
    await tester.pumpAndSettle();

    expect(find.textContaining('not proof of cause'), findsOneWidget);
    expect(find.textContaining('On late nights you slept'), findsOneWidget);

    await tester.tap(find.text('Heart'));
    await tester.pumpAndSettle();
    expect(find.textContaining('On late nights you slept'), findsNothing);
  });

  testWidgets('The coach answers a question and shows the numbers used', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Coach'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(CoachQuestions.sleepWeek));
    await tester.pumpAndSettle();

    expect(find.text('NUMBERS USED'), findsOneWidget);
    expect(find.text('Your usual (28 days)'), findsOneWidget);
    expect(find.text('Start bedtime experiment'), findsOneWidget);
  });

  testWidgets('Turning the coach off in You stops questions', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Coach'));
    await tester.pumpAndSettle();
    expect(find.textContaining('The coach is turned off'), findsOneWidget);
    expect(find.text(CoachQuestions.sleepWeek), findsNothing);
  });

  testWidgets('The app starts dark and the theme can be switched', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();

    ThemeMode mode() => tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;
    expect(mode(), ThemeMode.dark, reason: 'dark is the default');

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(mode(), ThemeMode.light);

    await tester.tap(find.text('Automatic'));
    await tester.pumpAndSettle();
    expect(mode(), ThemeMode.system);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(mode(), ThemeMode.dark);
  });

  testWidgets('Deleting all data asks first, then returns to welcome', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Delete all my data'));
    await tester.tap(find.text('Delete all my data'));
    await tester.pumpAndSettle();
    expect(find.text('Delete everything?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete everything?'), findsNothing);

    await tester.tap(find.text('Delete all my data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.textContaining('finally explained'), findsOneWidget);
  });

  testWidgets('The app is called BeFit and has five tabs', (tester) async {
    await pumpApp(tester);

    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).title, 'BeFit');
    final labels = tester
        .widget<PillNavBar>(find.byType(PillNavBar))
        .items
        .map((item) => item.label);
    expect(labels, ['Today', 'Patterns', 'Coach', 'Friends', 'You']);
    expect(HomeShell.friendsTab, 3);
    expect(HomeShell.youTab, 4);
  });

  testWidgets('Today shows Recovery, Effort and Sleep rings with a briefing', (tester) async {
    await pumpApp(tester);

    expect(find.text('RECOVERY'), findsOneWidget);
    expect(find.text('EFFORT'), findsOneWidget);
    expect(find.text('SLEEP'), findsOneWidget);
    expect(find.text('HRV below your normal'), findsOneWidget);
    expect(find.text('DAILY BRIEFING'), findsOneWidget);

    await tester.tap(find.text('RECOVERY'));
    await tester.pumpAndSettle();
    expect(find.text('WHY THIS SCORE'), findsOneWidget);
    expect(find.text('Resting HR'), findsNWidgets(2));
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('The You tab has no Google card and has friend sharing', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Google'), findsNothing);
    expect(find.text('What friends can see'), findsOneWidget);
    expect(find.text('Friends only see what you turn on.'), findsOneWidget);
    expect(find.text('Off by default'), findsOneWidget);

    Switch switchFor(String title) => tester.widget<Switch>(
          find.descendant(
            of: find.ancestor(of: find.text(title), matching: find.byType(MergeSemantics)),
            matching: find.byType(Switch),
          ),
        );
    expect(switchFor('Steps').value, isTrue);
    expect(switchFor('Active minutes').value, isTrue);
    expect(switchFor('Mood').value, isTrue);
    expect(switchFor('Sleep').value, isFalse);

    await tester.ensureVisible(find.text('Sleep'));
    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();
    expect(switchFor('Sleep').value, isFalse, reason: 'only the switch toggles');
  });

  group('Friends', () {
    Future<void> openFriends(WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Friends'));
      await tester.pumpAndSettle();
    }

    double top(WidgetTester tester, String name) => tester.getTopLeft(find.text(name)).dy;

    testWidgets('shows the weekly leaderboard', (tester) async {
      await openFriends(tester);

      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(find.text('Weekly leaderboard'), findsOneWidget);
      for (final name in ['Deniz', 'Mert', 'Ece', 'Can']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('80,500'), findsOneWidget);
      expect(find.text('Cheer'), findsNWidgets(4));
      expect(top(tester, 'Mert'), lessThan(top(tester, 'Ece')));
    });

    testWidgets('"Vs usual" ranks against each person\'s normal', (tester) async {
      await openFriends(tester);

      await tester.tap(find.text('Vs usual'));
      await tester.pumpAndSettle();

      expect(find.textContaining('so everyone can win'), findsOneWidget);
      expect(find.text('125%'), findsOneWidget);
      expect(top(tester, 'Ece'), lessThan(top(tester, 'Mert')));
      expect(top(tester, 'Can'), lessThan(top(tester, 'Deniz')));
    });

    testWidgets('cheering a friend shows a snackbar and disables the button', (tester) async {
      await openFriends(tester);

      await tester.tap(find.text('Cheer').first);
      await tester.pump();

      expect(find.text('You cheered Mert'), findsOneWidget);
      expect(find.text('Cheered'), findsOneWidget);
      expect(find.text('Cheer'), findsNWidgets(3));
    });

    testWidgets('a friend opens a detail sheet without sleep or heart data', (tester) async {
      await openFriends(tester);

      await tester.tap(find.text('Deniz'));
      await tester.pumpAndSettle();

      expect(find.text('What Deniz shares with you'), findsOneWidget);
      expect(find.text('STEPS THIS WEEK'), findsOneWidget);
      expect(find.text('104% of their usual'), findsOneWidget);
      expect(find.text('212'), findsOneWidget);
      expect(find.textContaining('Never sleep or heart data'), findsOneWidget);

      await tester.tap(find.text('Cheer').last);
      await tester.pump();
      expect(find.text('You cheered Deniz'), findsOneWidget);
    });

    testWidgets('shows the shared goal and copies the invite code', (tester) async {
      await openFriends(tester);

      await tester.ensureVisible(find.textContaining('100,000 steps this week'));
      expect(find.text('You + Ece: 100,000 steps this week'), findsOneWidget);
      expect(find.text('Ece: 43,900'), findsOneWidget);
      expect(find.textContaining('2 days left'), findsOneWidget);

      await tester.ensureVisible(find.text('Copy'));
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(find.text('BEFIT-7K2Q'), findsOneWidget);
      expect(find.text('Copied'), findsOneWidget);
    });

    testWidgets('a valid code adds Zeynep', (tester) async {
      await openFriends(tester);
      expect(find.text('Zeynep'), findsNothing);

      await tester.ensureVisible(find.text('Add with a code'));
      await tester.tap(find.text('Add with a code'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'befit-ab12');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Zeynep'), findsOneWidget);
      expect(find.text('Zeynep is now your friend'), findsOneWidget);
    });

    testWidgets('an invalid code shows an error', (tester) async {
      await openFriends(tester);

      await tester.ensureVisible(find.text('Add with a code'));
      await tester.tap(find.text('Add with a code'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'HELLO');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Codes look like BEFIT-7K2Q.'), findsOneWidget);
      expect(find.text('Zeynep'), findsNothing);
    });
  });

  testWidgets('Every tab fits a small phone in light and dark', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(BeFitApp(now: now, startOnboarded: true));
    await tester.pumpAndSettle();

    for (final theme in ['Light', 'Dark']) {
      for (final tab in ['Today', 'Patterns', 'Coach', 'Friends']) {
        await tester.tap(find.descendant(of: find.byType(PillNavBar), matching: find.text(tab)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$tab in $theme');
      }
      await tester.tap(find.descendant(of: find.byType(PillNavBar), matching: find.text('You')));
      await tester.pumpAndSettle();
      final e = tester.takeException();
      expect(e, isNull, reason: 'You in $theme: $e');
      await tester.tap(find.text(theme == 'Light' ? 'Light' : 'Dark'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
