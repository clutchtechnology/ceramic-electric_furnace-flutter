import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../widgets/common/tech_line_widgets.dart';
import '../widgets/realtime_data/data_card.dart';
import '../widgets/realtime_data/valve_control.dart';
import '../widgets/realtime_data/valve_status_indicator.dart';
import '../widgets/realtime_data/electrode_current_chart.dart';
import '../widgets/realtime_data/info_card.dart';
import '../widgets/realtime_data/smelting_control_button.dart';
import '../widgets/history_curve/tech_chart.dart';
import '../models/app_state.dart';
import '../models/realtime_data.dart';
import '../models/valve_status.dart';
import '../api/index.dart';
import '../api/valve_api.dart';
import '../api/control_api.dart'; // 控制API
import '../api/batch_api.dart'; // 批次管理API
import '../tools/valve_calculator.dart';
import '../api/api.dart';
import '../services/alarm_service.dart';

/// 实时数据页面
/// 用于显示智能生产线数字孪生系统的实时数据
class RealtimeDataPage extends StatefulWidget {
  const RealtimeDataPage({super.key});

  @override
  State<RealtimeDataPage> createState() => RealtimeDataPageState();
}

/// 公开的 State 类，允许通过 GlobalKey 访问
class RealtimeDataPageState extends State<RealtimeDataPage> {
  late AppState _appState;
  final ApiClient _apiClient = ApiClient();
  final ValveApi _valveApi = ValveApi();
  final AlarmService _alarmService = AlarmService();

  /// 是否正在刷新数据
  bool isRefreshing = false;

  /// 实时数据
  RealtimeBatchData _realtimeData = RealtimeBatchData.empty();

  /// 蝶阀最新状态
  LatestValveStatus? _latestValveStatus;

  /// 蝶阀开合度（1-4号蝶阀）
  Map<int, double> _valveOpenPercentages = {
    1: 0.0,
    2: 0.0,
    3: 0.0,
    4: 0.0,
  };

  /// ============================================================
  /// 双速轮询架构 (稳定性优先)
  /// - 弧流弧压: 0.2s 高频轮询 (arc_current, arc_voltage, setpoints)
  /// - 传感器: 0.5s 低频轮询 (depths, valves, cooling, hopper)
  /// ============================================================

  /// 弧流弧压轮询定时器 (0.2s)
  Timer? _arcPollingTimer;
  static const Duration _arcPollingInterval = Duration(milliseconds: 200);

  /// 传感器轮询定时器 (0.5s)
  Timer? _sensorPollingTimer;
  static const Duration _sensorPollingInterval = Duration(milliseconds: 500);

  /// 弧流弧压实时数据
  ArcRealtimeData _arcData = ArcRealtimeData.empty();

  /// 传感器实时数据
  SensorRealtimeData? _sensorData;

  /// 是否已暂停轮询（用于 Tab 切换）
  bool _isPollingPaused = false;

  /// 防止并发请求的标志
  bool _isArcFetching = false;
  bool _isSensorFetching = false;

  @override
  void initState() {
    super.initState();
    _appState = AppState.instance;
    _appState.addListener(_onStateChanged);

    // 初始化为空数据，等待后端返回真实数据
    _realtimeData = RealtimeBatchData.empty();

    // 加载蝶阀配置（从后端）
    _loadValveConfig();

    // 启动双速数据轮询
    _startPolling();

    // 立即获取一次数据
    _fetchArcData();
    _fetchSensorData();

    // 检查断电恢复（延迟执行，等待界面渲染完成）
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _checkPowerRecovery();
      }
    });
  }

  /// 从后端加载蝶阀配置
  Future<void> _loadValveConfig() async {
    try {
      final configMap = await _valveApi.getValveConfig();
      // 转换为 ValveCalculator 需要的格式
      Map<int, Map<String, double>> configs = {};
      for (int i = 1; i <= 4; i++) {
        final valveConfig = configMap['valve_$i'];
        if (valveConfig != null) {
          configs[i] = {
            'full_open_time': valveConfig.fullOpenTime,
            'full_close_time': valveConfig.fullCloseTime,
          };
        }
      }
      ValveCalculator.updateConfigs(configs);
      debugPrint('[RealtimeDataPage] 蝶阀配置加载成功: $configs');
    } catch (e) {
      debugPrint('[RealtimeDataPage] 加载蝶阀配置失败，使用默认值: $e');
    }
  }

  @override
  void dispose() {
    _stopPolling();
    _alarmService.dispose();
    _appState.removeListener(_onStateChanged);
    super.dispose();
  }

  /// ============================================================
  /// 双速轮询控制
  /// ============================================================

  /// 启动双速轮询
  void _startPolling() {
    if (_isPollingPaused) return;

    // 启动弧流弧压轮询 (0.2s)
    if (_arcPollingTimer == null) {
      _arcPollingTimer = Timer.periodic(_arcPollingInterval, (_) {
        if (mounted && !_isPollingPaused) {
          _fetchArcData();
        }
      });
      debugPrint(
          '[RealtimeDataPage] 弧流弧压轮询已启动 (间隔: ${_arcPollingInterval.inMilliseconds}ms)');
    }

    // 启动传感器轮询 (0.5s)
    if (_sensorPollingTimer == null) {
      _sensorPollingTimer = Timer.periodic(_sensorPollingInterval, (_) {
        if (mounted && !_isPollingPaused) {
          _fetchSensorData();
        }
      });
      debugPrint(
          '[RealtimeDataPage] 传感器轮询已启动 (间隔: ${_sensorPollingInterval.inMilliseconds}ms)');
    }
  }

  /// 停止所有轮询
  void _stopPolling() {
    _arcPollingTimer?.cancel();
    _arcPollingTimer = null;
    _sensorPollingTimer?.cancel();
    _sensorPollingTimer = null;
    debugPrint('[RealtimeDataPage] 双速轮询已停止');
  }

  /// 暂停轮询（Tab 切换时调用）
  void pausePolling() {
    _isPollingPaused = true;
    _stopPolling();
    debugPrint('[RealtimeDataPage] 双速轮询已暂停');
  }

  /// 恢复轮询（Tab 切换回来时调用）
  void resumePolling() {
    _isPollingPaused = false;
    _startPolling();
    _fetchArcData(); // 立即获取一次
    _fetchSensorData();
    debugPrint('[RealtimeDataPage] 双速轮询已恢复');
  }

  /// ============================================================
  /// 弧流弧压数据获取 (0.2s 高频)
  /// ============================================================
  Future<void> _fetchArcData() async {
    // 防止并发请求
    if (_isArcFetching) return;
    _isArcFetching = true;

    try {
      final data = await _apiClient.getRealtimeArc();
      if (data != null && mounted) {
        setState(() {
          _arcData = ArcRealtimeData.fromJson(data);

          // 同步更新 _realtimeData 中的电流电压数据
          _syncArcDataToRealtimeData();
        });
      }
    } catch (e) {
      // 高频轮询，仅在调试时打印错误，不中断运行
      // debugPrint('[RealtimeDataPage] 弧流弧压获取失败: $e');
    } finally {
      _isArcFetching = false;
    }
  }

  /// 将弧流弧压数据同步到 _realtimeData（用于兼容现有 UI）
  void _syncArcDataToRealtimeData() {
    // 更新 electrodes 的电流电压
    if (_realtimeData.electrodes.length >= 3) {
      final phases = ['U', 'V', 'W'];
      for (int i = 0; i < 3; i++) {
        final oldElectrode = _realtimeData.electrodes[i];
        _realtimeData.electrodes[i] = ElectrodeRealtimeData(
          id: oldElectrode.id,
          name: oldElectrode.name,
          depthMm: oldElectrode.depthMm,
          currentA: _arcData.arcCurrent[phases[i]] ?? oldElectrode.currentA,
          voltageV: _arcData.arcVoltage[phases[i]] ?? oldElectrode.voltageV,
        );
      }
    }

    // 更新 electricity 的电流数组
    _realtimeData = RealtimeBatchData(
      electrodes: _realtimeData.electrodes,
      electricity: ElectricityRealtimeData(
        powerKW: _realtimeData.electricity.powerKW,
        energyKWh: _realtimeData.electricity.energyKWh,
        currentsA: [
          _arcData.arcCurrent['U'] ?? 0.0,
          _arcData.arcCurrent['V'] ?? 0.0,
          _arcData.arcCurrent['W'] ?? 0.0,
        ],
      ),
      cooling: _realtimeData.cooling,
      hopper: _realtimeData.hopper,
      batch: _realtimeData.batch,
    );
  }

  /// ============================================================
  /// 传感器数据获取 (0.5s 低频)
  /// ============================================================
  Future<void> _fetchSensorData() async {
    // 防止并发请求
    if (_isSensorFetching) return;
    _isSensorFetching = true;

    try {
      final data = await _apiClient.getRealtimeSensor();
      if (data != null && mounted) {
        setState(() {
          _sensorData = SensorRealtimeData.fromJson(data);

          // 同步更新 _realtimeData 中的传感器数据
          _syncSensorDataToRealtimeData();

          // 检查报警状态并播放声音
          _checkAlarmStatus();
        });
      }
    } catch (e) {
      // 低频轮询，打印错误日志
      debugPrint('[RealtimeDataPage] 传感器数据获取失败: $e');
    } finally {
      _isSensorFetching = false;
    }
  }

  /// 将传感器数据同步到 _realtimeData（用于兼容现有 UI）
  void _syncSensorDataToRealtimeData() {
    if (_sensorData == null) return;

    // 更新 electrodes 的深度
    if (_realtimeData.electrodes.length >= 3) {
      for (int i = 0; i < 3; i++) {
        final oldElectrode = _realtimeData.electrodes[i];
        final depthKey = (i + 1).toString();
        _realtimeData.electrodes[i] = ElectrodeRealtimeData(
          id: oldElectrode.id,
          name: oldElectrode.name,
          depthMm:
              _sensorData!.electrodeDepths[depthKey] ?? oldElectrode.depthMm,
          currentA: oldElectrode.currentA,
          voltageV: oldElectrode.voltageV,
        );
      }
    }

    // 更新冷却水和料仓数据
    _realtimeData = RealtimeBatchData(
      electrodes: _realtimeData.electrodes,
      electricity: _realtimeData.electricity,
      cooling: _sensorData!.cooling,
      hopper: _sensorData!.hopper,
      batch: _sensorData!.batch ?? _realtimeData.batch,
    );

    // 更新蝶阀开度
    _valveOpenPercentages = Map.from(_sensorData!.valveOpenness);
  }

  /// 获取蝶阀最新状态并增量计算开合度
  ///
  /// 逻辑：
  /// - 每5秒获取一次最新状态
  /// - 检查批次变化（新批次开度归零）
  /// - "01"（开）→ 开合度 +增量（根据配置计算）
  /// - "10"（关）→ 开合度 -增量（根据配置计算）
  /// - "00"（停）→ 开合度不变
  /// - 请求失败 → 记录失败次数，下次成功时补偿
  Future<void> _fetchValveLatestStatus() async {
    try {
      final latestStatus = await _valveApi.getLatestValveStatus();
      if (mounted) {
        setState(() {
          // 保存最新状态对象
          _latestValveStatus = latestStatus;

          // 检查批次变化（新批次开度归零）
          final currentBatch = _realtimeData.batch?.batchCode;
          if (ValveCalculator.checkBatchAndReset(currentBatch)) {
            debugPrint('[ValveStatus] 新批次检测到，开度已重置: $currentBatch');
          }

          // 构建状态映射
          Map<int, String> statuses = {};
          for (int i = 1; i <= 4; i++) {
            statuses[i] = latestStatus.getValveStatus(i)?.status ?? "00";
          }

          // 批量增量更新开合度（包含失败补偿逻辑）
          _valveOpenPercentages =
              ValveCalculator.batchUpdateOpenPercentages(statuses);

          // 打印调试信息
          debugPrint('[ValveStatus] ${ValveCalculator.getDebugInfo()}');
        });
      }
    } catch (e) {
      debugPrint('[RealtimeDataPage] 获取蝶阀状态失败: $e');
      // 记录失败，下次成功时会补偿
      ValveCalculator.recordFailure();
    }
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// 刷新数据方法，供外部通过 GlobalKey 调用
  Future<void> refreshData() async {
    if (isRefreshing) return;

    setState(() => isRefreshing = true);

    try {
      // 同时获取弧流弧压和传感器数据
      await Future.wait([
        _fetchArcData(),
        _fetchSensorData(),
      ]);
      await _appState.refreshAllData();

      if (mounted) {
        _showOperationResult(
          success: true,
          message: '数据刷新成功',
        );
      }
    } catch (e) {
      if (mounted) {
        _showOperationResult(
          success: false,
          message: '数据刷新失败: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => isRefreshing = false);
      }
    }
  }

  void _onValveChanged(ValveItem valve) {
    // 模拟操作延迟和可能的失败
    // 实际项目中这里应该是调用API
    Future.delayed(const Duration(milliseconds: 500), () async {
      // 90%成功率，10%失败率（用于演示）
      final isSuccess = DateTime.now().millisecond % 10 != 0;

      if (isSuccess) {
        // 保存到全局状态
        await _appState.updateValveState(
          valve.id,
          valve.status,
          openingDegree: valve.openingDegree,
        );

        // 显示成功提示
        String statusMsg = valve.status == ValveStatus.open
            ? '开启至${valve.openingDegree.toStringAsFixed(0)}%'
            : valve.status == ValveStatus.closed
                ? '关闭'
                : '停止';
        _showOperationResult(
          success: true,
          message: '${valve.name}$statusMsg成功',
        );
      } else {
        // 显示失败提示
        _showOperationResult(
          success: false,
          message: '${valve.name}操作失败：设备响应超时',
        );
      }
    });
  }

  /// 显示操作结果提示
  void _showOperationResult({required bool success, required String message}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? TechColors.statusNormal : TechColors.statusAlarm,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: success
            ? TechColors.statusNormal.withOpacity(0.9)
            : TechColors.statusAlarm.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: success ? 2 : 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: success ? TechColors.statusNormal : TechColors.statusAlarm,
            width: 1,
          ),
        ),
      ),
    );
  }

  /// 显示投料统计对话框
  Future<void> _showFeedingStatisticsDialog() async {
    showDialog(
      context: context,
      builder: (context) => FeedingStatisticsDialog(
        batchCode: _realtimeData.batch.batchCode ?? '当前批次',
      ),
    );
  }

  /// 检查报警状态
  void _checkAlarmStatus() {
    if (!_appState.isSmelting) {
      // 未冶炼时不检查报警
      _alarmService.stopAlarm();
      return;
    }

    bool hasAlarm = false;

    // 深度下限和上限 (与 _ElectrodeWidget 保持一致)
    const double depthMinThreshold = 150.0; // 下限 150mm
    const double depthMaxThreshold = 1960.0; // 上限 1960mm

    // 检查电极深度报警
    // - 显示深度 <= 0 (即实时深度 <= 下限)
    // - 实时深度 > 上限
    for (var electrode in _realtimeData.electrodes) {
      final displayDepth = electrode.depthMm - depthMinThreshold;
      if (displayDepth <= 0 || electrode.depthMm > depthMaxThreshold) {
        hasAlarm = true;
        break;
      }
    }

    // ============================================================
    // 检查电极电流报警（使用后端返回的设定值和死区）
    // 报警条件: 弧流 < 设定值*(1-死区) 或 弧流 > 设定值*(1+死区)
    // 注意: 弧压不需要报警
    // 保护条件: 电流为0时不触发报警（设备未运行或数据未就绪）
    // ============================================================
    final deadzonePercent = _arcData.manualDeadzonePercent / 100.0; // 转换为小数
    final phases = ['U', 'V', 'W'];

    for (var phase in phases) {
      final setpoint = _arcData.setpoints[phase] ?? 0.0;
      final currentValue = _arcData.arcCurrent[phase] ?? 0.0;

      // [CRITICAL] 电流为0时跳过报警（设备未运行或数据未就绪）
      if (currentValue == 0.0) {
        continue;
      }

      // 只有当设定值 > 0 时才检查报警
      if (setpoint > 0) {
        final minThreshold = setpoint * (1.0 - deadzonePercent);
        final maxThreshold = setpoint * (1.0 + deadzonePercent);

        if (currentValue < minThreshold || currentValue > maxThreshold) {
          hasAlarm = true;
          break;
        }
      }
    }

    // 检查冷却水流速报警（低于2.0）
    if (_realtimeData.cooling.furnaceShell.flowM3h < 2.0) {
      hasAlarm = true;
    }

    // 检查冷却水压报警（低于150 kPa）
    if (_realtimeData.cooling.furnaceShell.pressureKPa < 150.0) {
      hasAlarm = true;
    }

    // 检查炉盖冷却水流速报警（低于2.0）
    if (_realtimeData.cooling.furnaceCover.flowM3h < 2.0) {
      hasAlarm = true;
    }

    // 检查炉盖冷却水压报警（低于150 kPa）
    if (_realtimeData.cooling.furnaceCover.pressureKPa < 150.0) {
      hasAlarm = true;
    }

    // 根据报警状态控制声音
    if (hasAlarm && !_alarmService.isPlaying) {
      _alarmService.startAlarm();
    } else if (!hasAlarm && _alarmService.isPlaying) {
      _alarmService.stopAlarm();
    }
  }

  /// 开始冶炼
  ///
  /// [BACKEND_BYPASS_MODE] 当前跳过后端调用，直接设置前端状态
  /// 恢复后端调用：搜索 "BACKEND_BYPASS_MODE" 并取消注释后端代码，删除直接状态设置代码
  Future<void> _startSmelting() async {
    // 显示批次配置对话框
    final batchConfig = await showDialog<BatchConfig>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BatchConfigDialog(
        furnaceNumber: _appState.furnaceNumber,
      ),
    );

    // 用户取消
    if (batchConfig == null) return;

    // 生成批次号: FFYYMMDD 格式 (例如: 03260115 = 3号炉 + 2026年1月15日)
    // FF: 炉号 (01-99)
    // YY: 年份后两位 (26 = 2026)
    // MM: 月份 (01-12)
    // DD: 炉次/日期 (01-99)
    final furnace = batchConfig.furnaceNumber.padLeft(2, '0');
    final year = (batchConfig.year % 100).toString().padLeft(2, '0'); // 只取后两位
    final month = batchConfig.month.toString().padLeft(2, '0');
    final batch = batchConfig.batchNumber.toString().padLeft(2, '0');
    final code = '$furnace$year$month$batch';

    setState(() => isRefreshing = true); // 显示加载状态

    try {
      // 调用后端 API 开始冶炼
      final response = await BatchApi.startSmelting(code);

      if (mounted) {
        if (response.success) {
          setState(() {
            _appState.isSmelting = true;
            _appState.smeltingCode = response.batchCode ?? code;
            isRefreshing = false;
          });
          _appState.notifyListeners();

          _showOperationResult(
            success: true,
            message: '开始冶炼成功，批次号: ${response.batchCode ?? code}',
          );

          // 尝试立即刷新一次数据
          Future.delayed(const Duration(milliseconds: 1000), () {
            _fetchArcData();
            _fetchSensorData();
          });
        } else {
          setState(() => isRefreshing = false);
          _showOperationResult(
            success: false,
            message: response.message,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isRefreshing = false);
        _showOperationResult(
          success: false,
          message: '启动失败: $e',
        );
      }
    }
  }

  /// 停止冶炼
  Future<void> _stopSmelting() async {
    setState(() => isRefreshing = true);

    try {
      // 调用后端 API 停止冶炼
      final response = await BatchApi.stopSmelting();

      if (mounted) {
        setState(() {
          _appState.isSmelting = false;
          _appState.smeltingCode = '';
          isRefreshing = false;
        });
        _appState.notifyListeners();

        _showOperationResult(
          success: response.success,
          message: response.success ? '冶炼已停止，轮次结束' : response.message,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isRefreshing = false);
        // 即使API失败，也在本地停止状态，以免UI卡死
        setState(() => _appState.isSmelting = false);
        _showOperationResult(
          success: false,
          message: '停止失败: $e',
        );
      }
    }
  }

  /// 暂停冶炼
  Future<void> _pauseSmelting() async {
    setState(() => isRefreshing = true);

    try {
      final response = await BatchApi.pauseSmelting();

      if (mounted) {
        setState(() => isRefreshing = false);

        if (response.success) {
          // 暂停时保留批次号，但标记为非运行状态
          _showOperationResult(
            success: true,
            message: '冶炼已暂停，批次号已保留',
          );
        } else {
          _showOperationResult(
            success: false,
            message: response.message,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isRefreshing = false);
        _showOperationResult(
          success: false,
          message: '暂停失败: $e',
        );
      }
    }
  }

  /// 恢复冶炼
  Future<void> _resumeSmelting() async {
    setState(() => isRefreshing = true);

    try {
      final response = await BatchApi.resumeSmelting();

      if (mounted) {
        setState(() => isRefreshing = false);

        if (response.success) {
          _showOperationResult(
            success: true,
            message: '冶炼已恢复',
          );
        } else {
          _showOperationResult(
            success: false,
            message: response.message,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isRefreshing = false);
        _showOperationResult(
          success: false,
          message: '恢复失败: $e',
        );
      }
    }
  }

  /// 检查断电恢复 (应用启动时调用)
  Future<void> _checkPowerRecovery() async {
    try {
      final status = await BatchApi.getStatus();

      if (status.needsRecovery && mounted) {
        // 显示恢复对话框
        final shouldRecover = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _PowerRecoveryDialog(
            batchCode: status.batchCode ?? '',
            elapsedTime: status.formattedElapsedTime,
          ),
        );

        if (shouldRecover == true) {
          // 恢复冶炼
          await _resumeSmelting();
          setState(() {
            _appState.isSmelting = true;
            _appState.smeltingCode = status.batchCode ?? '';
          });
          _appState.notifyListeners();
        } else {
          // 放弃批次
          await _stopSmelting();
        }
      } else if (status.isRunning && mounted) {
        // 后端正在运行但前端不知道（可能是前端重启）
        setState(() {
          _appState.isSmelting = true;
          _appState.smeltingCode = status.batchCode ?? '';
        });
        _appState.notifyListeners();
      }
    } catch (e) {
      debugPrint('[RealtimeDataPage] 检查断电恢复失败: $e');
    }
  }

  /// 构建风机状态指示器
  Widget _buildFanStatusIndicator() {
    // 除尘器未接入
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TechColors.textSecondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: TechColors.textSecondary,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 14,
            color: TechColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            '设备未接入',
            style: TextStyle(
              color: TechColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建蝶阀状态指示面板
  /// 一列4行布局，每行占据1/4高度
  Widget _buildValveStatusPanel() {
    return Column(
      children: List.generate(4, (index) {
        int valveId = index + 1;
        String currentStatus = _latestValveStatus?.getStatus(valveId) ?? "00";
        double openPercentage = _valveOpenPercentages[valveId] ?? 0.0;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: index < 3 ? 8 : 0, // 除最后一行外都有底部间距
            ),
            child: ValveStatusIndicator(
              valveId: valveId,
              currentStatus: currentStatus,
              openPercentage: openPercentage,
            ),
          ),
        );
      }),
    );
  }

  /// 构建PM10浓度卡片
  Widget _buildPM10Card() {
    // 除尘器未接入，显示"-"
    return InfoCard(
      accentColor: TechColors.textSecondary,
      items: [
        InfoCardItem(
          icon: Icons.air,
          label: 'PM10浓度',
          value: '-',
          unit: 'mg/m³',
          iconColor: TechColors.textSecondary,
          valueColor: TechColors.textSecondary,
          showWarning: false,
          layout: InfoCardLayout.vertical,
        ),
      ],
    );
  }

  /// 构建风机功率卡片
  Widget _buildFanPowerCard() {
    // 除尘器未接入，显示"-"
    return InfoCard(
      accentColor: AppTheme.textSecondary(context),
      items: [
        InfoCardItem(
          icon: Icons.flash_on,
          label: '瞬时功率',
          value: '-',
          unit: 'kW',
          iconColor: AppTheme.textSecondary(context),
          valueColor: AppTheme.textSecondary(context),
          layout: InfoCardLayout.horizontal,
        ),
        InfoCardItem(
          icon: Icons.electric_meter,
          label: '累计能耗',
          value: '-',
          unit: 'kWh',
          iconColor: AppTheme.textSecondary(context),
          valueColor: AppTheme.textSecondary(context),
          layout: InfoCardLayout.horizontal,
        ),
      ],
    );
  }

  /// 构建电炉功率卡片
  Widget _buildFurnacePowerCard() {
    final power = _realtimeData.electricity.powerKW;
    final energy = _realtimeData.electricity.energyKWh;

    return InfoCard(
      accentColor: AppTheme.glowOrange(context),
      items: [
        InfoCardItem(
          icon: Icons.flash_on,
          label: '瞬时功率',
          value: power.toStringAsFixed(1),
          unit: 'kW',
          iconColor: AppTheme.glowOrange(context),
          valueColor: AppTheme.glowOrange(context),
          layout: InfoCardLayout.horizontal,
        ),
        InfoCardItem(
          icon: Icons.electric_meter,
          label: '累计能耗',
          value: energy.toStringAsFixed(1),
          unit: 'kWh',
          iconColor: AppTheme.glowBlue(context),
          valueColor: AppTheme.glowBlue(context),
          layout: InfoCardLayout.horizontal,
        ),
      ],
    );
  }

  /// 构建温度卡片
  Widget _buildTemperatureCard() {
    // 除尘器未接入，显示"-"
    return InfoCard(
      accentColor: TechColors.textSecondary,
      items: [
        InfoCardItem(
          icon: Icons.thermostat,
          label: '入口温度',
          value: '-',
          unit: '℃',
          iconColor: TechColors.textSecondary,
          valueColor: TechColors.textSecondary,
          showWarning: false,
          layout: InfoCardLayout.vertical,
        ),
      ],
    );
  }

  /// 显示频谱对话框
  void _showSpectrumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgMedium(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppTheme.glowCyan(context).withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.graphic_eq, color: AppTheme.glowCyan(context), size: 20),
            const SizedBox(width: 8),
            Text(
              '振动频谱分析',
              style: TextStyle(color: AppTheme.textPrimary(context)),
            ),
          ],
        ),
        content: Container(
          width: 600,
          height: 400,
          decoration: BoxDecoration(
            color: AppTheme.bgDeep(context),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.borderDark(context)),
          ),
          child: Center(
            child: Text(
              '频谱内容将在这里显示',
              style: TextStyle(
                  color: AppTheme.textSecondary(context), fontSize: 16),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('关闭', style: TextStyle(color: TechColors.glowCyan)),
          ),
        ],
      ),
    );
  }

  /// 构建振动频谱数据行
  Widget _buildVibrationSpectrumRow() {
    final vibrationFault = _appState.vibrationFault;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Icon(Icons.graphic_eq, size: 18, color: TechColors.statusWarning),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '除尘器风机振动频谱',
              style: TextStyle(
                color: TechColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
          // 故障提示图标
          if (vibrationFault)
            Tooltip(
              message: '故障检测',
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.warning,
                  size: 18,
                  color: TechColors.glowRed,
                ),
              ),
            ),
          // 数值显示
          Text(
            '50.0',
            style: TextStyle(
              color: TechColors.glowCyan,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
              shadows: [
                Shadow(
                  color: TechColors.glowCyan.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Hz',
            style: TextStyle(
              color: TechColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          // 频谱查看按钮
          _buildSpectrumButton(),
        ],
      ),
    );
  }

  /// 构建频谱查看按钮
  Widget _buildSpectrumButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _showSpectrumDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: TechColors.glowCyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: TechColors.glowCyan.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bar_chart,
                size: 14,
                color: TechColors.glowCyan,
              ),
              const SizedBox(width: 4),
              const Text(
                '查看频谱',
                style: TextStyle(
                  color: TechColors.glowCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate furnace image size (increased)
    final furnaceWidth = screenWidth * 0.40;

    // Calculate valve panel width (smaller)
    final valveWidth = screenWidth * 0.27;

    // Calculate right panel width (increased)
    final rightPanelWidth = screenWidth * 0.32;

    return Container(
      color: TechColors.bgDeep,
      child: Stack(
        children: [
          // 冶炼控制按钮（电炉图片上方居中）
          Positioned(
            left: (screenWidth - furnaceWidth) / 2 - 50,
            top: 50,
            right: (screenWidth - furnaceWidth) / 2 + 50,
            child: Center(
              child: SmeltingControlButton(
                isSmelting: _appState.isSmelting,
                smeltingCode: _appState.smeltingCode,
                onStart: _startSmelting,
                onStop: _stopSmelting,
                isSystemReady: true, // [BACKEND_BYPASS] 跳过后端检查，始终允许点击
              ),
            ),
          ),
          // 电炉图片居中偏左显示
          Positioned(
            left: (screenWidth - furnaceWidth) / 2 - 30,
            top: 150,
            width: furnaceWidth,
            child: AspectRatio(
              aspectRatio: 1.0, // 根据实际图片比例调整
              child: Stack(
                children: [
                  Image.asset(
                    'assets/images/furnace.png',
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  // 电极1（左上）
                  Positioned(
                    top: furnaceWidth * 0.15,
                    left: furnaceWidth / 2 - 210,
                    child: _ElectrodeWidget(
                        label: '1#电极',
                        isSmelting: _appState.isSmelting,
                        depthValue: _realtimeData.electrodes[0].depthMm,
                        current: _realtimeData.electrodes[0].currentA
                            .toStringAsFixed(0),
                        currentValue: _realtimeData.electrodes[0].currentA,
                        voltage: _realtimeData.electrodes[0].voltageV
                            .toStringAsFixed(0)),
                  ),
                  // 电极2（右上）
                  Positioned(
                    top: furnaceWidth * 0.15,
                    left: furnaceWidth / 2 + 90,
                    child: _ElectrodeWidget(
                        label: '2#电极',
                        isSmelting: _appState.isSmelting,
                        depthValue: _realtimeData.electrodes[1].depthMm,
                        current: _realtimeData.electrodes[1].currentA
                            .toStringAsFixed(0),
                        currentValue: _realtimeData.electrodes[1].currentA,
                        voltage: _realtimeData.electrodes[1].voltageV
                            .toStringAsFixed(0)),
                  ),
                  // 电极3（下方中间）
                  Positioned(
                    top: furnaceWidth * 0.40,
                    left: furnaceWidth / 2 - 60,
                    child: _ElectrodeWidget(
                        isSmelting: _appState.isSmelting,
                        label: '3#电极',
                        depthValue: _realtimeData.electrodes[2].depthMm,
                        current: _realtimeData.electrodes[2].currentA
                            .toStringAsFixed(0),
                        currentValue: _realtimeData.electrodes[2].currentA,
                        voltage: _realtimeData.electrodes[2].voltageV
                            .toStringAsFixed(0)),
                  ),
                  // 删除了电炉功率卡片（已将电压数据整合到电极显示中）
                ],
              ),
            ),
          ),
          // 左上角：蝶阀状态指示面板
          Positioned(
            left: 16,
            top: 16,
            height: (screenHeight - 48) * 0.45,
            width: valveWidth,
            child: TechPanel(
              title: '蝶阀状态',
              height: double.infinity,
              accentColor: TechColors.glowGreen,
              padding: const EdgeInsets.all(12),
              child: _buildValveStatusPanel(),
            ),
          ),
          // 最右侧：除尘器面板（占据除冷却水外的剩余高度）
          Positioned(
            right: 16,
            top: 16,
            bottom: screenHeight * 0.33,
            width: rightPanelWidth,
            child: TechPanel(
              title: '除尘器',
              height: double.infinity,
              accentColor: TechColors.glowCyan,
              padding: const EdgeInsets.all(8),
              headerActions: [
                _buildFanStatusIndicator(),
              ],
              child: Stack(
                children: [
                  // 背景图片
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      'assets/images/dust_collector.png',
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  // 左上角：PM10浓度卡片
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _buildPM10Card(),
                  ),
                  // 左侧居中温度卡片
                  Positioned(
                    left: 150,
                    top: 0,
                    bottom: 70,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildTemperatureCard(),
                    ),
                  ),
                  // 左下角：风机功率卡片
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: _buildFanPowerCard(),
                  ),
                ],
              ),
            ),
          ),
          // 前置过滤器压差面板（位于除尘器和炉皮冷却水之间）
          Positioned(
            right: 16,
            bottom: screenHeight * 0.22,
            width: rightPanelWidth,
            child: TechPanel(
              title: '前置过滤器压差',
              accentColor: TechColors.glowBlue,
              padding: const EdgeInsets.all(8),
              child: DataCard(
                items: [
                  DataItem(
                      icon: Icons.compress,
                      label: '进出口压差',
                      value: _realtimeData.cooling.filterPressureDiffKPa
                          .toStringAsFixed(1),
                      unit: 'kPa',
                      iconColor: TechColors.glowBlue),
                ],
              ),
            ),
          ),
          // 左侧中部：梯形图（电极电流图表）
          Positioned(
            left: 16,
            top: (screenHeight - 48) * 0.45 + 16 + 10,
            height: (screenHeight - 48) * 0.34,
            width: valveWidth,
            child: TechPanel(
              height: double.infinity,
              accentColor: TechColors.glowOrange,
              padding: const EdgeInsets.all(8),
              child: ElectrodeCurrentChart(
                deadzonePercent: _arcData.manualDeadzonePercent, // 从API获取死区百分比
                electrodes: [
                  ElectrodeData(
                    name: '电极1',
                    setValue: _arcData.setpoints['U'] ?? 0.0, // 从API获取U相设定值
                    actualValue: _arcData.arcCurrent['U'] ?? 0.0, // 从API获取U相弧流
                  ),
                  ElectrodeData(
                    name: '电极2',
                    setValue: _arcData.setpoints['V'] ?? 0.0, // 从API获取V相设定值
                    actualValue: _arcData.arcCurrent['V'] ?? 0.0, // 从API获取V相弧流
                  ),
                  ElectrodeData(
                    name: '电极3',
                    setValue: _arcData.setpoints['W'] ?? 0.0, // 从API获取W相设定值
                    actualValue: _arcData.arcCurrent['W'] ?? 0.0, // 从API获取W相弧流
                  ),
                ],
              ),
            ),
          ),
          // 右侧下部：炉皮冷却水面板（自适应内容高度）
          Positioned(
            right: 16,
            bottom: 16,
            width: rightPanelWidth,
            child: TechPanel(
              title: '炉皮冷却水',
              accentColor: TechColors.glowOrange,
              padding: const EdgeInsets.all(8),
              child: DataCard(
                items: [
                  DataItem(
                      icon: Icons.water,
                      label: '冷却水流速',
                      value: _realtimeData.cooling.furnaceShell.flowM3h
                          .toStringAsFixed(2),
                      unit: 'm³/h',
                      iconColor: TechColors.glowOrange,
                      threshold: _appState.furnaceShellFlowMin,
                      isAboveThreshold: false),
                  DataItem(
                      icon: Icons.opacity,
                      label: '冷却水水压',
                      value: _realtimeData.cooling.furnaceShell.pressureKPa
                          .toStringAsFixed(1),
                      unit: 'kPa',
                      iconColor: TechColors.glowBlue,
                      threshold: _appState.furnaceShellPressureMin,
                      isAboveThreshold: false),
                  DataItem(
                      icon: Icons.water_drop,
                      label: '冷却水用量',
                      value: _realtimeData.cooling.furnaceShell.totalM3
                          .toStringAsFixed(2),
                      unit: 'm³',
                      iconColor: TechColors.glowCyan),
                ],
              ),
            ),
          ),
          // 中间列底部：炉盖冷却水面板
          Positioned(
            left: valveWidth + 28,
            right: rightPanelWidth + 28,
            bottom: 16,
            child: TechPanel(
              title: '炉盖冷却水',
              accentColor: TechColors.glowOrange,
              padding: const EdgeInsets.all(8),
              child: DataCard(
                items: [
                  DataItem(
                      icon: Icons.water,
                      label: '冷却水流速',
                      value: _realtimeData.cooling.furnaceCover.flowM3h
                          .toStringAsFixed(2),
                      unit: 'm³/h',
                      iconColor: TechColors.glowOrange,
                      threshold: _appState.furnaceCoverFlowMin,
                      isAboveThreshold: false),
                  DataItem(
                      icon: Icons.opacity,
                      label: '冷却水水压',
                      value: _realtimeData.cooling.furnaceCover.pressureKPa
                          .toStringAsFixed(1),
                      unit: 'kPa',
                      iconColor: TechColors.glowBlue,
                      threshold: _appState.furnaceCoverPressureMin,
                      isAboveThreshold: false),
                  DataItem(
                      icon: Icons.water_drop,
                      label: '冷却水用量',
                      value: _realtimeData.cooling.furnaceCover.totalM3
                          .toStringAsFixed(2),
                      unit: 'm³',
                      iconColor: TechColors.glowCyan),
                ],
              ),
            ),
          ),
          // 左侧底部：重量面板
          Positioned(
            left: 16,
            bottom: 16,
            width: valveWidth,
            child: GestureDetector(
              onTap: _showFeedingStatisticsDialog,
              child: TechPanel(
                title: '重量',
                accentColor: TechColors.glowOrange,
                padding: const EdgeInsets.all(8),
                child: DataCard(
                  items: [
                    DataItem(
                        icon: Icons.scale,
                        label: '料仓重量',
                        value: _realtimeData.hopper.weightKg.toStringAsFixed(0),
                        unit: 'kg',
                        iconColor: TechColors.glowOrange),
                    // 投料重量：显示当前批次的累计投料量
                    DataItem(
                        icon: Icons.arrow_downward,
                        label: '投料重量',
                        value: _realtimeData.hopper.feedingTotalKg
                            .toStringAsFixed(0),
                        unit: 'kg',
                        iconColor: TechColors.glowGreen),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 电炉功率与能耗专用卡片，保证行高与报警数据一致
class FurnacePowerCard extends StatelessWidget {
  final String power;
  final String energy;
  const FurnacePowerCard({
    super.key,
    required this.power,
    required this.energy,
  });

  @override
  Widget build(BuildContext context) {
    // 统一行高样式
    Widget buildRow(
        IconData icon, String label, String value, String unit, Color color) {
      return Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: AppTheme.textSecondary(context), fontSize: 16)),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
              shadows: [
                Shadow(color: color.withOpacity(0.5), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(unit,
              style: TextStyle(
                  color: AppTheme.textSecondary(context), fontSize: 16)),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgMedium(context).withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderDark(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildRow(Icons.flash_on, '瞬时功率', power, 'kW',
              AppTheme.glowOrange(context)),
          Divider(height: 32, color: AppTheme.borderDark(context)),
          buildRow(Icons.electric_meter, '累计能耗', energy, 'kWh',
              AppTheme.glowBlue(context)),
        ],
      ),
    );
  }
}

/// 电极数据小部件（显示深度、电流和电压）
/// 深度显示: 实时深度 - 下限 (显示相对深度)
/// 深度报警: 显示深度 <= 0 (实时 <= 下限) 或 实时深度 > 上限
class _ElectrodeWidget extends StatelessWidget {
  final String label;
  final String current;
  final String voltage;
  final double depthValue; // 实时深度数值 (mm)
  final double currentValue; // 电流数值，用于报警判断
  final double depthMinThreshold; // 深度下限 (mm) - 显示用: 显示值 = 实时值 - 下限
  final double depthMaxThreshold; // 深度上限 (mm) - 超过此值报警
  final bool isSmelting; // 是否正在冶炼

  // 电流设定值 2989A，阈值为 ±15%
  static const double currentSetpoint = 2989.0;
  static const double currentMinThreshold = currentSetpoint * 0.85; // 2540.65
  static const double currentMaxThreshold = currentSetpoint * 1.15; // 3437.35

  const _ElectrodeWidget({
    required this.label,
    required this.current,
    required this.voltage,
    this.depthValue = 0,
    this.currentValue = 0,
    this.depthMinThreshold = 150, // 默认下限 150mm
    this.depthMaxThreshold = 1960, // 默认上限 1960mm
    this.isSmelting = false,
  });

  /// 计算显示深度 = 实时深度 - 下限
  double get displayDepth => depthValue - depthMinThreshold;

  /// 显示深度字符串 (保留整数)
  String get depthDisplay => displayDepth.toStringAsFixed(0);

  /// 判断深度是否报警
  /// - 显示深度 <= 0 (即实时深度 <= 下限)
  /// - 实时深度 > 上限
  bool get isDepthAlarm =>
      isSmelting && (displayDepth <= 0 || depthValue > depthMaxThreshold);

  /// 判断电流是否报警 (超出 ±15% 范围)
  bool get isCurrentAlarm =>
      isSmelting &&
      (currentValue < currentMinThreshold ||
          currentValue > currentMaxThreshold);

  /// 获取报警类型描述
  String get alarmType {
    if (displayDepth <= 0) return '低位';
    if (depthValue > depthMaxThreshold) return '高位';
    if (currentValue < currentMinThreshold) return '电流过低';
    if (currentValue > currentMaxThreshold) return '电流过高';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    // 任意一种报警状态
    final isAlarm = isDepthAlarm || isCurrentAlarm;

    // 根据报警状态选择边框和阴影颜色
    final borderColor =
        isAlarm ? AppTheme.statusAlarm(context) : AppTheme.glowCyan(context);

    // 深度颜色
    final depthColor = isDepthAlarm
        ? AppTheme.statusAlarm(context)
        : AppTheme.glowCyan(context);

    // 电流颜色
    final currentColor = isCurrentAlarm
        ? AppTheme.statusAlarm(context)
        : AppTheme.glowOrange(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgMedium(context).withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: isAlarm ? 2.0 : 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(isAlarm ? 0.5 : 0.25),
            blurRadius: isAlarm ? 16 : 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：电极标签 + 报警标识
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, color: borderColor, size: 18),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: TechColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isAlarm) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: TechColors.statusAlarm.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: TechColors.statusAlarm, width: 1),
                  ),
                  child: Text(
                    '$alarmType报警',
                    style: const TextStyle(
                      color: TechColors.statusAlarm,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // 第二行：深度数据 (显示值 = 实时值 - 下限)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '深度 ',
                style: TextStyle(
                  color: TechColors.textSecondary,
                  fontSize: 18,
                ),
              ),
              Text(
                (displayDepth / 1000).toStringAsFixed(3),
                style: TextStyle(
                  color: depthColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto Mono',
                  shadows: [
                    Shadow(
                      color: depthColor.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                'm',
                style: TextStyle(
                  color: TechColors.textSecondary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 第三行：弧流数据
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '弧流 ',
                style: TextStyle(
                  color: TechColors.textSecondary,
                  fontSize: 18,
                ),
              ),
              Text(
                current,
                style: TextStyle(
                  color: currentColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto Mono',
                  shadows: [
                    Shadow(
                      color: currentColor.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                'A',
                style: TextStyle(
                  color: TechColors.textSecondary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 第四行：弧压数据
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '弧压 ',
                style: TextStyle(
                  color: TechColors.textSecondary,
                  fontSize: 18,
                ),
              ),
              Text(
                voltage,
                style: TextStyle(
                  color: TechColors.glowGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto Mono',
                  shadows: [
                    Shadow(
                      color: TechColors.glowGreen.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                'V',
                style: TextStyle(
                  color: TechColors.textSecondary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 投料统计对话框
class FeedingStatisticsDialog extends StatefulWidget {
  final String batchCode;

  const FeedingStatisticsDialog({
    super.key,
    required this.batchCode,
  });

  @override
  State<FeedingStatisticsDialog> createState() =>
      _FeedingStatisticsDialogState();
}

/// 批次配置数据类
class BatchConfig {
  final String furnaceNumber; // 炉号
  final int year; // 年份
  final int month; // 月份
  final int batchNumber; // 当月第XX炉

  BatchConfig({
    required this.furnaceNumber,
    required this.year,
    required this.month,
    required this.batchNumber,
  });
}

/// 批次配置对话框
class BatchConfigDialog extends StatefulWidget {
  final String furnaceNumber;

  const BatchConfigDialog({
    super.key,
    required this.furnaceNumber,
  });

  @override
  State<BatchConfigDialog> createState() => _BatchConfigDialogState();
}

class _BatchConfigDialogState extends State<BatchConfigDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedBatchNumber;
  bool _isLoading = false;
  bool _isLoadingSequence = true; // 正在加载序号
  late TextEditingController _batchNumberController;
  String? _batchNumberError;
  int _latestSequence = 0; // 数据库中最新序号

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _selectedBatchNumber = 1;
    _batchNumberController = TextEditingController(text: '1');

    // 自动获取最新序号
    _fetchLatestSequence();
  }

  /// 从后端获取最新批次序号
  Future<void> _fetchLatestSequence() async {
    setState(() => _isLoadingSequence = true);

    try {
      final response = await BatchApi.getLatestSequence(
        furnaceNumber: widget.furnaceNumber,
        year: _selectedYear,
        month: _selectedMonth,
      );

      if (mounted) {
        setState(() {
          _latestSequence = response.latestSequence;
          _selectedBatchNumber = response.nextSequence;
          _batchNumberController.text = response.nextSequence.toString();
          _isLoadingSequence = false;
        });

        debugPrint(
            '[BatchConfigDialog] 最新序号: $_latestSequence, 建议序号: ${response.nextSequence}');
      }
    } catch (e) {
      debugPrint('[BatchConfigDialog] 获取最新序号失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingSequence = false;
          // 失败时使用默认值 1
          _batchNumberController.text = '1';
        });
      }
    }
  }

  @override
  void dispose() {
    _batchNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: TechColors.bgDeep,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TechColors.glowCyan.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: TechColors.glowCyan.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TechColors.bgDark.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: TechColors.glowCyan.withOpacity(0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: TechColors.glowCyan,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '批次配置',
                    style: TextStyle(
                      color: TechColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // 内容区域
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 炉号（只读）
                  _buildReadOnlyField('炉号', '${widget.furnaceNumber}号炉'),
                  const SizedBox(height: 20),
                  // 年份选择
                  _buildYearSelector(),
                  const SizedBox(height: 20),
                  // 月份选择
                  _buildMonthSelector(),
                  const SizedBox(height: 20),
                  // 炉次选择
                  _buildBatchNumberSelector(),
                  const SizedBox(height: 32),
                  // 按钮组
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          '取消',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppTheme.glowCyan(context).withOpacity(0.2),
                          foregroundColor: AppTheme.glowCyan(context),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side:
                                BorderSide(color: AppTheme.borderGlow(context)),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.borderGlow(context),
                                ),
                              )
                            : Text(
                                '确认',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TechColors.textSecondary,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: TechColors.bgDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: TechColors.borderDark),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: TechColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;
    final years =
        List.generate(5, (index) => currentYear - 2 + index); // 前2年到后2年

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '年份',
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.bgMedium(context).withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderDark(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedYear,
              dropdownColor: AppTheme.bgDark(context),
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 20,
              ),
              icon: Icon(Icons.arrow_drop_down,
                  color: AppTheme.borderGlow(context)),
              onChanged: (value) {
                if (value != null && value != _selectedYear) {
                  setState(() => _selectedYear = value);
                  // 年份变化时重新获取序号
                  _fetchLatestSequence();
                }
              },
              items: years.map((year) {
                return DropdownMenuItem<int>(
                  value: year,
                  child: Text('$year年'),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '月份',
          style: TextStyle(
            color: TechColors.textSecondary,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: TechColors.bgMedium.withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: TechColors.borderDark),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedMonth,
              dropdownColor: TechColors.bgDark,
              style: const TextStyle(
                color: TechColors.textPrimary,
                fontSize: 20,
              ),
              icon:
                  const Icon(Icons.arrow_drop_down, color: TechColors.glowCyan),
              onChanged: (value) {
                if (value != null && value != _selectedMonth) {
                  setState(() => _selectedMonth = value);
                  // 月份变化时重新获取序号
                  _fetchLatestSequence();
                }
              },
              items: List.generate(12, (index) {
                final month = index + 1;
                return DropdownMenuItem<int>(
                  value: month,
                  child: Text('${month.toString().padLeft(2, '0')}月'),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchNumberSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '当月炉次',
              style: TextStyle(
                color: TechColors.textSecondary,
                fontSize: 18,
              ),
            ),
            if (_isLoadingSequence) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: TechColors.glowCyan,
                ),
              ),
            ] else if (_latestSequence > 0) ...[
              const SizedBox(width: 8),
              Text(
                '(上次: $_latestSequence)',
                style: TextStyle(
                  color: TechColors.glowGreen.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _batchNumberController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: TechColors.textPrimary,
            fontSize: 20,
          ),
          decoration: InputDecoration(
            hintText: '请输入炉次 (01-99)',
            hintStyle: TextStyle(
              color: TechColors.textSecondary.withOpacity(0.5),
              fontSize: 16,
            ),
            errorText: _batchNumberError,
            filled: true,
            fillColor: TechColors.bgMedium.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: TechColors.borderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: TechColors.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: TechColors.glowCyan, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: TechColors.statusAlarm),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            setState(() {
              _batchNumberError = _validateBatchNumber(value);
            });
          },
        ),
      ],
    );
  }

  String? _validateBatchNumber(String value) {
    if (value.isEmpty) {
      return '请输入炉次';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return '请输入有效数字';
    }
    if (number < 1 || number > 99) {
      return '炉次范围为 1-99';
    }
    return null;
  }

  void _onConfirm() {
    final batchNumberText = _batchNumberController.text.trim();
    final error = _validateBatchNumber(batchNumberText);

    if (error != null) {
      setState(() {
        _batchNumberError = error;
      });
      return;
    }

    final batchNumber = int.parse(batchNumberText);
    final config = BatchConfig(
      furnaceNumber: widget.furnaceNumber,
      year: _selectedYear,
      month: _selectedMonth,
      batchNumber: batchNumber,
    );
    Navigator.of(context).pop(config);
  }
}

class _FeedingStatisticsDialogState extends State<FeedingStatisticsDialog> {
  bool _isLoading = true;
  List<ChartDataPoint> _feedingData = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadFeedingData();
  }

  Future<void> _loadFeedingData() async {
    // [BACKEND_BYPASS_MODE] 跳过后端，直接显示模拟数据
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    await Future.delayed(const Duration(milliseconds: 400));
    // 构造模拟数据
    final now = DateTime.now();
    final List<ChartDataPoint> points = List.generate(12, (i) {
      final time = now.subtract(Duration(minutes: (11 - i) * 5));
      return ChartDataPoint(
        label:
            "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
        value: 1000 + i * 120 + (i % 3 == 0 ? 80 : 0),
      );
    });
    if (mounted) {
      setState(() {
        _feedingData = points;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 900,
        height: 600,
        decoration: BoxDecoration(
          color: TechColors.bgDeep,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TechColors.glowOrange.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: TechColors.glowOrange.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TechColors.bgDark.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: TechColors.glowOrange.withOpacity(0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.assessment,
                    color: TechColors.glowOrange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '投料统计',
                        style: TextStyle(
                          color: TechColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '批次: ${widget.batchCode}',
                        style: const TextStyle(
                          color: TechColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    color: TechColors.textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // 内容区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: TechColors.glowOrange,
            ),
            SizedBox(height: 16),
            Text(
              '正在加载数据...',
              style: TextStyle(
                color: TechColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: TechColors.statusAlarm,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(
                color: TechColors.statusAlarm,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFeedingData,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TechColors.glowOrange.withOpacity(0.2),
                foregroundColor: TechColors.glowOrange,
              ),
            ),
          ],
        ),
      );
    }

    if (_feedingData.isEmpty) {
      return const Center(
        child: Text(
          '暂无投料数据',
          style: TextStyle(
            color: TechColors.textSecondary,
            fontSize: 18,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 图表标题
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: TechColors.glowOrange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '投料重量变化趋势',
              style: TextStyle(
                color: TechColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '数据点数: ${_feedingData.length}',
              style: const TextStyle(
                color: TechColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 图表
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: TechColors.bgDark.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: TechColors.borderDark),
            ),
            padding: const EdgeInsets.all(16),
            child: TechLineChart(
              data: _feedingData,
              accentColor: TechColors.glowOrange,
              yAxisLabel: 'kg',
              showGrid: true,
              showPoints: true,
              minY: 0,
            ),
          ),
        ),
      ],
    );
  }
}

/// 断电恢复对话框
/// 当检测到后端有未完成的冶炼批次时显示
class _PowerRecoveryDialog extends StatelessWidget {
  final String batchCode;
  final String elapsedTime;

  const _PowerRecoveryDialog({
    required this.batchCode,
    required this.elapsedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: TechColors.bgDeep,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TechColors.statusWarning.withOpacity(0.7),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: TechColors.statusWarning.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TechColors.statusWarning.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: TechColors.statusWarning.withOpacity(0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.power_settings_new,
                    color: TechColors.statusWarning,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '检测到未完成的冶炼批次',
                      style: TextStyle(
                        color: TechColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 内容区域
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 批次信息
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TechColors.bgMedium.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: TechColors.borderDark),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('批次编号', batchCode),
                        const SizedBox(height: 12),
                        _buildInfoRow('已运行时长', elapsedTime),
                        const SizedBox(height: 12),
                        _buildInfoRow('当前状态', '已暂停（断电保护）'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 提示文字
                  Text(
                    '系统检测到上次冶炼因断电而中断，请选择：',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 按钮组
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.statusAlarm(context),
                            side: BorderSide(
                                color: AppTheme.statusAlarm(context)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '放弃批次',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppTheme.statusNormal(context).withOpacity(0.2),
                            foregroundColor: AppTheme.statusNormal(context),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                  color: AppTheme.statusNormal(context)),
                            ),
                          ),
                          child: const Text(
                            '恢复冶炼',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TechColors.textSecondary,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: TechColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
