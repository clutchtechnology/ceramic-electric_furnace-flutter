import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:async';
import '../widgets/common/tech_line_widgets.dart';
import '../widgets/common/health_status.dart';
import '../models/app_state.dart';
import '../api/control_api.dart'; // 新增：控制 API
import 'realtime_data_page.dart';
// import 'realtime_monitor_page.dart'; // 暂时隐藏
import 'history_curve_page.dart';
import 'alarm_record_page.dart';
import 'settings_page.dart';
import 'status_page.dart'; // 合并的状态页面

/// 智能生产线数字孪生系统页面
/// 参考工业 SCADA/数字孪生可视化设计
class DigitalTwinPage extends StatefulWidget {
  const DigitalTwinPage({super.key});

  @override
  State<DigitalTwinPage> createState() => _DigitalTwinPageState();
}

class _DigitalTwinPageState extends State<DigitalTwinPage> {
  int _selectedNavIndex = 0;

  // 时钟定时器（替代 StreamBuilder 防止内存泄漏）
  Timer? _clockTimer;
  String _timeString = '';
  String _dateString = '';

  // 健康状态组件 Key（用于获取状态）
  final GlobalKey<HealthStatusWidgetState> _healthStatusKey =
      GlobalKey<HealthStatusWidgetState>();

  // 实时数据页面 Key（用于刷新数据）
  final GlobalKey<RealtimeDataPageState> _realtimeDataPageKey =
      GlobalKey<RealtimeDataPageState>();

  // 状态页面 Key (合并了 DB30 + DB41)
  final GlobalKey<StatusPageState> _statusPageKey =
      GlobalKey<StatusPageState>();

  // 系统就绪状态（后端+PLC都正常）
  bool _isSystemReady = false;

  // 刷新按钮状态
  bool _isRefreshing = false;

  // 轮询控制状态
  bool _isPollingRunning = false;
  String? _currentBatchCode;
  bool _isStarting = false;
  bool _isStopping = false;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateTime();
    });
    // 启动时查询轮询状态
    _checkPollingStatus();
  }

  void _updateTime() {
    final now = DateTime.now();
    final newTimeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final newDateString =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (_timeString != newTimeString || _dateString != newDateString) {
      setState(() {
        _timeString = newTimeString;
        _dateString = newDateString;
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _clockTimer = null;
    super.dispose();
  }

  /// 健康状态变化回调
  /// 【修改】只需要后端连接即可开始轮询，不需要 PLC 连接
  void _onHealthStatusChanged(bool isBackendHealthy, bool isPlcHealthy) {
    // 只检查后端连接，不检查 PLC 连接
    // PLC 连接状态由后端轮询服务自行处理（容错模式）
    final newSystemReady = isBackendHealthy;
    if (_isSystemReady != newSystemReady) {
      setState(() {
        _isSystemReady = newSystemReady;
      });
      // 同步到全局状态
      AppState.instance.updateSystemReady(newSystemReady);
    }
  }

  /// 查询轮询状态
  Future<void> _checkPollingStatus() async {
    try {
      final status = await ControlApi.getStatus();
      if (mounted) {
        setState(() {
          _isPollingRunning = status.isRunning;
          _currentBatchCode = status.batchCode;
        });
      }
    } catch (e) {
      print('查询轮询状态失败: $e');
    }
  }

  /// 开始验连
  Future<void> _startSmelting() async {
    if (_isStarting || _isPollingRunning) return;

    setState(() => _isStarting = true);

    try {
      // 生成批次号
      final batchCode = ControlApi.generateBatchCode();

      // 调用后端 API 启动轮询
      final response = await ControlApi.startPolling(batchCode);

      if (mounted) {
        setState(() {
          _isPollingRunning = true;
          _currentBatchCode = response.batchCode;
          _isStarting = false;
        });

        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 轮询已启动 | 批次号: ${response.batchCode}'),
            backgroundColor: TechColors.statusNormal,
            duration: const Duration(seconds: 3),
          ),
        );

        // 刷新实时数据页面
        _realtimeDataPageKey.currentState?.resumePolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isStarting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 启动失败: $e'),
            backgroundColor: TechColors.statusAlarm,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 停止验连
  Future<void> _stopSmelting() async {
    if (_isStopping || !_isPollingRunning) return;

    setState(() => _isStopping = true);

    try {
      final response = await ControlApi.stopPolling();

      if (mounted) {
        setState(() {
          _isPollingRunning = false;
          _currentBatchCode = null;
          _isStopping = false;
        });

        // 显示成功提示
        final duration = response.durationSeconds != null
            ? '${(response.durationSeconds! / 60).toStringAsFixed(1)} 分钟'
            : '未知';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🛑 轮询已停止 | 批次号: ${response.batchCode} | 运行时长: $duration'),
            backgroundColor: TechColors.statusWarning,
            duration: const Duration(seconds: 3),
          ),
        );

        // 暂停实时数据页面
        _realtimeDataPageKey.currentState?.pausePolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isStopping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 停止失败: $e'),
            backgroundColor: TechColors.statusAlarm,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 导航项点击回调
  void _onNavItemTap(int index) {
    if (_selectedNavIndex == index) return;

    // 离开当前页面时暂停轮询
    if (_selectedNavIndex == 0) {
      _realtimeDataPageKey.currentState?.pausePolling();
    } else if (_selectedNavIndex == 3) {
      _statusPageKey.currentState?.pausePolling();
    }

    setState(() {
      _selectedNavIndex = index;
    });

    // 进入新页面时恢复轮询
    if (index == 0) {
      _realtimeDataPageKey.currentState?.resumePolling();
    } else if (index == 3) {
      _statusPageKey.currentState?.resumePolling();
    }
  }

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
                children: [
                  RealtimeDataPage(key: _realtimeDataPageKey), // 0: 实时数据
                  // RealtimeMonitorPage(), // 1: 实时监控 (暂时隐藏)
                  const HistoryCurvePage(), // 1: 历史曲线
                  const AlarmRecordPage(), // 2: 报警记录
                  StatusPage(key: _statusPageKey), // 3: 设备状态 (合并 DB30+DB41)
                  const SettingsPage(), // 4: 系统设置
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
    final navItems = ['数据大屏', '历史曲线', '报警记录', '设备状态'];

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
                      fontSize: 10,
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
                onTap: () => _onNavItemTap(index),
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
            // 时间显示 + 健康状态
            _buildClockDisplay(),
            const SizedBox(width: 12),
            // 系统配置按钮
            IconButton(
              onPressed: () => _onNavItemTap(4),
              icon: Icon(
                Icons.settings,
                color: _selectedNavIndex == 4
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
                // 先退出全屏模式，再最小化
                if (await windowManager.isFullScreen()) {
                  await windowManager.setFullScreen(false);
                }
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
    // 使用 Timer + setState 替代 StreamBuilder 防止内存泄漏
    return Row(
      children: [
        // 刷新数据按钮（仅在实时数据页面显示）
        if (_selectedNavIndex == 0) ...[
          _buildRefreshButton(),
          const SizedBox(width: 12),
        ],
        // 健康状态指示器
        HealthStatusWidget(
          key: _healthStatusKey,
          onStatusChanged: _onHealthStatusChanged,
        ),
        const SizedBox(width: 12),
        // 时间
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
            _timeString.isEmpty ? '--:--:--' : _timeString,
            style: TextStyle(
              color: TechColors.glowCyan,
              fontSize: 14,
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
  }

  /// 构建刷新按钮
  Widget _buildRefreshButton() {
    return InkWell(
      onTap: _isRefreshing
          ? null
          : () async {
              setState(() => _isRefreshing = true);
              // 调用实时数据页面的刷新方法
              await _realtimeDataPageKey.currentState?.refreshData();
              if (mounted) {
                setState(() => _isRefreshing = false);
              }
            },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _isRefreshing
              ? TechColors.bgMedium
              : TechColors.glowOrange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _isRefreshing
                ? TechColors.borderDark
                : TechColors.glowOrange.withOpacity(0.6),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRefreshing)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    TechColors.glowOrange,
                  ),
                ),
              )
            else
              Icon(
                Icons.refresh,
                size: 16,
                color: TechColors.glowOrange,
              ),
            const SizedBox(width: 6),
            Text(
              _isRefreshing ? '刷新中...' : '刷新数据',
              style: TextStyle(
                color: _isRefreshing
                    ? TechColors.textSecondary
                    : TechColors.glowOrange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto Mono',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 开始验连按钮
  Widget _buildStartButton() {
    return MouseRegion(
      cursor: _isStarting ? SystemMouseCursors.wait : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _isStarting ? null : _startSmelting,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isStarting
                  ? [Colors.grey.shade700, Colors.grey.shade800]
                  : [TechColors.statusNormal, TechColors.statusNormal.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _isStarting
                  ? Colors.grey.shade600
                  : TechColors.statusNormal.withOpacity(0.5),
            ),
            boxShadow: _isStarting
                ? []
                : [
                    BoxShadow(
                      color: TechColors.statusNormal.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isStarting)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(
                  Icons.play_circle_outline,
                  size: 16,
                  color: Colors.white,
                ),
              const SizedBox(width: 6),
              Text(
                _isStarting ? '启动中...' : '开始验连',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Roboto Mono',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 停止验连按钮
  Widget _buildStopButton() {
    return MouseRegion(
      cursor: _isStopping ? SystemMouseCursors.wait : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _isStopping ? null : _stopSmelting,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isStopping
                  ? [Colors.grey.shade700, Colors.grey.shade800]
                  : [TechColors.statusAlarm, TechColors.statusAlarm.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _isStopping
                  ? Colors.grey.shade600
                  : TechColors.statusAlarm.withOpacity(0.5),
            ),
            boxShadow: _isStopping
                ? []
                : [
                    BoxShadow(
                      color: TechColors.statusAlarm.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isStopping)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(
                  Icons.stop_circle_outlined,
                  size: 16,
                  color: Colors.white,
                ),
              const SizedBox(width: 6),
              Text(
                _isStopping
                    ? '停止中...'
                    : '停止验连 (${_currentBatchCode ?? 'N/A'})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Roboto Mono',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
