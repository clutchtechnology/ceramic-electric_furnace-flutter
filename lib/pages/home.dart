import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:async';
import '../widgets/common/tech_line_widgets.dart';
import 'realtime_data_page.dart';
// import 'realtime_monitor_page.dart'; // 暂时隐藏
import 'history_curve_page.dart';
import 'alarm_record_page.dart';
import 'settings_page.dart';

/// 智能生产线数字孪生系统页面
/// 参考工业 SCADA/数字孪生可视化设计
class DigitalTwinPage extends StatefulWidget {
  const DigitalTwinPage({super.key});

  @override
  State<DigitalTwinPage> createState() => _DigitalTwinPageState();
}

class _DigitalTwinPageState extends State<DigitalTwinPage> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TechColors.bgDeep,
      body: AnimatedGridBackground(
        gridColor: TechColors.borderDark.withOpacity(0.3),
        gridSize: 40,
        child: Column(
          children: [
            // 顶部导航栏
            _buildTopNavBar(),
            // 主内容区 - 使用 IndexedStack 保持页面状态，避免切换时重建
            Expanded(
              child: IndexedStack(
                index: _selectedNavIndex,
                children: const [
                  RealtimeDataPage(), // 0: 实时数据
                  // RealtimeMonitorPage(), // 1: 实时监控 (暂时隐藏)
                  HistoryCurvePage(), // 1: 历史曲线
                  AlarmRecordPage(), // 2: 报警记录
                  SettingsPage(), // 3: 系统设置
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _buildCurrentPage 方法已移除，由 IndexedStack 替代

  /// 顶部导航栏
  Widget _buildTopNavBar() {
    final navItems = ['数据大屏', '历史曲线', '报警记录'];

    return DragToMoveArea(
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: TechColors.bgDark.withOpacity(0.9),
          border: Border(
            bottom: BorderSide(
              color: TechColors.glowCyan.withOpacity(0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            // Logo/标题
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: TechColors.glowCyan,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: TechColors.glowCyan.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [TechColors.glowCyan, TechColors.glowCyanLight],
                  ).createShader(bounds),
                  child: const Text(
                    '3号电炉系统',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 40),
            // 导航项
            ...List.generate(navItems.length, (index) {
              final isSelected = _selectedNavIndex == index;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _selectedNavIndex = index),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? TechColors.glowCyan.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? TechColors.glowCyan.withOpacity(0.5)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    navItems[index],
                    style: TextStyle(
                      color: isSelected
                          ? TechColors.glowCyan
                          : TechColors.textSecondary,
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            // 时间显示
            _buildClockDisplay(),
            const SizedBox(width: 16),
            // 系统配置按钮
            IconButton(
              onPressed: () => setState(() => _selectedNavIndex = 3),
              icon: Icon(
                Icons.settings,
                color: _selectedNavIndex == 3
                    ? TechColors.glowCyan
                    : TechColors.textSecondary,
                size: 20,
              ),
              splashRadius: 18,
            ),
            const SizedBox(width: 8),
            // 最小化按钮
            IconButton(
              onPressed: () async {
                await windowManager.minimize();
              },
              icon: const Icon(
                Icons.remove,
                color: TechColors.textSecondary,
                size: 20,
              ),
              splashRadius: 18,
              tooltip: '最小化',
            ),
            // 关闭按钮
            IconButton(
              onPressed: () async {
                await windowManager.close();
              },
              icon: const Icon(
                Icons.close,
                color: TechColors.textSecondary,
                size: 20,
              ),
              splashRadius: 18,
              tooltip: '关闭',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockDisplay() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        final dateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        return Row(
          children: [
            Text(
              dateStr,
              style: const TextStyle(
                color: TechColors.textSecondary,
                fontSize: 14,
                fontFamily: 'Roboto Mono',
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: TechColors.bgMedium,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: TechColors.glowCyan.withOpacity(0.3),
                ),
              ),
              child: Text(
                timeStr,
                style: TextStyle(
                  color: TechColors.glowCyan,
                  fontSize: 16,
                  fontFamily: 'Roboto Mono',
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: TechColors.glowCyan.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
