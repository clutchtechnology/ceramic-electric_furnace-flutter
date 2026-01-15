// 水泵数据模型 - 泵房状态页面
// ============================================================
// 功能: 模拟水泵房监控数据，用于电炉程序中的泵房状态显示
// 注意: 仅前端展示，不连接后端API
// ============================================================

import 'dart:math';

// ============================================================
// 1, 单个水泵实时数据
// ============================================================
class PumpData {
  // 2, 水泵编号 (1-6)
  final int id;

  // 3, 电压值 (V) - 三相电压均值
  final double voltage;

  // 4, 电流值 (A) - 三相电流均值
  final double current;

  // 5, 功率值 (kW) - 有功功率
  final double power;

  // 6, 运行状态 (normal/warning/alarm/offline)
  final String status;

  // 7, 当前报警列表
  final List<String> alarms;

  PumpData({
    required this.id,
    required this.voltage,
    required this.current,
    required this.power,
    required this.status,
    required this.alarms,
  });

  // 4, 是否运行中 (电流 > 0.1A 表示电机启动)
  bool get isRunning => current > 0.1;

  // 6, 是否有报警
  bool get hasAlarm => status == 'alarm' || alarms.isNotEmpty;

  // 6, 是否有警告
  bool get hasWarning => status == 'warning';

  /// 创建离线状态空数据
  factory PumpData.empty(int id) {
    return PumpData(
      id: id,
      voltage: 0.0,
      current: 0.0,
      power: 0.0,
      status: 'offline',
      alarms: [],
    );
  }

  /// 生成模拟数据
  factory PumpData.mock(int id, {bool isRunning = true}) {
    final random = Random();
    return PumpData(
      id: id,
      voltage: isRunning ? 380 + random.nextDouble() * 10 : 0.0,
      current: isRunning ? 15 + random.nextDouble() * 5 : 0.0,
      power: isRunning ? 8 + random.nextDouble() * 4 : 0.0,
      status: isRunning ? 'normal' : 'offline',
      alarms: [],
    );
  }
}

// ============================================================
// 8, 压力表数据
// ============================================================
class PressureData {
  // 9, 压力值 (MPa)
  final double value;

  // 10, 状态 (normal/warning/alarm/offline)
  final String status;

  PressureData({
    required this.value,
    required this.status,
  });

  /// 创建离线状态空数据
  factory PressureData.empty() {
    return PressureData(value: 0.0, status: 'offline');
  }

  /// 生成模拟数据
  factory PressureData.mock() {
    final random = Random();
    return PressureData(
      value: 0.5 + random.nextDouble() * 0.3,
      status: 'normal',
    );
  }
}
