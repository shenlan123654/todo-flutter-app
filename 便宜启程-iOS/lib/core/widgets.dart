import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/settings_controller.dart';
import 'theme.dart';

class SpacePainter extends CustomPainter {
  SpacePainter({required this.showPlanet});

  final bool showPlanet;
  static final _random = math.Random(20261105);
  static final List<_Star> _stars = List.generate(110, (_) {
    return _Star(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      radius: 0.4 + _random.nextDouble() * 1.6,
      alpha: 0.2 + _random.nextDouble() * 0.7,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF03060D), Color(0xFF061024), Color(0xFF081226), Color(0xFF03070F)],
        ).createShader(rect),
    );

    if (showPlanet) {
      final center = Offset(size.width * 1.04, -size.height * 0.03);
      final radius = size.width * 0.72;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: const [Color(0xFF2B4F80), Color(0xFF152F55), Color(0xFF0A1730), Color(0x000A1730)],
            stops: const [0.0, 0.45, 0.75, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x2E7FB7FF),
      );
    }

    for (final star in _stars) {
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        Paint()..color = Colors.white.withValues(alpha: star.alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SpacePainter oldDelegate) => false;
}

class _Star {
  const _Star({required this.x, required this.y, required this.radius, required this.alpha});
  final double x;
  final double y;
  final double radius;
  final double alpha;
}

class PageBackground extends StatelessWidget {
  const PageBackground({super.key, required this.home, required this.child});
  final bool home;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>().settings;
    final path = home ? settings.homeBackground : settings.otherBackground;
    final file = path == null ? null : File(path);
    final exists = file != null && file.existsSync();
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: SpacePainter(showPlanet: home)),
        if (exists) ...[
          Image.file(file, fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: settings.backgroundDim)),
        ],
        child,
      ],
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, this.child, this.padding = const EdgeInsets.all(16), this.onTap});
  final Widget? child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0x990B1730),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 106,
    this.stroke = 9,
    this.child,
  });

  final double progress;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0, 1)),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(value: value, stroke: stroke),
              );
            },
          ),
          child ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.stroke});
  final double value;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = stroke / 2;
    final rect = Rect.fromLTWH(inset, inset, size.width - stroke, size.height - stroke);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.10),
    );
    if (value <= 0.001) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 2.1
        ..strokeCap = StrokeCap.round
        ..color = SpaceColors.accent.withValues(alpha: 0.25),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [SpaceColors.accentSoft, SpaceColors.accent],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.value != value;
}

class GlowBar extends StatelessWidget {
  const GlowBar({super.key, required this.progress, this.height = 8});
  final double progress;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: Colors.white.withValues(alpha: 0.08),
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress.clamp(0, 1)),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return FractionallySizedBox(
              widthFactor: value,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [SpaceColors.accent, SpaceColors.accentSoft]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class TaskCheckbox extends StatelessWidget {
  const TaskCheckbox({
    super.key,
    required this.checked,
    required this.style,
    required this.onToggle,
  });

  final bool checked;
  final CheckboxStyle style;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isRound = style == CheckboxStyle.rounded || style == CheckboxStyle.dot;
    final size = style == CheckboxStyle.dot ? 26.0 : 28.0;
    final fill = style == CheckboxStyle.outline ? Colors.transparent : (checked ? SpaceColors.accent : Colors.transparent);
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fill,
          shape: isRound ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isRound ? null : BorderRadius.circular(7),
          border: Border.all(
            color: checked ? SpaceColors.accent : Colors.white.withValues(alpha: 0.30),
            width: 1.5,
          ),
        ),
        child: Center(
          child: checked
              ? Icon(
                  Icons.check,
                  size: 18,
                  color: style == CheckboxStyle.outline ? SpaceColors.accent : Colors.white,
                )
              : (style == CheckboxStyle.dot
                  ? Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: SpaceColors.accent, shape: BoxShape.circle),
                    )
                  : null),
        ),
      ),
    );
  }
}

class QichengBottomBar extends StatelessWidget {
  const QichengBottomBar({
    super.key,
    required this.index,
    required this.onChanged,
    required this.items,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final List<BottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE6081224), Color(0xF4050B18)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0x334DA3FF), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == index;
              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: selected ? SpaceColors.accent : const Color(0xFF7C93B3),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: selected ? SpaceColors.accent : const Color(0xFF7C93B3),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 16,
                        height: 2,
                        decoration: BoxDecoration(
                          color: selected ? SpaceColors.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  const BottomNavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(text, style: const TextStyle(fontSize: 13, color: SpaceColors.muted)),
    );
  }
}

class SettingSwitchRow extends StatelessWidget {
  const SettingSwitchRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, color: textColor)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: SpaceColors.muted)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFF04101F),
              activeTrackColor: SpaceColors.accent,
              inactiveThumbColor: const Color(0xFFB9CCE3),
              inactiveTrackColor: const Color(0xFF22314A),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingNavRow extends StatelessWidget {
  const SettingNavRow({
    super.key,
    required this.title,
    required this.value,
    this.onTap,
    this.valueColor,
  });

  final String title;
  final String value;
  final VoidCallback? onTap;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(title, style: TextStyle(fontSize: 15, color: textColor))),
            Text(value, style: TextStyle(fontSize: 12, color: valueColor ?? SpaceColors.muted)),
            const SizedBox(width: 6),
            const Text('›', style: TextStyle(fontSize: 16, color: SpaceColors.muted)),
          ],
        ),
      ),
    );
  }
}

class RowDivider extends StatelessWidget {
  const RowDivider({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Colors.white.withValues(alpha: 0.06));
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 88});
  final double size;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>().settings;
    final logo = settings.logoPath;
    final file = logo == null ? null : File(logo);
    if (file != null && file.existsSync()) {
      return ClipOval(
        child: Image.file(file, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return ClipOval(
      child: Image.asset(
        'assets/images/branding_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandLogo(size: 76),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(fontSize: 15, color: Colors.white)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: SpaceColors.muted)),
      ],
    );
  }
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = '确定',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF0B1730),
      title: Text(title, style: const TextStyle(fontSize: 17, color: Colors.white)),
      content: Text(message, style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFFB9CCE3))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消', style: TextStyle(color: SpaceColors.muted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? SpaceColors.danger : SpaceColors.accent,
            foregroundColor: destructive ? Colors.white : const Color(0xFF04101F),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}
