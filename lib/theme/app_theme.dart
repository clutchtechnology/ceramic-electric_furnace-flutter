import 'package:flutter/material.dart';

/// ============================================================================
/// 应用主题配置 (App Theme Configuration)
/// ============================================================================
///
/// 奥卡姆剃刀原则：单文件集中管理配色，零额外依赖
/// 使用 Flutter 原生 ThemeData + Theme.of(context) 实现主题切换
///
/// 配色方案：
///   - 深色主题：科技风格（青色发光边框）
///   - 浅色主题：绿色系（清新工业风格）
/// ============================================================================

class AppTheme {
  // ===== 深色主题（当前科技风格）=====
  static const _darkBgDeep = Color(0xFF0d1117);
  static const _darkBgDark = Color(0xFF161b22);
  static const _darkBgMedium = Color(0xFF21262d);
  static const _darkBgLight = Color(0xFF30363d);
  static const _darkBorderDark = Color(0xFF30363d);
  static const _darkBorderGlow = Color(0xFF00d4ff);
  static const _darkGridLine = Color(0xFF21262d);
  static const _darkGlowCyan = Color(0xFF00d4ff);
  static const _darkGlowCyanLight = Color(0xFF00f0ff);
  static const _darkGlowGreen = Color(0xFF00ff88);
  static const _darkGlowOrange = Color(0xFFff9500);
  static const _darkGlowRed = Color(0xFFff3b30);
  static const _darkGlowBlue = Color(0xFF0088ff);
  static const _darkTextPrimary = Color(0xFFe6edf3);
  static const _darkTextSecondary = Color(0xFF8b949e);
  static const _darkTextMuted = Color(0xFF484f58);
  static const _darkStatusNormal = Color(0xFF00ff88);
  static const _darkStatusWarning = Color(0xFFffcc00);
  static const _darkStatusAlarm = Color(0xFFff3b30);
  static const _darkStatusOffline = Color(0xFF484f58);

  // ===== 浅色主题（绿色系）=====
  static const _lightBgDeep = Color(0xFFe9eea8);
  static const _lightBgDark = Color(0xFFf2fedc);
  static const _lightBgMedium = Color(0xFFfafbe7);
  static const _lightBgLight = Color(0xFFffffff);
  static const _lightBorderDark = Color(0xFFd5a339);
  static const _lightBorderGlow = Color(0xFF007663);
  static const _lightGridLine = Color(0xFFe0e8d8);
  static const _lightGlowCyan = Color(0xFF007663);
  static const _lightGlowCyanLight = Color(0xFF008b67);
  static const _lightGlowGreen = Color(0xFF008b67);
  static const _lightGlowOrange = Color(0xFFd5a339);
  static const _lightGlowRed = Color(0xFFb95d3b);
  static const _lightGlowBlue = Color(0xFF007663);
  static const _lightTextPrimary = Color(0xFF1b3d2f);
  static const _lightTextSecondary = Color(0xFF474838);
  static const _lightTextMuted = Color(0xFF8b949e);
  static const _lightStatusNormal = Color(0xFF008b67);
  static const _lightStatusWarning = Color(0xFFd5a339);
  static const _lightStatusAlarm = Color(0xFFb95d3b);
  static const _lightStatusOffline = Color(0xFF8b949e);

  // ===== 深色主题 =====
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _darkBgDark,
        primaryColor: _darkBorderGlow,
        colorScheme: const ColorScheme.dark(
          primary: _darkBorderGlow,
          secondary: _darkGlowGreen,
          error: _darkGlowRed,
          surface: _darkBgMedium,
          onSurface: _darkTextPrimary,
          onPrimary: _darkBgDark,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: _darkTextPrimary),
          bodyMedium: TextStyle(color: _darkTextSecondary),
          bodySmall: TextStyle(color: _darkTextMuted),
          titleLarge: TextStyle(color: _darkTextPrimary),
          titleMedium: TextStyle(color: _darkTextPrimary),
          titleSmall: TextStyle(color: _darkTextSecondary),
        ),
        cardTheme: CardThemeData(
          color: _darkBgMedium,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: _darkBorderGlow, width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkBgDark,
          foregroundColor: _darkTextPrimary,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: _darkBorderDark,
          thickness: 1,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _darkGlowGreen;
            }
            return _darkTextMuted;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _darkGlowGreen.withOpacity(0.5);
            }
            return _darkBorderDark;
          }),
        ),
      );

  // ===== 浅色主题 =====
  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: _lightBgDeep,
        primaryColor: _lightBorderGlow,
        colorScheme: const ColorScheme.light(
          primary: _lightBorderGlow,
          secondary: _lightGlowGreen,
          error: _lightGlowRed,
          surface: _lightBgMedium,
          onSurface: _lightTextPrimary,
          onPrimary: _lightBgLight,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: _lightTextPrimary),
          bodyMedium: TextStyle(color: _lightTextSecondary),
          bodySmall: TextStyle(color: _lightTextMuted),
          titleLarge: TextStyle(color: _lightTextPrimary),
          titleMedium: TextStyle(color: _lightTextPrimary),
          titleSmall: TextStyle(color: _lightTextSecondary),
        ),
        cardTheme: CardThemeData(
          color: _lightBgLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: _lightBorderGlow, width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _lightBgDeep,
          foregroundColor: _lightTextPrimary,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: _lightBorderDark,
          thickness: 1,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _lightGlowGreen;
            }
            return _lightTextMuted;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _lightGlowGreen.withOpacity(0.5);
            }
            return _lightBorderDark;
          }),
        ),
      );

  // ===== 扩展颜色访问器（用于自定义组件）=====

  /// 背景层级
  static Color bgDeep(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkBgDeep
          : _lightBgDeep;

  static Color bgDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkBgDark
          : _lightBgDark;

  static Color bgMedium(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkBgMedium
          : _lightBgMedium;

  static Color bgLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkBgLight
          : _lightBgLight;

  /// 边框与线条
  static Color borderDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkBorderDark
          : _lightBorderDark;

  static Color borderGlow(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkBorderGlow
          : _lightBorderGlow;

  static Color gridLine(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkGridLine
          : _lightGridLine;

  /// 发光色
  static Color glowCyan(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkGlowCyan
          : _lightGlowCyan;

  static Color glowCyanLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkGlowCyanLight
          : _lightGlowCyanLight;

  static Color glowGreen(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkGlowGreen
          : _lightGlowGreen;

  static Color glowOrange(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkGlowOrange
          : _lightGlowOrange;

  static Color glowRed(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkGlowRed
          : _lightGlowRed;

  static Color glowBlue(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkGlowBlue
          : _lightGlowBlue;

  /// 文字
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkTextPrimary
          : _lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkTextSecondary
          : _lightTextSecondary;

  static Color textMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkTextMuted
          : _lightTextMuted;

  /// 状态色
  static Color statusNormal(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkStatusNormal
          : _lightStatusNormal;

  static Color statusWarning(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkStatusWarning
          : _lightStatusWarning;

  static Color statusAlarm(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkStatusAlarm
          : _lightStatusAlarm;

  static Color statusOffline(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkStatusOffline
          : _lightStatusOffline;
}
