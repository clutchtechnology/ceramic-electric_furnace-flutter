import 'dart:async';
import 'package:flutter/material.dart';
import '../../api/index.dart';
import '../../api/api.dart';
import '../common/tech_line_widgets.dart';
import '../../theme/app_theme.dart';

/// 健康状态小部件 - 显示后端、PLC、数据库连接状态
class HealthStatusWidget extends StatefulWidget {
  /// 状态变化回调 (后端正常, PLC正常)
  final void Function(bool isBackendHealthy, bool isPlcHealthy)?
      onStatusChanged;

  const HealthStatusWidget({super.key, this.onStatusChanged});

  @override
  State<HealthStatusWidget> createState() => HealthStatusWidgetState();
}

class HealthStatusWidgetState extends State<HealthStatusWidget> {
  // ===== 状态变量 =====
  bool _isSystemHealthy = false;
  bool _isPlcHealthy = false;
  bool _isDbHealthy = false;

  // 定时器
  Timer? _timer;

  // 上次状态 (避免重复日志)
  bool? _lastSystemHealthy;
  bool? _lastPlcHealthy;
  bool? _lastDbHealthy;

  // 网络异常退避
  int _consecutiveFailures = 0;
  static const int _normalIntervalSeconds = 30;
  static const int _maxIntervalSeconds = 120;

  // ===== 公开属性供外部访问 =====
  bool get isSystemHealthy => _isSystemHealthy;
  bool get isPlcHealthy => _isPlcHealthy;
  bool get isDbHealthy => _isDbHealthy;
  bool get isSystemReady => _isSystemHealthy && _isPlcHealthy;

  @override
  void initState() {
    super.initState();
    _checkHealth();
    _startPolling(_normalIntervalSeconds);
  }

  void _startPolling(int intervalSeconds) {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      if (mounted) _checkHealth();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 更新健康状态
  void _updateHealthStatus({
    required String serviceName,
    required bool newValue,
    required bool? lastValue,
    required void Function(bool) updateLast,
    required void Function(bool) updateCurrent,
    Object? errorDetail,
  }) {
    if (!mounted) return;

    // 状态变化时记录日志
    if (newValue && lastValue == false) {
      debugPrint('$serviceName恢复正常');
    } else if (!newValue && lastValue != false) {
      debugPrint(
          '$serviceName连接断开${errorDetail != null ? ": $errorDetail" : ""}');
    }

    updateLast(newValue);
    setState(() => updateCurrent(newValue));
  }

  Future<void> _checkHealth() async {
    final client = ApiClient();
    bool allHealthy = true;

    // 1. 检查系统服务
    if (!await _checkSystemHealth(client)) allHealthy = false;
    // 2. 检查 PLC
    if (!await _checkPlcHealth(client)) allHealthy = false;
    // 3. 检查数据库
    if (!await _checkDbHealth(client)) allHealthy = false;

    // 通知状态变化
    widget.onStatusChanged?.call(_isSystemHealthy, _isPlcHealthy);

    // 调整轮询间隔
    _adjustPollingInterval(allHealthy);
  }

  void _adjustPollingInterval(bool allHealthy) {
    if (!mounted) return;

    if (allHealthy) {
      if (_consecutiveFailures > 0) {
        _consecutiveFailures = 0;
        _startPolling(_normalIntervalSeconds);
      }
    } else {
      final previousFailures = _consecutiveFailures;
      _consecutiveFailures = (_consecutiveFailures + 1).clamp(0, 3);
      if (_consecutiveFailures != previousFailures) {
        final newInterval =
            (_normalIntervalSeconds * (1 << _consecutiveFailures))
                .clamp(_normalIntervalSeconds, _maxIntervalSeconds);
        _startPolling(newInterval);
      }
    }
  }

  Future<bool> _checkSystemHealth(ApiClient client) async {
    try {
      await client.get(Api.health);
      _updateHealthStatus(
        serviceName: '系统服务',
        newValue: true,
        lastValue: _lastSystemHealthy,
        updateLast: (v) => _lastSystemHealthy = v,
        updateCurrent: (v) => _isSystemHealthy = v,
      );
      return true;
    } catch (e) {
      _updateHealthStatus(
        serviceName: '系统服务',
        newValue: false,
        lastValue: _lastSystemHealthy,
        updateLast: (v) => _lastSystemHealthy = v,
        updateCurrent: (v) => _isSystemHealthy = v,
        errorDetail: e,
      );
      return false;
    }
  }

  Future<bool> _checkPlcHealth(ApiClient client) async {
    try {
      final response = await client.get(Api.healthPlc);
      final plcConnected = _parseConnected(response);
      _updateHealthStatus(
        serviceName: 'PLC',
        newValue: plcConnected,
        lastValue: _lastPlcHealthy,
        updateLast: (v) => _lastPlcHealthy = v,
        updateCurrent: (v) => _isPlcHealthy = v,
      );
      return plcConnected;
    } catch (e) {
      _updateHealthStatus(
        serviceName: 'PLC',
        newValue: false,
        lastValue: _lastPlcHealthy,
        updateLast: (v) => _lastPlcHealthy = v,
        updateCurrent: (v) => _isPlcHealthy = v,
        errorDetail: e,
      );
      return false;
    }
  }

  Future<bool> _checkDbHealth(ApiClient client) async {
    try {
      final response = await client.get(Api.healthDb);
      final dbConnected = _parseDbStatus(response);
      _updateHealthStatus(
        serviceName: '数据库',
        newValue: dbConnected,
        lastValue: _lastDbHealthy,
        updateLast: (v) => _lastDbHealthy = v,
        updateCurrent: (v) => _isDbHealthy = v,
      );
      return dbConnected;
    } catch (e) {
      _updateHealthStatus(
        serviceName: '数据库',
        newValue: false,
        lastValue: _lastDbHealthy,
        updateLast: (v) => _lastDbHealthy = v,
        updateCurrent: (v) => _isDbHealthy = v,
        errorDetail: e,
      );
      return false;
    }
  }

  /// 解析 {"data": {"connected": true}} 格式
  bool _parseConnected(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return data['connected'] == true;
      }
    }
    return false;
  }

  /// 解析数据库状态
  bool _parseDbStatus(dynamic response) {
    if (response is! Map<String, dynamic>) return false;
    final data = response['data'];
    if (data is! Map<String, dynamic>) return false;

    // 格式1: status == "healthy"
    if (data['status'] == 'healthy') return true;

    // 格式2: databases.influxdb.connected
    final databases = data['databases'];
    if (databases is Map<String, dynamic>) {
      final influxdb = databases['influxdb'];
      if (influxdb is Map<String, dynamic>) {
        return influxdb['connected'] == true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatusIndicator('服务', _isSystemHealthy),
        const SizedBox(width: 8),
        _buildStatusIndicator('PLC', _isPlcHealthy),
        const SizedBox(width: 8),
        _buildStatusIndicator('数据库', _isDbHealthy),
      ],
    );
  }

  Widget _buildStatusIndicator(String label, bool isHealthy) {
    final color =
        isHealthy ? AppTheme.glowGreen(context) : AppTheme.glowRed(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgMedium(context),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
        ],
      ),
    );
  }
}
