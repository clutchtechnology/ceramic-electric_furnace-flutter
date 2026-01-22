import 'package:flutter/material.dart';
import 'dart:async';
import '../models/pump_data.dart';
import '../widgets/common/tech_line_widgets.dart';
import '../widgets/shared/custom_card_widget.dart';

/// ============================================================================
/// 泵房状态页面
/// 展示6个水泵的实时运行状态
/// 注意：仅前端展示，使用模拟数据，不连接后端API
/// ============================================================================
class PumpRoomStatusPage extends StatefulWidget {
  const PumpRoomStatusPage({super.key});

  @override
  State<PumpRoomStatusPage> createState() => _PumpRoomStatusPageState();
}

class _PumpRoomStatusPageState extends State<PumpRoomStatusPage> {
  // 定时器 - 用于定期刷新模拟数据
  Timer? _refreshTimer;

  // 模拟的水泵数据 (6个水泵)
  List<PumpData> _pumps = [];

  // 模拟的压力数据
  PressureData? _pressure;

  @override
  void initState() {
    super.initState();
    _generateMockData();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// 生成模拟数据
  void _generateMockData() {
    setState(() {
      // 生成6个水泵的数据，1-5号运行，6号停止
      _pumps = List.generate(
        6,
        (index) => PumpData.mock(index + 1, isRunning: index < 5),
      );
      // 生成压力数据
      _pressure = PressureData.mock();
    });
  }

  /// 启动定时刷新 (每5秒刷新一次模拟数据)
  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _generateMockData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TechColors.bgDeep,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          children: [
            // 上半部分 - 3个水泵
            Expanded(
              child: TechPanel(
                height: double.infinity,
                accentColor: TechColors.glowCyan,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _buildPumpCard(0, hasPressure: true), // 1号泵带压力显示
                    const SizedBox(width: 8),
                    _buildPumpCard(1),
                    const SizedBox(width: 8),
                    _buildPumpCard(2),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 下半部分 - 3个水泵
            Expanded(
              child: TechPanel(
                height: double.infinity,
                accentColor: TechColors.glowCyan,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _buildPumpCard(3),
                    const SizedBox(width: 8),
                    _buildPumpCard(4),
                    const SizedBox(width: 8),
                    _buildPumpCard(5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单个水泵卡片
  Widget _buildPumpCard(int index, {bool hasPressure = false}) {
    if (index >= _pumps.length) {
      return Expanded(
        child: CustomCardWidget(
          pumpNumber: '#${index + 1}',
          power: 0.0,
          energy: 0.0,
          currentA: 0.0,
          currentB: 0.0,
          currentC: 0.0,
          isRunning: false,
          vibration: 0.0,
        ),
      );
    }

    final pump = _pumps[index];
    return Expanded(
      child: CustomCardWidget(
        pumpNumber: '#${pump.id}',
        power: pump.power,
        energy: 0.0, // 能耗暂无数据
        currentA: pump.current,
        currentB: pump.current, // 使用相同电流值
        currentC: pump.current,
        isRunning: pump.isRunning,
        vibration: 0.5, // 模拟振动数据
        pressure: hasPressure ? _pressure?.value : null, // 仅1号泵显示压力
        // 使用默认颜色
        powerColor: TechColors.glowCyan,
        currentColor: TechColors.glowCyan,
        vibrationColor: TechColors.glowGreen,
        pressureColor: TechColors.glowOrange,
      ),
    );
  }
}
