import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:async';
import '../theme/app_theme.dart';
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
            backgroundColor: AppTheme.statusNormal(context),
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
            backgroundColor: AppTheme.statusAlarm(context),
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
            content:
                Text('🛑 轮询已停止 | 批次号: ${response.batchCode} | 运行时长: $duration'),
            backgroundColor: AppTheme.statusWarning(context),
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
            backgroundColor: AppTheme.statusAlarm(context),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 处理关闭窗口
  /// [CRITICAL] 如果正在冶炼，需要二次确认
  Future<void> _handleCloseWindow() async {
    if (_isPollingRunning) {
      // 正在冶炼，弹出二次确认弹窗
      final shouldClose = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTheme.bgDark(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: AppTheme.statusWarning(context).withOpacity(0.5),
                width: 1,
              ),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.statusWarning(context),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  '确认关闭',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '系统当前正在运行数据采集',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgMedium(context),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppTheme.statusNormal(context).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_circle_filled,
                        color: AppTheme.statusNormal(context),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '批次号: ${_currentBatchCode ?? 'N/A'}',
                        style: TextStyle(
                          color: AppTheme.statusNormal(context),
                          fontSize: 14,
                          fontFamily: 'Roboto Mono',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '关闭程序将停止数据采集，确定要关闭吗？',
                  style: TextStyle(
                    color: AppTheme.statusWarning(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  '取消',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 14,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.statusAlarm(context),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  '确认关闭',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (shouldClose == true) {
        // 用户确认关闭，先停止轮询再关闭窗口
        try {
          await ControlApi.stopPolling();
        } catch (e) {
          debugPrint('关闭时停止轮询失败: $e');
        }
        await windowManager.close();
      }
    } else {
      // 未在冶炼，直接关闭
      await windowManager.close();
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
      backgroundColor: AppTheme.bgDeep(context),
      body: AnimatedGridBackground(
        gridColor: AppTheme.borderDark(context).withOpacity(0.3),
        gridSize: 40,
        child: Column(
          children: [
            // 顶部导航栏
            _buildTopNavBar(context),
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
  Widget _buildTopNavBar(BuildContext context) {
    final navItems = ['数据大屏', '历史曲线', '报警记录', '设备状态'];

    return DragToMoveArea(
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.bgDark(context).withOpacity(0.9),
          border: Border(
            bottom: BorderSide(
              color: AppTheme.glowCyan(context).withOpacity(0.3),
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
                    color: AppTheme.glowCyan(context),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.glowCyan(context).withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppTheme.glowCyan(context),
                      AppTheme.glowCyanLight(context)
                    ],
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
                onTap: () => _onNavItemTap(index),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.glowCyan(context).withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.glowCyan(context).withOpacity(0.5)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    navItems[index],
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.glowCyan(context)
                          : AppTheme.textSecondary(context),
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
            _buildClockDisplay(context),
            const SizedBox(width: 12),
            // 系统配置按钮
            IconButton(
              onPressed: () => _onNavItemTap(4),
              icon: Icon(
                Icons.settings,
                color: _selectedNavIndex == 4
                    ? AppTheme.glowCyan(context)
                    : AppTheme.textSecondary(context),
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
              icon: Icon(
                Icons.remove,
                color: AppTheme.textSecondary(context),
                size: 20,
              ),
              splashRadius: 18,
              tooltip: '最小化',
            ),
            // 关闭按钮
            IconButton(
              onPressed: () => _handleCloseWindow(),
              icon: Icon(
                Icons.close,
                color: AppTheme.textSecondary(context),
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

  Widget _buildClockDisplay(BuildContext context) {
    // 使用 Timer + setState 替代 StreamBuilder 防止内存泄漏
    return Row(
      children: [
        // 刷新数据按钮（仅在实时数据页面显示）
        if (_selectedNavIndex == 0) ...[
          _buildRefreshButton(context),
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
            color: AppTheme.bgMedium(context),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppTheme.glowCyan(context).withOpacity(0.3),
            ),
          ),
          child: Text(
            _timeString.isEmpty ? '--:--:--' : _timeString,
            style: TextStyle(
              color: AppTheme.glowCyan(context),
              fontSize: 14,
              fontFamily: 'Roboto Mono',
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: AppTheme.glowCyan(context).withOpacity(0.5),
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
  Widget _buildRefreshButton(BuildContext context) {
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
              ? AppTheme.bgMedium(context)
              : AppTheme.glowOrange(context).withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _isRefreshing
                ? AppTheme.borderDark(context)
                : AppTheme.glowOrange(context).withOpacity(0.6),
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
                    AppTheme.glowOrange(context),
                  ),
                ),
              )
            else
              Icon(
                Icons.refresh,
                size: 16,
                color: AppTheme.glowOrange(context),
              ),
            const SizedBox(width: 6),
            Text(
              _isRefreshing ? '刷新中...' : '刷新数据',
              style: TextStyle(
                color: _isRefreshing
                    ? AppTheme.textSecondary(context)
                    : AppTheme.glowOrange(context),
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
  Widget _buildStartButton(BuildContext context) {
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
                  : [
                      AppTheme.statusNormal(context),
                      AppTheme.statusNormal(context).withOpacity(0.8)
                    ],
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _isStarting
                  ? Colors.grey.shade600
                  : AppTheme.statusNormal(context).withOpacity(0.5),
            ),
            boxShadow: _isStarting
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.statusNormal(context).withOpacity(0.3),
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
  Widget _buildStopButton(BuildContext context) {
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
                  : [
                      AppTheme.statusAlarm(context),
                      AppTheme.statusAlarm(context).withOpacity(0.8)
                    ],
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _isStopping
                  ? Colors.grey.shade600
                  : AppTheme.statusAlarm(context).withOpacity(0.5),
            ),
            boxShadow: _isStopping
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.statusAlarm(context).withOpacity(0.3),
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
                _isStopping ? '停止中...' : '停止验连 (${_currentBatchCode ?? 'N/A'})',
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
