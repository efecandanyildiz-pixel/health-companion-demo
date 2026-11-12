import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../logic/formatters.dart';
import '../logic/friends.dart';
import '../logic/scores.dart';
import '../models/friend.dart';
import '../ui/app_font.dart';
import '../ui/charts.dart';
import '../ui/components.dart';
import '../ui/palette.dart';

/// Friends: a weekly leaderboard, cheers, a shared goal and invite codes.
///
/// Friends only ever see steps, active minutes and a mood. Never sleep or
/// heart data.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  LeaderboardMode _mode = LeaderboardMode.steps;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final entries = rankLeaderboard(
      [
        LeaderboardEntry.forYou(app.days),
        for (final friend in app.friends) LeaderboardEntry.fromFriend(friend),
      ],
      _mode,
    );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: ScreenHeader(eyebrow: 'THIS WEEK', title: 'Friends'),
          ),
          const SizedBox(height: 18),
          _LeaderboardCard(
            entries: entries,
            mode: _mode,
            onModeChanged: (mode) => setState(() => _mode = mode),
          ),
          const SizedBox(height: 14),
          const _SharedGoalCard(),
          const SizedBox(height: 14),
          const _AddFriendCard(),
        ],
      ),
    );
  }
}

/// Avatar colours, picked by [Friend.colorIndex].
List<Color> friendGradient(AppPalette p, int colorIndex) {
  final options = [p.sleep.gradient, p.heart.gradient, p.activity.gradient, p.effort, p.experiment];
  return options[colorIndex % options.length];
}

ScoreLevel _moodLevel(Mood mood) => switch (mood) {
      Mood.drained || Mood.tired => ScoreLevel.low,
      Mood.okay => ScoreLevel.mid,
      Mood.fresh || Mood.great => ScoreLevel.high,
    };

void _cheer(BuildContext context, AppState app, Friend friend) {
  app.cheer(friend.id);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('You cheered ${friend.name}')));
}

/// A round avatar with the first letter of the name.
class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name, required this.colors, this.size = 36});

  final String name;
  final List<Color> colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: colors)),
        child: Text(
          name.characters.first,
          style: AppFont.style(size: size * 0.42, weight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}

/// A small ring in the recovery colours, plus the mood word.
class MoodBadge extends StatelessWidget {
  const MoodBadge(this.mood, {super.key});

  final Mood mood;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = p.scoreColor(_moodLevel(mood));
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 8, 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: p.isDark ? 0.14 : 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScoreRing(
            fraction: (mood.index + 1) / Mood.values.length,
            colors: [color],
            size: 14,
            strokeWidth: 3,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              mood.label,
              overflow: TextOverflow.ellipsis,
              style: AppFont.style(size: 12, weight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheerButton extends StatelessWidget {
  const _CheerButton({required this.friend, this.large = false});

  final Friend friend;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = context.palette;
    final cheered = app.hasCheered(friend.id);
    final label = Text(cheered ? 'Cheered' : 'Cheer');
    final onPressed = cheered ? null : () => _cheer(context, app, friend);

    if (large) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(cheered ? Icons.check_rounded : Icons.celebration_outlined, size: 20),
          label: label,
          style: FilledButton.styleFrom(
            backgroundColor: p.ink,
            foregroundColor: p.background,
            disabledBackgroundColor: p.track,
            disabledForegroundColor: p.muted,
            shape: const StadiumBorder(),
            textStyle: AppFont.style(size: 16, weight: FontWeight.w700),
          ),
        ),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        disabledForegroundColor: p.faint,
        side: BorderSide(color: p.border),
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: AppFont.style(size: 12, weight: FontWeight.w700),
      ),
      child: label,
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({
    required this.entries,
    required this.mode,
    required this.onModeChanged,
  });

  final List<LeaderboardEntry> entries;
  final LeaderboardMode mode;
  final ValueChanged<LeaderboardMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = context.palette;
    final friendsById = {for (final f in app.friends) f.id: f};

    return AppCard(
      raised: true,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Weekly leaderboard',
              style: AppFont.style(size: 17, weight: FontWeight.w700, color: p.ink),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedSwitch(
            options: const ['Steps', 'Vs usual'],
            selectedIndex: mode.index,
            onChanged: (index) => onModeChanged(LeaderboardMode.values[index]),
            semanticLabel: 'Rank by',
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              mode == LeaderboardMode.steps
                  ? 'Total steps over the last 7 full days.'
                  : "Ranked against each person's own normal, so everyone can win.",
              style: AppFont.style(size: 12, height: 1.4, color: p.muted),
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < entries.length; i++)
            _LeaderboardRow(
              rank: i + 1,
              entry: entries[i],
              mode: mode,
              friend: friendsById[entries[i].id],
              last: i == entries.length - 1,
            ),
        ],
      ),
    );
  }
}

const _cheerWidth = 78.0;

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.mode,
    required this.friend,
    required this.last,
  });

  final int rank;
  final LeaderboardEntry entry;
  final LeaderboardMode mode;

  /// Null for your own row.
  final Friend? friend;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final friend = this.friend;
    final value = mode == LeaderboardMode.steps
        ? formatThousands(entry.stepsThisWeek)
        : '${entry.percentOfUsual}%';
    final valueNote = mode == LeaderboardMode.steps ? 'steps' : 'of usual';

    final row = Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: entry.isYou ? p.surfaceAccent : null,
        borderRadius: entry.isYou ? BorderRadius.circular(16) : null,
        border: entry.isYou || last ? null : Border(bottom: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              style: AppFont.style(size: 15, weight: FontWeight.w800, color: rank == 1 ? p.ink : p.muted),
            ),
          ),
          if (friend == null)
            const ExcludeSemantics(child: Avatar(size: 36))
          else
            _InitialAvatar(name: friend.name, colors: friendGradient(p, friend.colorIndex)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  overflow: TextOverflow.ellipsis,
                  style: AppFont.style(size: 15, weight: FontWeight.w700, color: p.ink),
                ),
                if (entry.mood != null) ...[
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: MoodBadge(entry.mood!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppFont.style(size: 16, weight: FontWeight.w800, color: p.ink)),
              Text(valueNote, style: AppFont.style(size: 11, color: p.muted)),
            ],
          ),
          const SizedBox(width: 8),
          // Same width on every row, so the values line up.
          SizedBox(
            width: _cheerWidth,
            child: friend == null ? null : _CheerButton(friend: friend),
          ),
        ],
      ),
    );

    if (friend == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showFriendDetails(context, friend),
      child: row,
    );
  }
}

/// A friend's week: mood, steps against their usual, active minutes.
Future<void> showFriendDetails(BuildContext context, Friend friend) {
  final p = context.palette;
  final percent = percentOfUsualWeek(friend.stepsThisWeek, friend.usualDailySteps);
  final shared = [
    for (final metric in SharedMetric.values)
      if (friend.sharesMetric(metric) && metric != SharedMetric.sleep) metric.label.toLowerCase(),
  ];
  final sharedText = switch (shared.length) {
    0 => 'nothing yet',
    1 => shared.first,
    _ => '${shared.sublist(0, shared.length - 1).join(', ')} and ${shared.last}',
  };

  Widget stat(String label, String value, String note) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppFont.style(size: 11, weight: FontWeight.w700, letterSpacing: 1.6, color: p.muted),
            ),
            const SizedBox(height: 6),
            Text(value, style: AppFont.style(size: 24, weight: FontWeight.w800, letterSpacing: -0.8, color: p.ink)),
            const SizedBox(height: 2),
            Text(note, style: AppFont.style(size: 12, color: p.muted)),
          ],
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: p.surfaceRaised,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _InitialAvatar(name: friend.name, colors: friendGradient(p, friend.colorIndex), size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        style: AppFont.style(size: 28, weight: FontWeight.w800, letterSpacing: -1, height: 1, color: p.ink),
                      ),
                      const SizedBox(height: 6),
                      if (friend.sharesMetric(SharedMetric.mood))
                        MoodBadge(moodFromRecovery(friend.recovery))
                      else
                        Text('Mood not shared', style: AppFont.style(size: 12, color: p.muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  stat(
                    'STEPS THIS WEEK',
                    formatThousands(friend.stepsThisWeek),
                    '$percent% of their usual',
                  ),
                  const SizedBox(width: 10),
                  friend.sharesMetric(SharedMetric.activeMinutes)
                      ? stat('ACTIVE MINUTES', '${friend.activeMinutesThisWeek}', 'this week')
                      : stat('ACTIVE MINUTES', '—', 'Not shared'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Their usual is ${formatThousands(friend.usualDailySteps)} steps a day.',
              style: AppFont.style(size: 13, color: p.muted),
            ),
            const SizedBox(height: 14),
            Text(
              'What ${friend.name} shares with you',
              style: AppFont.style(size: 15, weight: FontWeight.w700, color: p.ink),
            ),
            const SizedBox(height: 4),
            Text(
              '${sharedText[0].toUpperCase()}${sharedText.substring(1)}. '
              'Never sleep or heart data.',
              style: AppFont.style(size: 13, height: 1.4, color: p.muted),
            ),
            const SizedBox(height: 18),
            _CheerButton(friend: friend, large: true),
          ],
        ),
      ),
    ),
  );
}

class _SharedGoalCard extends StatelessWidget {
  const _SharedGoalCard();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = context.palette;
    final goal = app.sharedGoal;
    final friend = app.friends.where((f) => f.id == goal.friendId).firstOrNull;
    if (friend == null) return const SizedBox.shrink();

    final progress = sharedGoalProgress(
      goal,
      yourDailySteps: yourFullDaySteps(app.days),
      friendDailySteps: friend.weekSteps.reversed.toList(),
    );
    final friendColors = friendGradient(p, friend.colorIndex);

    Widget share(String name, int steps, List<Color> colors) {
      return Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: colors)),
          ),
          const SizedBox(width: 8),
          Text('$name: ${formatThousands(steps)}', style: AppFont.style(size: 13, weight: FontWeight.w600, color: p.ink)),
        ],
      );
    }

    final yourShare = progress.targetSteps <= 0
        ? 0.0
        : (progress.yourSteps / progress.targetSteps).clamp(0.0, 1.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SHARED GOAL',
            style: AppFont.style(size: 11, weight: FontWeight.w700, letterSpacing: 1.6, color: p.muted),
          ),
          const SizedBox(height: 6),
          Text(
            'You + ${friend.name}: ${formatThousands(goal.targetSteps)} steps this week',
            style: AppFont.style(size: 16, weight: FontWeight.w700, height: 1.3, color: p.ink),
          ),
          const SizedBox(height: 14),
          Semantics(
            label: '${(progress.fraction * 100).round()}% of the goal',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                height: 10,
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: p.track)),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: constraints.maxWidth * progress.fraction,
                        child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: friendColors))),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: constraints.maxWidth * yourShare,
                        child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: p.brand))),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              share('You', progress.yourSteps, p.brand),
              share(friend.name, progress.friendSteps, friendColors),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            progress.reached
                ? 'Goal reached. Nice work, both of you.'
                : '${formatThousands(progress.stepsToGo)} to go · '
                    '${progress.daysLeft} ${progress.daysLeft == 1 ? 'day' : 'days'} left',
            style: AppFont.style(size: 12, color: p.muted),
          ),
        ],
      ),
    );
  }
}

class _AddFriendCard extends StatelessWidget {
  const _AddFriendCard();

  void _copy(BuildContext context, String code) {
    // Copying is instant, so the snackbar does not wait for it.
    unawaited(Clipboard.setData(ClipboardData(text: code)));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Copied')));
  }

  Future<void> _addWithCode(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _AddFriendDialog(),
    );
    if (name == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$name is now your friend')));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = context.palette;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add a friend', style: AppFont.style(size: 15, weight: FontWeight.w700, color: p.ink)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            decoration: BoxDecoration(
              color: p.isDark ? p.background : p.track,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your invite code', style: AppFont.style(size: 12, color: p.muted)),
                      const SizedBox(height: 2),
                      Text(
                        app.inviteCode,
                        style: AppFont.style(size: 18, weight: FontWeight.w800, letterSpacing: 1.6, color: p.ink),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _copy(context, app.inviteCode),
                  icon: Icon(Icons.copy_rounded, size: 18, color: p.ink),
                  label: Text('Copy', style: AppFont.style(size: 13, weight: FontWeight.w700, color: p.ink)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _addWithCode(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: p.ink,
              side: BorderSide(color: p.border),
              shape: const StadiumBorder(),
              minimumSize: const Size(double.infinity, 44),
            ),
            child: Text('Add with a code', style: AppFont.style(size: 13, weight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          Text(
            'Friends see only what you share in the You tab.',
            style: AppFont.style(size: 12, color: p.muted),
          ),
        ],
      ),
    );
  }
}

/// Asks for a friend's code. Pops with the new friend's name when added.
class _AddFriendDialog extends StatefulWidget {
  const _AddFriendDialog();

  @override
  State<_AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<_AddFriendDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final app = AppScope.of(context);
    final before = app.friends.length;
    switch (app.addFriendWithCode(_controller.text)) {
      case AddFriendResult.added:
        Navigator.of(context).pop(app.friends[before].name);
      case AddFriendResult.invalidCode:
        setState(() => _error = 'Codes look like BEFIT-7K2Q.');
      case AddFriendResult.alreadyFriends:
        setState(() => _error = "You're already friends.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      title: Text(
        'Add with a code',
        style: AppFont.style(size: 20, weight: FontWeight.w800, color: p.ink),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Type your friend's invite code.",
            style: AppFont.style(size: 14, height: 1.4, color: p.muted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            style: AppFont.style(size: 16, weight: FontWeight.w700, letterSpacing: 1.2, color: p.ink),
            decoration: InputDecoration(
              hintText: 'BEFIT-XXXX',
              errorText: _error,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
