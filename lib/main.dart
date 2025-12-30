import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'pages/home.dart';
import 'models/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化全局状态管理
  await AppState.initialize();

  // 初始化窗口管理器 - 隐藏原生标题栏，使用自定义标题栏
  // 设置为19寸5:4固定窗口 (1280x1024)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    // 5:4横屏比例 = 1280x1024
    const fixedSize = Size(1280, 1024);

    WindowOptions windowOptions = const WindowOptions(
      size: fixedSize,
      minimumSize: fixedSize, // 固定最小尺寸
      maximumSize: fixedSize, // 固定最大尺寸，禁止放大
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // 隐藏原生标题栏
      windowButtonVisibility: false, // 隐藏原生窗口按钮
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setResizable(false); // 禁止调整大小
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

class _MyAppState extends State<MyApp> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 预缓存电炉图片，确保打开页面时立即显示
    precacheImage(const AssetImage('assets/images/furnace.png'), context);
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
