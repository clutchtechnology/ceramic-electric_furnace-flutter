import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home.dart';
import 'models/app_state.dart';
import 'api/index.dart';
import 'api/valve_api.dart';
import 'api/status_service.dart';
import 'providers/realtime_config_provider.dart';
import 'theme/app_theme.dart';

// 全局配置 Provider 实例
final realtimeConfigProvider = RealtimeConfigProvider();

// 主题状态管理
class ThemeManager {
  static const String _themeKey = 'app_theme_mode';
  static ThemeMode _currentThemeMode = ThemeMode.dark;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? true;
    _currentThemeMode = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static ThemeMode get currentThemeMode => _currentThemeMode;

  static Future<void> setThemeMode(ThemeMode mode) async {
    _currentThemeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, mode == ThemeMode.dark);
  }

  static bool isDarkMode() => _currentThemeMode == ThemeMode.dark;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化全局状态管理
  await AppState.initialize();

  // 初始化主题配置
  await ThemeManager.init();

  // 初始化配置 Provider (加载持久化配置)
  await realtimeConfigProvider.loadConfig();

  // 初始化窗口管理器 - 全屏模式（工控机专用）
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // 隐藏原生标题栏
      windowButtonVisibility: false, // 隐藏原生窗口按钮
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setResizable(false); // 禁止调整大小
      await windowManager.setFullScreen(true); // 启用全屏模式
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// 主题状态管理
class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeManager.currentThemeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3号电炉系统',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: const DigitalTwinPage(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'), // 中文简体
      ],
      locale: const Locale('zh', 'CN'),
    );
  }

  /// 切换主题
  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
    ThemeManager.setThemeMode(_themeMode);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 预缓存电炉图片，确保打开页面时立即显示
    precacheImage(const AssetImage('assets/images/furnace.png'), context);
  }
}
