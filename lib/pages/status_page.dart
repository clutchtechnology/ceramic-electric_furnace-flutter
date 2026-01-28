import 'package:flutter/material.dart';
import 'dart:async';

import '../api/status_service.dart';
import '../models/status_model.dart';
import '../theme/app_theme.dart';

/// 设备状态页面 (合并 DB30 + DB41)
/// 参考磨料车间的紧凑设计，使用垂直分区布局
class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => StatusPageState();
}

/// 公开 State 类以便通过 GlobalKey 访问 (用于页面切换时暂停/恢复轮询)
class StatusPageState extends State<StatusPage> {
  // ============================================================
  // 常量定义
  // ============================================================
  static const int _columnCount = 3;
  static const int _pollIntervalSeconds = 5;
  static const int _maxBackoffSeconds = 60;
  static const int _maxRefreshDurationSeconds = 15;

  // ============================================================
  // 状态变量
  // ============================================================
  final StatusService _statusService = StatusService();
  Timer? _timer;

  // DB30 数据
  Db30StatusResponse? _db30Response;
  // DB41 数据
  Db41StatusResponse? _db41Response;

  bool _isRefreshing = false;
  String? _errorMessage;
  int _consecutiveFailures = 0;
  DateTime? _refreshStartTime;

  // ============================================================
  // 生命周期
  // ============================================================
  @override
  void initState() {
    super.initState();
    // 不在 initState 中启动轮询，由外部控制
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  // ============================================================
  // 轮询控制 (供外部通过 GlobalKey 调用)
  // ============================================================

  /// 暂停轮询
  void pausePolling() {
    if (_timer == null) return;
    _timer?.cancel();
    _timer = null;
    debugPrint('[StatusPage] 轮询已暂停');
  }

  /// 恢复轮询
  void resumePolling() {
    if (_timer != null) return;
    _consecutiveFailures = 0;
    _fetchData();
    _startPollingWithInterval(_pollIntervalSeconds);
    debugPrint('[StatusPage] 轮询已恢复');
  }

  void _startPollingWithInterval(int intervalSeconds) {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) async {
        if (!mounted) return;
        try {
          await _fetchData();
        } catch (e) {
          debugPrint('[StatusPage] 定时器回调异常: $e');
        }
      },
    );
  }

  void _adjustPollingInterval(bool wasSuccess) {
    if (!mounted || _timer == null) return;

    if (wasSuccess) {
      if (_consecutiveFailures > 0) {
        _consecutiveFailures = 0;
        _startPollingWithInterval(_pollIntervalSeconds);
      }
    } else {
      _consecutiveFailures = (_consecutiveFailures + 1).clamp(0, 4);
      final newInterval = (_pollIntervalSeconds * (1 << _consecutiveFailures))
          .clamp(_pollIntervalSeconds, _maxBackoffSeconds);
      if (_consecutiveFailures == 1) {
        debugPrint('[StatusPage] 网络异常，轮询间隔延长至 ${newInterval}s');
      }
      _startPollingWithInterval(newInterval);
    }
  }

  // ============================================================
  // 数据获取
  // ============================================================

  /// 获取所有状态数据
  Future<void> _fetchData() async {
    // 防止卡死检测
    if (_isRefreshing) {
      if (_refreshStartTime != null) {
        final duration =
            DateTime.now().difference(_refreshStartTime!).inSeconds;
        if (duration > _maxRefreshDurationSeconds) {
          debugPrint('[StatusPage] _isRefreshing 卡死超过 ${duration}s，强制重置！');
          _isRefreshing = false;
          _refreshStartTime = null;
        } else {
          return;
        }
      } else {
        _isRefreshing = false;
      }
    }
    if (!mounted) return;

    _refreshStartTime = DateTime.now();
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      // 并行获取 DB30 和 DB41 数据
      final results = await Future.wait([
        _statusService.getDb30Devices(),
        _statusService.getDb41Devices(),
      ]);

      if (!mounted) return;

      final db30Result = results[0] as Db30StatusResponse;
      final db41Result = results[1] as Db41StatusResponse;

      setState(() {
        if (db30Result.success && db41Result.success) {
          _db30Response = db30Result;
          _db41Response = db41Result;
          _adjustPollingInterval(true);
        } else {
          // 部分成功也保存数据
          if (db30Result.success) _db30Response = db30Result;
          if (db41Result.success) _db41Response = db41Result;

          // 记录错误
          final errors = <String>[];
          if (!db30Result.success) errors.add('DB30: ${db30Result.message}');
          if (!db41Result.success) errors.add('DB41: ${db41Result.message}');
          _errorMessage = errors.join('\n');
          _adjustPollingInterval(false);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '网络错误: $e';
      });
      _adjustPollingInterval(false);
    } finally {
      _refreshStartTime = null;
      if (mounted) {
        setState(() => _isRefreshing = false);
      } else {
        _isRefreshing = false;
      }
    }
  }

  // ============================================================
  // UI 构建
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep(context),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _errorMessage != null &&
                    _db30Response == null &&
                    _db41Response == null
                ? _buildErrorWidget()
                : _buildVerticalLayout(),
          ),
        ],
      ),
    );
  }

  /// 垂直布局: DB30 (上) + DB41 (下) 各占 50%
  Widget _buildVerticalLayout() {
    final db30Devices = _db30Response?.devices ?? [];
    final db41Devices = _db41Response?.devices ?? [];

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: _buildDbSection(
              'DB30',
              db30Devices,
              AppTheme.glowCyan(context),
              isDb30: true,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            flex: 1,
            child: _buildDbSection(
              'DB41 ',
              db41Devices,
              AppTheme.glowOrange(context),
              isDb30: false,
            ),
          ),
        ],
      ),
    );
  }

  /// 单个 DB 区块
  Widget _buildDbSection(
    String title,
    List<dynamic> statusList,
    Color accentColor, {
    required bool isDb30,
  }) {
    int normalCount = 0;
    if (isDb30) {
      normalCount = (statusList as List<Db30DeviceStatus>)
          .where((s) => s.isNormal)
          .length;
    } else {
      normalCount = (statusList as List<Db41DeviceStatus>)
          .where((s) => s.isNormal)
          .length;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgDark(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildSectionHeader(
              title, normalCount, statusList.length, accentColor),
          Expanded(
            child: statusList.isEmpty
                ? _buildEmptyHint()
                : _buildStatusGrid(statusList, isDb30),
          ),
        ],
      ),
    );
  }

  /// 区块标题栏
  Widget _buildSectionHeader(
    String title,
    int normalCount,
    int totalCount,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
        border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: accentColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Spacer(),
          Text(
            '正常: $normalCount/$totalCount',
            style: TextStyle(
              color: accentColor.withOpacity(0.8),
              fontSize: 11,
              fontFamily: 'Roboto Mono',
            ),
          ),
        ],
      ),
    );
  }

  /// 空数据提示
  Widget _buildEmptyHint() {
    return Center(
      child: Text(
        '暂无数据',
        style: TextStyle(
          color: AppTheme.textSecondary(context).withOpacity(0.5),
          fontSize: 11,
        ),
      ),
    );
  }

  /// 状态网格
  Widget _buildStatusGrid(List<dynamic> statusList, bool isDb30) {
    final itemsPerColumn = (statusList.length / _columnCount).ceil();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_columnCount, (colIndex) {
          final startIndex = colIndex * itemsPerColumn;
          final endIndex =
              (startIndex + itemsPerColumn).clamp(0, statusList.length);

          return Expanded(
            child: Column(
              children: [
                for (int i = startIndex; i < endIndex; i++)
                  isDb30
                      ? _buildDb30StatusCard(
                          statusList[i] as Db30DeviceStatus, i)
                      : _buildDb41StatusCard(
                          statusList[i] as Db41DeviceStatus, i),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 顶部状态栏
  Widget _buildHeader() {
    final db30Summary = _db30Response?.summary ?? StatusSummary.empty();
    final db41Summary = _db41Response?.summary ?? StatusSummary.empty();
    final totalNormal = db30Summary.healthy + db41Summary.healthy;
    final totalError = db30Summary.error + db41Summary.error;
    final total = db30Summary.total + db41Summary.total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgDark(context),
        border: Border(
          bottom:
              BorderSide(color: AppTheme.borderDark(context).withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Text(
            '设备状态监控',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Spacer(),
          _buildStatChip('总计', total, AppTheme.glowCyan(context)),
          const SizedBox(width: 10),
          _buildStatChip('正常', totalNormal, AppTheme.glowGreen(context)),
          const SizedBox(width: 10),
          _buildStatChip('异常', totalError, AppTheme.glowRed(context)),
          const SizedBox(width: 12),
          // 刷新按钮
          IconButton(
            onPressed: _isRefreshing ? null : _fetchData,
            icon: _isRefreshing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.glowCyan(context),
                    ),
                  )
                : Icon(Icons.refresh,
                    color: AppTheme.glowCyan(context), size: 20),
          ),
        ],
      ),
    );
  }

  /// 统计标签
  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Mono',
            ),
          ),
        ],
      ),
    );
  }

  /// 错误提示
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppTheme.glowRed(context), size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '未知错误',
            style:
                TextStyle(color: AppTheme.textSecondary(context), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.glowCyan(context).withOpacity(0.2),
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// DB30 单个状态卡片
  Widget _buildDb30StatusCard(Db30DeviceStatus device, int index) {
    final hasError = !device.isNormal;
    final accentColor =
        hasError ? AppTheme.glowRed(context) : AppTheme.glowGreen(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgMedium(context).withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: hasError
              ? AppTheme.glowRed(context).withOpacity(0.3)
              : AppTheme.borderDark(context).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // 序号
          SizedBox(
            width: 20,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 10,
                fontFamily: 'Roboto Mono',
              ),
            ),
          ),
          // 状态灯
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.5),
                  blurRadius: 3,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // 设备名
          Expanded(
            child: Text(
              device.deviceName,
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 11,
                fontFamily: 'Roboto Mono',
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          // D (Done)
          _buildValueBadge('D', device.done ? '1' : '0', device.done,
              AppTheme.glowGreen(context)),
          const SizedBox(width: 3),
          // B (Busy)
          _buildValueBadge('B', device.busy ? '1' : '0', device.busy,
              AppTheme.glowOrange(context)),
          const SizedBox(width: 3),
          // E (Error)
          _buildValueBadge('E', device.error ? '1' : '0', device.error,
              AppTheme.glowRed(context)),
          const SizedBox(width: 3),
          // S (Status)
          _buildValueBadge(
            'S',
            device.status.toRadixString(16).toUpperCase().padLeft(4, '0'),
            device.status != 0,
            AppTheme.glowCyan(context),
          ),
        ],
      ),
    );
  }

  /// DB41 单个状态卡片
  Widget _buildDb41StatusCard(Db41DeviceStatus device, int index) {
    final hasError = !device.isNormal;
    final accentColor =
        hasError ? AppTheme.glowRed(context) : AppTheme.glowGreen(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgMedium(context).withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: hasError
              ? AppTheme.glowRed(context).withOpacity(0.3)
              : AppTheme.borderDark(context).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // 序号
          SizedBox(
            width: 20,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 10,
                fontFamily: 'Roboto Mono',
              ),
            ),
          ),
          // 状态灯
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.5),
                  blurRadius: 3,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // 设备名
          Expanded(
            child: Text(
              device.deviceName,
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 11,
                fontFamily: 'Roboto Mono',
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          // E (Error)
          _buildValueBadge('E', device.error ? '1' : '0', device.error,
              AppTheme.glowRed(context)),
          const SizedBox(width: 3),
          // S (Status)
          _buildValueBadge(
            'S',
            device.status.toRadixString(16).toUpperCase().padLeft(4, '0'),
            device.status != 0,
            AppTheme.glowOrange(context),
          ),
        ],
      ),
    );
  }

  /// 通用值徽章
  Widget _buildValueBadge(
      String label, String value, bool isActive, Color activeColor) {
    final color = isActive ? activeColor : AppTheme.textSecondary(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 9),
        ),
        const SizedBox(width: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withOpacity(0.2)
                : AppTheme.bgMedium(context).withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Mono',
            ),
          ),
        ),
      ],
    );
  }
}
