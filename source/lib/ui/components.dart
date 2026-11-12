import 'package:flutter/material.dart';

import 'app_font.dart';
import 'palette.dart';

/// A rounded card. [raised] is for the main card of a screen.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.raised = false,
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool raised;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(raised ? 28 : 24);
    final decoration = BoxDecoration(
      color: color ?? (raised ? p.surfaceRaised : p.surface),
      borderRadius: radius,
      border: Border.all(color: borderColor ?? p.border),
      boxShadow: p.isDark
          ? null
          : const [
              BoxShadow(
                color: Color(0x0A15121C),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
              BoxShadow(
                color: Color(0x0F15121C),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
    );
    final content = Padding(padding: padding, child: child);
    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: decoration,
        child: InkWell(borderRadius: radius, onTap: onTap, child: content),
      ),
    );
  }
}

/// Small caps line above a big bold title, with an optional widget right.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.trailing,
    this.titleColor,
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null)
                Text(
                  eyebrow!,
                  style: AppFont.style(
                    size: 12,
                    weight: FontWeight.w600,
                    letterSpacing: 2.4,
                    color: p.muted,
                  ),
                ),
              const SizedBox(height: 4),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: AppFont.style(
                    size: 44,
                    weight: FontWeight.w800,
                    letterSpacing: -1.8,
                    height: 1,
                    color: titleColor ?? p.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// A small rounded label, for example "48 min less".
class DiffChip extends StatelessWidget {
  const DiffChip(this.text, {super.key, required this.background, required this.foreground});

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppFont.style(size: 12, weight: FontWeight.w700, color: foreground),
      ),
    );
  }
}

/// The main button of a screen: a large high-contrast pill.
class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: p.ink,
          foregroundColor: p.background,
          shape: const StadiumBorder(),
          textStyle: AppFont.style(size: 17, weight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

/// A row of options where one is selected, for example Day / Week / Month.
class SegmentedSwitch extends StatelessWidget {
  const SegmentedSwitch({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    this.selectedGradient,
    this.semanticLabel,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Fill for the selected option. Without it, a quiet fill is used.
  final List<Color>? selectedGradient;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: p.isDark ? p.background : p.track,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++)
              Expanded(
                child: Semantics(
                  selected: i == selectedIndex,
                  button: true,
                  child: GestureDetector(
                    onTap: () => onChanged(i),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: i == selectedIndex && selectedGradient == null
                            ? (p.isDark ? p.navSelected : p.surface)
                            : null,
                        gradient: i == selectedIndex && selectedGradient != null
                            ? LinearGradient(colors: selectedGradient!)
                            : null,
                      ),
                      child: Text(
                        options[i],
                        style: AppFont.style(
                          size: 13,
                          weight: i == selectedIndex
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: i == selectedIndex
                              ? (selectedGradient != null
                                  ? Colors.white
                                  : p.ink)
                              : p.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PillNavItem {
  const PillNavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// Bottom navigation. The current tab sits inside a rounded pill, so it is
/// always clear where you are.
class PillNavBar extends StatelessWidget {
  const PillNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<PillNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.navBackground,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                Flexible(
                  child: Semantics(
                    selected: i == selectedIndex,
                    button: true,
                    label: items[i].label,
                    excludeSemantics: true,
                    child: Material(
                      color: i == selectedIndex ? p.navSelected : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => onSelected(i),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 52),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  items[i].icon,
                                  size: 22,
                                  color: i == selectedIndex ? p.ink : p.faint,
                                ),
                                const SizedBox(height: 3),
                                // Shrinks the label a little on very narrow phones.
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    items[i].label,
                                    maxLines: 1,
                                    style: AppFont.style(
                                      size: 11,
                                      weight: i == selectedIndex
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: i == selectedIndex ? p.ink : p.faint,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round "B" avatar with the brand gradient.
class Avatar extends StatelessWidget {
  const Avatar({super.key, this.size = 44, this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: p.brand),
      ),
      child: Text(
        'B',
        style: AppFont.style(
          size: size * 0.38,
          weight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
    if (onTap == null) return circle;
    return Semantics(
      button: true,
      label: 'Open your settings',
      excludeSemantics: true,
      child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: circle),
    );
  }
}

/// The app name: "Be" in ink, "Fit" in the brand gradient, next to the
/// round "B" mark.
class BeFitWordmark extends StatelessWidget {
  const BeFitWordmark({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = AppFont.style(
      size: size,
      weight: FontWeight.w800,
      letterSpacing: -0.8,
      height: 1,
      color: p.ink,
    );
    return Semantics(
      label: 'BeFit',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Avatar(size: size * 1.3),
          SizedBox(width: size * 0.4),
          Text('Be', style: style),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) =>
                LinearGradient(colors: p.brand).createShader(bounds),
            child: Text('Fit', style: style),
          ),
        ],
      ),
    );
  }
}

/// Shows the short privacy notice used by onboarding and the You tab.
Future<void> showPrivacyNotice(BuildContext context) {
  final p = context.palette;
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Privacy notice',
        style: AppFont.style(size: 20, weight: FontWeight.w800, color: p.ink),
      ),
      content: Text(
        'We use your sleep, heart and activity data from your Fitbit Air, '
        'read only. We keep daily summaries, encrypted, and never raw '
        'sensor data. When you ask the coach a question, those summaries '
        'are sent to Claude by Anthropic to write the answer. We never sell '
        'your data or use it for ads. You can export or delete everything '
        'from the You tab, and withdraw your consent at any time. Friends '
        'only see what you choose to share, never your sleep or heart data.\n\n'
        'This is a draft for the course project, not a final legal text.',
        style: AppFont.style(size: 14, height: 1.45, color: p.muted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
