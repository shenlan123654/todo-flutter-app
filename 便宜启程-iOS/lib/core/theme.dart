import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SpaceColors {
  static const deepSpace = Color(0xFF04070F);
  static const navy = Color(0xFF081226);
  static const card = Color(0xCC0B1A33);
  static const accent = Color(0xFF4DA3FF);
  static const accentSoft = Color(0xFF8FD8FF);
  static const gold = Color(0xFFF0D7A0);
  static const danger = Color(0xFFFF6B7A);
  static const muted = Color(0xFF8FA9C9);
}

ThemeData buildAppTheme(int fontColor) {
  final text = Color(fontColor);
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'Noto Sans CJK SC'],
  );
  return base.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: ColorScheme.dark(
      primary: SpaceColors.accent,
      onPrimary: const Color(0xFF04101F),
      secondary: SpaceColors.accentSoft,
      onSecondary: const Color(0xFF04101F),
      surface: SpaceColors.navy,
      onSurface: text,
      surfaceContainerHighest: const Color(0xFF0B1730),
      onSurfaceVariant: text.withValues(alpha: 0.62),
      outline: SpaceColors.accent.withValues(alpha: 0.35),
      error: SpaceColors.danger,
      onError: const Color(0xFF1A0307),
    ),
    textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
    dividerColor: Colors.white.withValues(alpha: 0.06),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

String two(int n) => n.toString().padLeft(2, '0');

String timeLabel(DateTime time) => '${two(time.hour)}:${two(time.minute)}';

String dateLabel(DateTime date) => '${date.month}月${date.day}日';

String fullDateLabel(DateTime date) {
  const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  return '${date.month}月${date.day}日 周${weekdays[date.weekday - 1]}';
}
