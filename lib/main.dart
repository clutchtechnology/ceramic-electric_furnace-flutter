import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'pages/home.dart';
import 'models/app_state.dart';
import 'api/index.dart';
import 'api/valve_api.dart';
import 'api/status_service.dart';
import 'providers/realtime_config_provider.dart';

// 全局配置 Provider 实例
final realtimeConfigProvider = RealtimeConfigProvider();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化全局状态管理
  await AppState.initialize();

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

/// [CRITICAL] 使用 WidgetsBindingObserver 监听应用生命周期
/// Windows 桌面应用关闭时，进程可能被直接杀死，dispose() 可能不会执行
/// 因此需要在 didChangeAppLifecycleState 中清理资源
/// 
/// [CRITICAL] 使用 WindowListener 监听窗口事件
/// 当窗口从最小化恢复时，自动设置为全屏模式
class _MyAppState extends State<MyApp> with WidgetsBindingObserver, WindowListener {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 添加窗口事件监听器
    windowManager.addListener(this);
  }

  /// 窗口从最小化恢复时自动全屏
  @override
  void onWindowRestore() {
    debugPrint('[MyApp] 窗口恢复，设置全屏模式');
    windowManager.setFullScreen(true);
  }

  /// 窗口获得焦点时确保全屏
  @override
  void onWindowFocus() {
    // 延迟检查，确保窗口状态稳定后再设置全屏
    Future.delayed(const Duration(milliseconds: 100), () async {
      final isFullScreen = await windowManager.isFullScreen();
      final isMinimized = await windowManager.isMinimized();
      if (!isFullScreen && !isMinimized) {
        debugPrint('[MyApp] 窗口获得焦点但非全屏，恢复全屏模式');
        await windowManager.setFullScreen(true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 预缓存电炉图片，确保打开页面时立即显示
    precacheImage(const AssetImage('assets/images/furnace.png'), context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Windows 应用进入后台或被关闭时清理资源
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _cleanupResources();
    }
  }

  /// 清理所有网络资源
  void _cleanupResources() {
    debugPrint('[MyApp] 正在清理网络资源...');
    try {
      // 释放所有 HTTP Client
      ApiClient.dispose();
      ValveApi().dispose();
      StatusService().dispose();
      debugPrint('[MyApp] 网络资源清理完成');
    } catch (e) {
      debugPrint('[MyApp] 清理资源时发生错误: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    windowManager.removeListener(this); // 移除窗口监听器
    _cleanupResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3号电炉系统',
      theme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
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
}
