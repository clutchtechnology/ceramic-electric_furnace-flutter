import 'package:flutter/material.dart';
import '../widgets/tech_line_widgets.dart';
import '../widgets/data_card.dart';
import '../widgets/valve_control.dart';

/// 数据大屏页面
/// 用于显示智能生产线数字孪生系统的数据大屏内容
class DataScreenPage extends StatefulWidget {
  const DataScreenPage({super.key});

  @override
  State<DataScreenPage> createState() => _DataScreenPageState();
}

class _DataScreenPageState extends State<DataScreenPage> {
  // 4路蝶阀状态
  List<ValveItem> _valves = [
    const ValveItem(id: '1', name: '1号蝶阀', isOpen: true),
    const ValveItem(id: '2', name: '2号蝶阀', isOpen: false),
    const ValveItem(id: '3', name: '3号蝶阀', isOpen: true),
    const ValveItem(id: '4', name: '4号蝶阀', isOpen: false),
  ];

  void _onValveChanged(ValveItem valve) {
    setState(() {
      _valves = _valves.map((v) {
        if (v.id == valve.id) {
          return valve;
        }
        return v;
      }).toList();
    });
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
            right: screenWidth * 0.05,
            top: 16,
            width: screenWidth * 0.5,
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/furnace.png',
                  fit: BoxFit.contain,
                ),
                // 电极1（左上）
                Positioned(
                  top: screenWidth * 0.5 * 0.15,
                  left: (screenWidth * 0.5) / 2 - 180,
                  child: _ElectrodeDepthWidget(label: '电极1', value: '120', unit: 'mm'),
                ),
                // 电极2（右上）
                Positioned(
                  top: screenWidth * 0.5 * 0.15,
                  left: (screenWidth * 0.5) / 2 + 60,
                  child: _ElectrodeDepthWidget(label: '电极2', value: '118', unit: 'mm'),
                ),
                // 电极3（下方中间）
                Positioned(
                  top: screenWidth * 0.5 * 0.40,
                  left: (screenWidth * 0.5) / 2 - 60,
                  child: _ElectrodeDepthWidget(label: '电极3', value: '123', unit: 'mm'),
                ),
              ],
            ),
          ),
          // 左侧面板组（料仓 + 蝶阀）
          Positioned(
            left: 16,
            top: 32,
            bottom: 32,
            child: SizedBox(
              width: screenWidth * 0.40 - 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 料仓面板
                  TechPanel(
                    title: '料仓',
                    accentColor: TechColors.glowCyan,
                    child: DataCard(
                      items: const [
                        DataItem(icon: Icons.thermostat, label: '除尘器入口温度', value: '85.6', unit: '℃', iconColor: TechColors.glowOrange),
                        DataItem(icon: Icons.air, label: '除尘器排风口 PM10 浓度', value: '12.3', unit: 'µg/m³', iconColor: TechColors.glowGreen, threshold: 10.0, isAboveThreshold: true),
                        DataItem(icon: Icons.flash_on, label: '除尘器风机瞬时功率', value: '45.2', unit: 'kW', iconColor: TechColors.glowCyan),
                        DataItem(icon: Icons.electric_meter, label: '除尘器风机累计能耗', value: '1280.5', unit: 'kWh', iconColor: TechColors.glowBlue),
                        DataItem(icon: Icons.vibration, label: '除尘器风机振动幅值', value: '2.8', unit: 'mm/s', iconColor: TechColors.glowRed),
                        DataItem(icon: Icons.graphic_eq, label: '除尘器风机振动频谱', value: '50.0', unit: 'Hz', iconColor: TechColors.statusWarning),
                      ],
                    ),
                  ),
                  // 蝶阀面板
                  TechPanel(
                    title: '蝶阀',
                    accentColor: TechColors.glowGreen,
                    child: ValveControlPanel(
                      valves: _valves,
                      onValveChanged: _onValveChanged,
                    ),
                  ),
                  // 前置过滤器面板
                  TechPanel(
                    title: '前置过滤器',
                    accentColor: TechColors.glowBlue,
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
          // 电炉面板（图片下方，和左侧等高）
          Positioned(
            right: 16,
            top: 32,
            bottom: 32,
            width: screenWidth * 0.58,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: TechPanel(
                title: '电炉',
                accentColor: TechColors.glowOrange,
                child: Row(
                  children: [
                    Expanded(
                      child: DataCard(
                        items: const [
                          DataItem(icon: Icons.thermostat, label: '炉皮温度1', value: '420', unit: '℃', iconColor: TechColors.glowRed, threshold: 400, isAboveThreshold: true),
                          DataItem(icon: Icons.thermostat, label: '炉皮温度2', value: '398', unit: '℃', iconColor: TechColors.glowRed, threshold: 400, isAboveThreshold: true),
                          DataItem(icon: Icons.thermostat, label: '炉皮温度3', value: '410', unit: '℃', iconColor: TechColors.glowRed, threshold: 400, isAboveThreshold: true),
                          DataItem(icon: Icons.thermostat, label: '炉皮温度4', value: '385', unit: '℃', iconColor: TechColors.glowRed, threshold: 400, isAboveThreshold: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FurnacePowerCard(power: '320.5', energy: '15800'),
                          const Divider(height: 32, color: TechColors.borderDark),
                          DataCard(
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

/// 电极深度小部件
class _ElectrodeDepthWidget extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _ElectrodeDepthWidget({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.85),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: TechColors.glowCyan, width: 1),
        boxShadow: [
          BoxShadow(
            color: TechColors.glowCyan.withOpacity(0.18),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: TechColors.glowCyan, size: 18),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: TechColors.textSecondary, fontSize: 14)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(color: TechColors.glowCyan, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Roboto Mono')),
          const SizedBox(width: 2),
          Text(unit, style: const TextStyle(color: TechColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
