import 'package:flutter/material.dart';
import '../widgets/tech_line_widgets.dart';
import '../widgets/data_card.dart';
import '../widgets/valve_control.dart';
import '../widgets/electrode_current_chart.dart';
import '../models/app_state.dart';

/// 数据大屏页面
/// 用于显示智能生产线数字孪生系统的数据大屏内容
class DataScreenPage extends StatefulWidget {
  const DataScreenPage({super.key});

  @override
  State<DataScreenPage> createState() => _DataScreenPageState();
}

class _DataScreenPageState extends State<DataScreenPage> {
  late AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState.instance;
    _appState.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
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

  /// 构建风机状态指示器
  Widget _buildFanStatusIndicator() {
    final fanRunning = _appState.fanRunning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (fanRunning ? TechColors.statusNormal : TechColors.statusAlarm).withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: fanRunning ? TechColors.statusNormal : TechColors.statusAlarm,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            fanRunning ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: fanRunning ? TechColors.statusNormal : TechColors.statusAlarm,
          ),
          const SizedBox(width: 4),
          Text(
            fanRunning ? '风机运行中' : '风机已停止',
            style: TextStyle(
              color: fanRunning ? TechColors.statusNormal : TechColors.statusAlarm,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
            child: const Text('关闭', style: TextStyle(color: TechColors.glowCyan)),
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

    return Container(
      color: TechColors.bgDeep,
      child: Stack(
        children: [
          // 电极深度叠加在电炉图片上
          Positioned(
            left: 16 + (screenWidth - 48) / 3 + 8 + ((screenWidth - 48) * 0.42 + 8 + (screenWidth - 48) * 0.25 - screenWidth * 0.5) / 2,
            top: 8,
            width: screenWidth * 0.5,
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
                    top: screenWidth * 0.5 * 0.15,
                    left: (screenWidth * 0.5) / 2 - 180,
                    child: _ElectrodeWidget(label: '电极1', depth: '120', current: '28.5'),
                  ),
                  // 电极2（右上）
                  Positioned(
                    top: screenWidth * 0.5 * 0.15,
                    left: (screenWidth * 0.5) / 2 + 60,
                    child: _ElectrodeWidget(label: '电极2', depth: '118', current: '29.2'),
                  ),
                  // 电极3（下方中间）
                  Positioned(
                    top: screenWidth * 0.5 * 0.40,
                    left: (screenWidth * 0.5) / 2 - 60,
                    child: _ElectrodeWidget(label: '电极3', depth: '123', current: '27.8'),
                  ),
                ],
              ),
            ),
          ),
          // 左侧面板组（料仓 + 蝶阀）- 第一列
          Positioned(
            left: 16,
            top: 16,
            bottom: 16,
            width: (screenWidth - 48) / 3,
            child: SizedBox(
              width: (screenWidth - 48) / 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 顶部面板（无标题）
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return TechPanel(
                          height: constraints.maxHeight,
                          accentColor: TechColors.glowOrange,
                          child: const ElectrodeCurrentChart(
                            electrodes: [
                              ElectrodeData(name: '电极1', setValue: 30.0, actualValue: 28.5),
                              ElectrodeData(name: '电极2', setValue: 30.0, actualValue: 29.2),
                              ElectrodeData(name: '电极3', setValue: 30.0, actualValue: 27.8),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 料仓面板
                  TechPanel(
                    title: '料仓',
                    accentColor: TechColors.glowCyan,
                    padding: const EdgeInsets.all(8),
                    headerActions: [
                      _buildFanStatusIndicator(),
                    ],
                    child: DataCard(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      items: const [
                        DataItem(icon: Icons.thermostat, label: '除尘器入口温度', value: '85.6', unit: '℃', iconColor: TechColors.glowOrange, threshold: 80.0, isAboveThreshold: true),
                        DataItem(icon: Icons.air, label: '除尘器排风口 PM10 浓度', value: '12.3', unit: 'µg/m³', iconColor: TechColors.glowGreen, threshold: 10.0, isAboveThreshold: true),
                        DataItem(icon: Icons.flash_on, label: '除尘器风机瞬时功率', value: '45.2', unit: 'kW', iconColor: TechColors.glowCyan),
                        DataItem(icon: Icons.electric_meter, label: '除尘器风机累计能耗', value: '1280.5', unit: 'kWh', iconColor: TechColors.glowBlue),
                        DataItem(icon: Icons.vibration, label: '除尘器风机振动幅值', value: '2.8', unit: 'mm/s', iconColor: TechColors.glowRed),
                        DataItem(icon: Icons.graphic_eq, label: '除尘器风机振动频谱', value: '50.0', unit: 'Hz', iconColor: TechColors.statusWarning),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 蝶阀面板
                  TechPanel(
                    title: '蝶阀',
                    accentColor: TechColors.glowGreen,
                    padding: const EdgeInsets.all(8),
                    child: ValveControlPanel(
                      valves: _appState.valves.map((v) => ValveItem(
                        id: v.id,
                        name: v.name,
                        status: v.status,
                        openingDegree: v.openingDegree,
                      )).toList(),
                      onValveChanged: _onValveChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 电炉和前置过滤器面板（图片下方，和左侧等高）- 第二列和第三列
          Positioned(
            left: 16 + (screenWidth - 48) / 3 + 8,
            top: 16,
            bottom: 16,
            width: (screenWidth - 48) * 0.42,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: TechPanel(
                title: '电炉',
                accentColor: TechColors.glowOrange,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: FurnaceDataCard(
                        items: const [
                          DataItem(icon: Icons.thermostat, label: '炉皮温度1', value: '420', unit: '℃', iconColor: TechColors.glowRed, threshold: 400, isAboveThreshold: true),
                          DataItem(icon: Icons.thermostat, label: '炉皮温度2', value: '398', unit: '℃', iconColor: TechColors.glowRed, threshold: 400, isAboveThreshold: true),
                          DataItem(icon: Icons.thermostat, label: '炉皮温度3', value: '410', unit: '℃', iconColor: TechColors.glowRed, threshold: 400, isAboveThreshold: true),
                          DataItem(icon: Icons.thermostat, label: '炉皮温度4', value: '385', unit: '℃', iconColor: TechColors.glowRed, threshold: 400, isAboveThreshold: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FurnacePowerCard(power: '320.5', energy: '15800'),
                          const Divider(height: 16, color: TechColors.borderDark),
                          FurnaceDataCard(
                            items: const [
                              DataItem(icon: Icons.water, label: '冷却水流速', value: '2.5', unit: 'm³/h', iconColor: TechColors.glowCyan, threshold: 2.0, isAboveThreshold: false),
                              DataItem(icon: Icons.opacity, label: '冷却水水压', value: '0.18', unit: 'MPa', iconColor: TechColors.glowCyan, threshold: 0.15, isAboveThreshold: false),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 第三列 - 重量和前置过滤器面板
          Positioned(
            left: 16 + (screenWidth - 48) / 3 + 8 + (screenWidth - 48) * 0.42 + 8,
            top: 16,
            bottom: 16,
            width: (screenWidth - 48) * 0.25,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 重量面板
                  TechPanel(
                    title: '重量',
                    accentColor: TechColors.glowOrange,
                    padding: const EdgeInsets.all(8),
                    child: DataCard(
                      items: const [
                        DataItem(icon: Icons.scale, label: '料仓重量', value: '2350', unit: 'kg', iconColor: TechColors.glowOrange),
                        DataItem(icon: Icons.arrow_downward, label: '投料重量', value: '185', unit: 'kg', iconColor: TechColors.glowOrange),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 前置过滤器面板
                  TechPanel(
                    title: '前置过滤器',
                    accentColor: TechColors.glowBlue,
                    padding: const EdgeInsets.all(8),
                    child: DataCard(
                      items: const [
                        DataItem(icon: Icons.compress, label: '进出口压差', value: '125.6', unit: 'Pa', iconColor: TechColors.glowBlue, threshold: 100.0, isAboveThreshold: true),
                      ],
                    ),
                  ),
                ],
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
    Widget buildRow(IconData icon, String label, String value, String unit, Color color) {
      return Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(color: TechColors.textSecondary, fontSize: 16)),
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
          Text(unit, style: const TextStyle(color: TechColors.textSecondary, fontSize: 16)),
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
          buildRow(Icons.electric_meter, '累计能耗', energy, 'kWh', TechColors.glowBlue),
        ],
      ),
    );
  }
}

/// 电极数据小部件（显示深度和电流）
class _ElectrodeWidget extends StatelessWidget {
  final String label;
  final String depth;
  final String current;
  
  const _ElectrodeWidget({
    required this.label,
    required this.depth,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: TechColors.glowCyan, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: TechColors.glowCyan.withOpacity(0.25),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：电极标签
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, color: TechColors.glowCyan, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: TechColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                  fontSize: 12,
                ),
              ),
              Text(
                depth,
                style: TextStyle(
                  color: TechColors.glowCyan,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto Mono',
                  shadows: [
                    Shadow(
                      color: TechColors.glowCyan.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                'mm',
                style: TextStyle(
                  color: TechColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 第三行：电流数据
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '电流 ',
                style: TextStyle(
                  color: TechColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                current,
                style: TextStyle(
                  color: TechColors.glowOrange,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto Mono',
                  shadows: [
                    Shadow(
                      color: TechColors.glowOrange.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                'kA',
                style: TextStyle(
                  color: TechColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
