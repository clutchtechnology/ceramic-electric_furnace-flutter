import 'package:flutter/material.dart';
import 'dart:async';
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

  /// 数据轮询定时器
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 5);

  /// 是否已暂停轮询（用于 Tab 切换）
  bool _isPollingPaused = false;

  @override
  void initState() {
    super.initState();
    _appState = AppState.instance;
    _appState.addListener(_onStateChanged);

    // 启动数据轮询
    _startPolling();

    // 立即获取一次数据
    _fetchRealtimeData();
  }

  @override
  void dispose() {
    _stopPolling();
    _alarmService.dispose();
    _appState.removeListener(_onStateChanged);
    super.dispose();
  }

  /// 启动数据轮询
  void _startPolling() {
    if (_pollingTimer != null || _isPollingPaused) return;
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      if (mounted && !_isPollingPaused) {
        _fetchRealtimeData();
      }
    });
    debugPrint(
        '[RealtimeDataPage] 数据轮询已启动 (间隔: ${_pollingInterval.inSeconds}s)');
  }

  /// 停止数据轮询
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('[RealtimeDataPage] 数据轮询已停止');
  }

  /// 暂停轮询（Tab 切换时调用）
  void pausePolling() {
    _isPollingPaused = true;
    _stopPolling();
    debugPrint('[RealtimeDataPage] 数据轮询已暂停');
  }

  /// 恢复轮询（Tab 切换回来时调用）
  void resumePolling() {
    _isPollingPaused = false;
    _startPolling();
    _fetchRealtimeData(); // 立即获取一次
    debugPrint('[RealtimeDataPage] 数据轮询已恢复');
  }

  /// 从后端获取实时数据
  /// 如果获取失败，保持原有数据不刷新
  Future<void> _fetchRealtimeData() async {
    try {
      // 1. 获取实时批量数据
      final data = await _apiClient.getRealtimeBatch();
      if (data != null && mounted) {
        setState(() {
          _realtimeData = RealtimeBatchData.fromJson(data);
        
        // 检查报警状态并播放声音
        _checkAlarmStatus();
        
        });
        debugPrint('[RealtimeDataPage] 实时数据刷新成功');
      } else {
        debugPrint('[RealtimeDataPage] 获取数据为空，保持原有数据');
      }

      // 2. 获取蝶阀最新状态并增量计算开合度
      await _fetchValveLatestStatus();
    } catch (e) {
      // 获取失败时不更新数据，保持原有状态
      debugPrint('[RealtimeDataPage] 获取实时数据失败，保持原有数据: $e');
    }
  }

  /// 获取蝶阀最新状态并增量计算开合度
  ///
  /// 逻辑：
  /// - 每5秒获取一次最新状态
  /// - "01"（开）→ 开合度 +16.67%
  /// - "10"（关）→ 开合度 -16.67%
  /// - "00"（停）→ 开合度不变
  /// - 请求失败 → 记录失败次数，下次成功时补偿
  Future<void> _fetchValveLatestStatus() async {
    try {
      final latestStatus = await _valveApi.getLatestValveStatus();
      if (mounted) {
        setState(() {
          // 保存最新状态对象
          _latestValveStatus = latestStatus;

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
      await _fetchRealtimeData();
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

    // 检查电极深度报警（低于150mm或高于1960mm）
    for (var electrode in _realtimeData.electrodes) {
      if (electrode.depthMm < 150 || electrode.depthMm > 1960) {
        hasAlarm = true;
        break;
      }
    }

    // 检查电极电流报警（±15%）
    const double currentSetpoint = 2989.0;
    const double currentMinThreshold = currentSetpoint * 0.85;
    const double currentMaxThreshold = currentSetpoint * 1.15;
    
    for (var electrode in _realtimeData.electrodes) {
      if (electrode.currentA < currentMinThreshold || 
          electrode.currentA > currentMaxThreshold) {
        hasAlarm = true;
        break;
      }
    }

    // 检查冷却水流速报警（低于2.0）
    if (_realtimeData.cooling.furnaceShell.flowM3h < 2.0) {
      hasAlarm = true;
    }

    // 检查冷却水压报警（低于0.15）
    if (_realtimeData.cooling.furnaceShell.pressureMPa < 0.15) {
      hasAlarm = true;
    }

    // 检查炉盖冷却水流速报警（低于2.0）
    if (_realtimeData.cooling.furnaceCover.flowM3h < 2.0) {
      hasAlarm = true;
    }

    // 检查炉盖冷却水压报警（低于0.15）
    if (_realtimeData.cooling.furnaceCover.pressureMPa < 0.15) {
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
  Future<void> _startSmelting() async {
    // 生成默认批次号 (SM+日期+时间)
    final now = DateTime.now();
    final code =
        'SM${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    setState(() => isRefreshing = true); // 显示加载状态

    try {
      // 调用后端 API 启动轮询
      final response = await ControlApi.startPolling(code);

      if (mounted) {
        setState(() {
          _appState.isSmelting = true;
          // 使用后端确认的批次号，或者我们生成的
          _appState.smeltingCode =
              response.batchCode.isNotEmpty ? response.batchCode : code;
          isRefreshing = false;
        });
        _appState.notifyListeners();

        _showOperationResult(
          success: true,
          message: '开始冶炼成功，设备连接中...',
        );

        // 尝试立即刷新一次数据，以检查连接状态
        Future.delayed(
            const Duration(milliseconds: 1000), () => _fetchRealtimeData());
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
      // 调用后端 API 停止轮询
      await ControlApi.stopPolling();

      if (mounted) {
        setState(() {
          _appState.isSmelting = false;
          isRefreshing = false;
        });
        _appState.notifyListeners();

        _showOperationResult(
          success: true,
          message: '冶炼已停止，轮次结束',
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
      accentColor: TechColors.textSecondary,
      items: [
        InfoCardItem(
          icon: Icons.flash_on,
          label: '瞬时功率',
          value: '-',
          unit: 'kW',
          iconColor: TechColors.textSecondary,
          valueColor: TechColors.textSecondary,
          layout: InfoCardLayout.horizontal,
        ),
        InfoCardItem(
          icon: Icons.electric_meter,
          label: '累计能耗',
          value: '-',
          unit: 'kWh',
          iconColor: TechColors.textSecondary,
          valueColor: TechColors.textSecondary,
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
      accentColor: TechColors.glowOrange,
      items: [
        InfoCardItem(
          icon: Icons.flash_on,
          label: '瞬时功率',
          value: power.toStringAsFixed(1),
          unit: 'kW',
          iconColor: TechColors.glowOrange,
          valueColor: TechColors.glowOrange,
          layout: InfoCardLayout.horizontal,
        ),
        InfoCardItem(
          icon: Icons.electric_meter,
          label: '累计能耗',
          value: energy.toStringAsFixed(1),
          unit: 'kWh',
          iconColor: TechColors.glowBlue,
          valueColor: TechColors.glowBlue,
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
        backgroundColor: TechColors.bgMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: TechColors.glowCyan.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.graphic_eq, color: TechColors.glowCyan, size: 20),
            const SizedBox(width: 8),
            const Text(
              '振动频谱分析',
              style: TextStyle(color: TechColors.textPrimary),
            ),
          ],
        ),
        content: Container(
          width: 600,
          height: 400,
          decoration: BoxDecoration(
            color: TechColors.bgDeep,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: TechColors.borderDark),
          ),
          child: const Center(
            child: Text(
              '频谱内容将在这里显示',
              style: TextStyle(color: TechColors.textSecondary, fontSize: 16),
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
                isSystemReady: _appState.isSystemReady,
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
                    left: furnaceWidth / 2 - 180,
                    child: _ElectrodeWidget(
                        label: '1#电极',
                        isSmelting: _appState.isSmelting,
                        depth: _realtimeData.electrodes[0].depthMm
                            .toStringAsFixed(0),
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
                    left: furnaceWidth / 2 + 60,
                    child: _ElectrodeWidget(
                        label: '2#电极',
                        isSmelting: _appState.isSmelting,
                        depth: _realtimeData.electrodes[1].depthMm
                            .toStringAsFixed(0),
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
                        depth: _realtimeData.electrodes[2].depthMm
                            .toStringAsFixed(0),
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
            bottom: screenHeight * 0.28,
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
            bottom: screenHeight * 0.17 + 2,
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
                      value:
                          (_realtimeData.cooling.filterPressureDiffMPa * 1000)
                              .toStringAsFixed(1), // MPa -> kPa (更直观)
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
                electrodes: [
                  ElectrodeData(
                    name: '电极1',
                    setValue: 5978, // 弧流目标值 5978 A
                    actualValue: _realtimeData.electrodes[0].currentA,
                  ),
                  ElectrodeData(
                    name: '电极2',
                    setValue: 5978, // 弧流目标值 5978 A
                    actualValue: _realtimeData.electrodes[1].currentA,
                  ),
                  ElectrodeData(
                    name: '电极3',
                    setValue: 5978, // 弧流目标值 5978 A
                    actualValue: _realtimeData.electrodes[2].currentA,
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
                      threshold: 2.0,
                      isAboveThreshold: false),
                  DataItem(
                      icon: Icons.opacity,
                      label: '冷却水水压',
                      value: _realtimeData.cooling.furnaceShell.pressureMPa
                          .toStringAsFixed(2),
                      unit: 'MPa',
                      iconColor: TechColors.glowBlue,
                      threshold: 0.15,
                      isAboveThreshold: false),
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
                      threshold: 2.0,
                      isAboveThreshold: false),
                  DataItem(
                      icon: Icons.opacity,
                      label: '冷却水水压',
                      value: _realtimeData.cooling.furnaceCover.pressureMPa
                          .toStringAsFixed(2),
                      unit: 'MPa',
                      iconColor: TechColors.glowBlue,
                      threshold: 0.15,
                      isAboveThreshold: false),
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
                style: const TextStyle(
                    color: TechColors.textSecondary, fontSize: 16)),
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
              style: const TextStyle(
                  color: TechColors.textSecondary, fontSize: 16)),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TechColors.borderDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildRow(Icons.flash_on, '瞬时功率', power, 'kW', TechColors.glowOrange),
          const Divider(height: 32, color: TechColors.borderDark),
          buildRow(
              Icons.electric_meter, '累计能耗', energy, 'kWh', TechColors.glowBlue),
        ],
      ),
    );
  }
}

/// 电极数据小部件（显示深度、电流和电压）
/// 深度报警: 低于低点(150mm) 或 高于高点(1960mm) 都报警
class _ElectrodeWidget extends StatelessWidget {
  final String label;
  final String depth;
  final String current;
  final String voltage;
  final double depthValue; // 深度数值，用于报警判断
  final double currentValue; // 电流数值，用于报警判断
  final double depthMinThreshold; // 深度低位阈值 (mm)
  final double depthMaxThreshold; // 深度高位阈值 (mm)
  final bool isSmelting; // 是否正在冶炼

  // 电流设定值 2989A，阈值为 ±15%
  static const double currentSetpoint = 2989.0;
  static const double currentMinThreshold = currentSetpoint * 0.85; // 2540.65
  static const double currentMaxThreshold = currentSetpoint * 1.15; // 3437.35

  const _ElectrodeWidget({
    required this.label,
    required this.depth,
    required this.current,
    required this.voltage,
    this.depthValue = 0,
    this.currentValue = 0,
    this.depthMinThreshold = 150, // 默认低位阈值 0.15m = 150mm
    this.depthMaxThreshold = 1960, // 默认高位阈值 1.96m = 1960mm
    this.isSmelting = false,
  });

  /// 判断深度是否报警（低于低点或高于高点）
  bool get isDepthAlarm =>
      isSmelting &&
      (depthValue < depthMinThreshold || depthValue > depthMaxThreshold);

  /// 判断电流是否报警 (超出 ±15% 范围)
  bool get isCurrentAlarm =>
      isSmelting &&
      (currentValue < currentMinThreshold ||
          currentValue > currentMaxThreshold);

  /// 获取报警类型描述
  String get alarmType {
    if (depthValue < depthMinThreshold) return '低位';
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
    final borderColor = isAlarm ? TechColors.statusAlarm : TechColors.glowCyan;

    // 深度颜色
    final depthColor =
        isDepthAlarm ? TechColors.statusAlarm : TechColors.glowCyan;

    // 电流颜色
    final currentColor =
        isCurrentAlarm ? TechColors.statusAlarm : TechColors.glowOrange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.9),
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
          // 第二行：深度数据
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
                (depthValue / 1000).toStringAsFixed(3),
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
  State<FeedingStatisticsDialog> createState() => _FeedingStatisticsDialogState();
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
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final apiClient = ApiClient();
      // 调用料仓历史数据接口
      final response = await apiClient.get(
        Api.historyHopper,
        params: {
          'batch_code': widget.batchCode,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> dataList = response['data'] as List<dynamic>;
        
        final List<ChartDataPoint> points = [];
        for (var item in dataList) {
          final timestamp = item['timestamp'] as String?;
          final feedingTotal = (item['feeding_total_kg'] ?? 0).toDouble();
          
          if (timestamp != null && timestamp.isNotEmpty) {
            // 提取时间部分 (HH:mm:ss)
            final timeStr = timestamp.length >= 19 
                ? timestamp.substring(11, 19) 
                : timestamp;
            
            points.add(ChartDataPoint(
              label: timeStr,
              value: feedingTotal,
            ));
          }
        }

        if (mounted) {
          setState(() {
            _feedingData = points;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('数据格式错误');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '加载数据失败: $e';
        });
      }
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
