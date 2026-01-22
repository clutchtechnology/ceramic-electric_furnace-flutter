import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/common/tech_line_widgets.dart';
import '../api/status_service.dart';
import '../models/status_model.dart';

/// DB41 数据状态页面
/// 显示传感器数据采集状态 (Error/Status)
class Db41StatusPage extends StatefulWidget {
  const Db41StatusPage({super.key});

  @override
  State<Db41StatusPage> createState() => Db41StatusPageState();
}

/// 公开 State 类以便通过 GlobalKey 访问 (用于页面切换时暂停/恢复轮询)
class Db41StatusPageState extends State<Db41StatusPage> {
  // ============================================================
  // 常量定义
  // ============================================================
  static const int _pollIntervalSeconds = 5;
  static const int _maxBackoffSeconds = 60;

  // ============================================================
  // 状态变量
  // ============================================================
  final StatusService _statusService = StatusService();
  Timer? _timer;
  Db41StatusResponse? _response;
  bool _isRefreshing = false;
  String? _errorMessage;
  int _consecutiveFailures = 0;

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
    debugPrint('[Db41StatusPage] 轮询已暂停');
  }

  /// 恢复轮询
  void resumePolling() {
    if (_timer != null) return;
    _consecutiveFailures = 0;
    _fetchData();
    _startPollingWithInterval(_pollIntervalSeconds);
    debugPrint('[Db41StatusPage] 轮询已恢复');
  }

  void _startPollingWithInterval(int intervalSeconds) {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) async {
        if (!mounted) return;
        await _fetchData();
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
      _startPollingWithInterval(newInterval);
    }
  }

  // ============================================================
  // 数据获取
  // ============================================================
  Future<void> _fetchData() async {
    if (_isRefreshing || !mounted) return;

    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final response = await _statusService.getDb41Devices();

      if (!mounted) return;
      setState(() {
        if (response.success) {
          _response = response;
          _adjustPollingInterval(true);
        } else {
          _errorMessage = response.message ?? '获取状态失败';
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
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  // ============================================================
  // UI 构建
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TechColors.bgDeep,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _errorMessage != null
                ? _buildErrorWidget()
                : _response == null
                    ? _buildLoadingWidget()
                    : _buildDeviceGrid(),
          ),
        ],
      ),
    );
  }

  /// 顶部状态栏
  Widget _buildHeader() {
    final summary = _response?.summary ?? StatusSummary.empty();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: TechColors.bgDark,
        border: Border(
          bottom: BorderSide(color: TechColors.borderDark.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          // 标题
          const Icon(Icons.sensors, color: TechColors.glowOrange, size: 20),
          const SizedBox(width: 8),
          const Text(
            'DB41 传感器数据状态',
            style: TextStyle(
              color: TechColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // 统计
          _buildStatChip('正常', summary.healthy, TechColors.glowGreen),
          const SizedBox(width: 8),
          _buildStatChip('异常', summary.error, TechColors.glowRed),
          const SizedBox(width: 8),
          _buildStatChip('总数', summary.total, TechColors.glowOrange),
          const SizedBox(width: 12),
          // 刷新指示器
          if (_isRefreshing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(TechColors.glowOrange),
              ),
            ),
        ],
      ),
    );
  }

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
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 11),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(TechColors.glowOrange),
          ),
          SizedBox(height: 16),
          Text(
            '正在加载状态数据...',
            style: TextStyle(color: TechColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: TechColors.glowRed, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '未知错误',
            style: const TextStyle(color: TechColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(
              backgroundColor: TechColors.glowOrange.withOpacity(0.2),
            ),
            child: const Text('重试',
                style: TextStyle(color: TechColors.glowOrange)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceGrid() {
    final devices = _response?.devices ?? [];

    if (devices.isEmpty) {
      return const Center(
        child: Text(
          '暂无设备数据',
          style: TextStyle(color: TechColors.textSecondary, fontSize: 11),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 3.8,
        ),
        itemCount: devices.length,
        itemBuilder: (context, index) => _buildDeviceCard(devices[index], index),
      ),
    );
  }

  Widget _buildDeviceCard(Db41DeviceStatus device, int index) {
    final hasError = !device.isNormal;
    final accentColor = hasError ? TechColors.glowRed : TechColors.glowGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: hasError
              ? TechColors.glowRed.withOpacity(0.3)
              : TechColors.borderDark.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // 序号
          SizedBox(
            width: 20,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: TechColors.textSecondary,
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
              style: const TextStyle(
                color: TechColors.textPrimary,
                fontSize: 11,
                fontFamily: 'Roboto Mono',
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          // E (Error)
          _buildValueBadge('E', device.error ? '1' : '0', device.error),
          const SizedBox(width: 4),
          // S (Status - 十六进制)
          _buildValueBadge(
            'S',
            device.status.toRadixString(16).toUpperCase().padLeft(4, '0'),
            device.status != 0,
          ),
        ],
      ),
    );
  }

  /// 通用值徽章 (与磨料车间样式一致)
  Widget _buildValueBadge(String label, String value, bool isError) {
    final color = isError ? TechColors.glowRed : TechColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: const TextStyle(color: TechColors.textSecondary, fontSize: 9),
        ),
        const SizedBox(width: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: isError
                ? TechColors.glowRed.withOpacity(0.2)
                : TechColors.bgMedium.withOpacity(0.3),
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
