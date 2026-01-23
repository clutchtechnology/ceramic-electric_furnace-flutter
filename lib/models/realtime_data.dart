/// 实时数据模型
/// 对应后端 /api/furnace/realtime/* 接口返回的数据

/// ============================================================
/// 弧流弧压数据 (快速接口 0.2s)
/// 对应后端 /api/furnace/realtime/arc
/// ============================================================
class ArcRealtimeData {
  final Map<String, double> arcCurrent; // 三相弧流 {U, V, W} (A)
  final Map<String, double> arcVoltage; // 三相弧压 {U, V, W} (V)
  final Map<String, double> setpoints; // 三相设定值 {U, V, W} (A)
  final double manualDeadzonePercent; // 手动死区百分比 (%)
  final String? timestamp;

  ArcRealtimeData({
    required this.arcCurrent,
    required this.arcVoltage,
    required this.setpoints,
    required this.manualDeadzonePercent,
    this.timestamp,
  });

  factory ArcRealtimeData.fromJson(Map<String, dynamic> json) {
    return ArcRealtimeData(
      arcCurrent: {
        'U': (json['arc_current']?['U'] ?? 0.0).toDouble(),
        'V': (json['arc_current']?['V'] ?? 0.0).toDouble(),
        'W': (json['arc_current']?['W'] ?? 0.0).toDouble(),
      },
      arcVoltage: {
        'U': (json['arc_voltage']?['U'] ?? 0.0).toDouble(),
        'V': (json['arc_voltage']?['V'] ?? 0.0).toDouble(),
        'W': (json['arc_voltage']?['W'] ?? 0.0).toDouble(),
      },
      setpoints: {
        'U': (json['setpoints']?['U'] ?? 0.0).toDouble(),
        'V': (json['setpoints']?['V'] ?? 0.0).toDouble(),
        'W': (json['setpoints']?['W'] ?? 0.0).toDouble(),
      },
      manualDeadzonePercent:
          (json['manual_deadzone_percent'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'],
    );
  }

  factory ArcRealtimeData.empty() {
    return ArcRealtimeData(
      arcCurrent: {'U': 0.0, 'V': 0.0, 'W': 0.0},
      arcVoltage: {'U': 0.0, 'V': 0.0, 'W': 0.0},
      setpoints: {'U': 0.0, 'V': 0.0, 'W': 0.0},
      manualDeadzonePercent: 0.0,
    );
  }
}

/// ============================================================
/// 传感器数据 (慢速接口 0.5s)
/// 对应后端 /api/furnace/realtime/sensor
/// ============================================================
class SensorRealtimeData {
  final Map<String, double> electrodeDepths; // 三个电极深度 {1, 2, 3} (mm)
  final Map<int, String> valveStatus; // 蝶阀状态 {1-4} ("01"开/"10"关/"00"停)
  final Map<int, double> valveOpenness; // 蝶阀开度 {1-4} (%)
  final CoolingRealtimeData cooling; // 冷却水数据
  final HopperRealtimeData hopper; // 料仓数据
  final BatchInfo? batch; // 批次信息
  final String? timestamp;

  SensorRealtimeData({
    required this.electrodeDepths,
    required this.valveStatus,
    required this.valveOpenness,
    required this.cooling,
    required this.hopper,
    this.batch,
    this.timestamp,
  });

  factory SensorRealtimeData.fromJson(Map<String, dynamic> json) {
    // 解析电极深度
    final depthsJson = json['electrode_depths'] as Map<String, dynamic>? ?? {};
    final depths = <String, double>{};
    depthsJson.forEach((key, value) {
      depths[key] = (value ?? 0.0).toDouble();
    });

    // 解析蝶阀状态
    final statusJson = json['valve_status'] as Map<String, dynamic>? ?? {};
    final statuses = <int, String>{};
    statusJson.forEach((key, value) {
      statuses[int.tryParse(key) ?? 0] = value?.toString() ?? '00';
    });

    // 解析蝶阀开度
    // 后端返回格式: {"1": {"valve_id": 1, "openness_percent": 0.0, ...}, ...}
    final opennessJson = json['valve_openness'] as Map<String, dynamic>? ?? {};
    final openness = <int, double>{};
    opennessJson.forEach((key, value) {
      if (value is Map) {
        // 嵌套对象格式，提取 openness_percent
        openness[int.tryParse(key) ?? 0] =
            (value['openness_percent'] ?? 0.0).toDouble();
      } else {
        // 简单数值格式 (向后兼容)
        openness[int.tryParse(key) ?? 0] = (value ?? 0.0).toDouble();
      }
    });

    return SensorRealtimeData(
      electrodeDepths: depths,
      valveStatus: statuses,
      valveOpenness: openness,
      cooling: CoolingRealtimeData.fromJson(json['cooling'] ?? {}),
      hopper: HopperRealtimeData.fromJson(json['hopper'] ?? {}),
      batch: json['batch'] != null ? BatchInfo.fromJson(json['batch']) : null,
      timestamp: json['timestamp'],
    );
  }

  factory SensorRealtimeData.empty() {
    return SensorRealtimeData(
      electrodeDepths: {'1': 0.0, '2': 0.0, '3': 0.0},
      valveStatus: {1: '00', 2: '00', 3: '00', 4: '00'},
      valveOpenness: {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0},
      cooling: CoolingRealtimeData(
        furnaceShell:
            CoolingWaterData(flowM3h: 0.0, pressureKPa: 0.0, totalM3: 0.0),
        furnaceCover:
            CoolingWaterData(flowM3h: 0.0, pressureKPa: 0.0, totalM3: 0.0),
        filterPressureDiffKPa: 0.0,
      ),
      hopper: HopperRealtimeData(
          weightKg: 0.0, feedingTotalKg: 0.0, success: false),
      batch: BatchInfo(isSmelting: false),
    );
  }
}

/// ============================================================
/// 原有模型 (保留兼容性)
/// ============================================================

/// 电极数据
class ElectrodeRealtimeData {
  final int id;
  final String name;
  final double depthMm; // 深度 mm
  final double currentA; // 电流 A (弧流，目标值约 5978 A)
  final double voltageV; // 电压 V (弧压，目标值约 80 V)

  ElectrodeRealtimeData({
    required this.id,
    required this.name,
    required this.depthMm,
    required this.currentA,
    required this.voltageV,
  });

  factory ElectrodeRealtimeData.fromJson(Map<String, dynamic> json) {
    return ElectrodeRealtimeData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      depthMm: (json['depth_mm'] ?? 0).toDouble(),
      currentA: (json['current_A'] ?? 0).toDouble(),
      voltageV: (json['voltage_V'] ?? 0).toDouble(),
    );
  }
}

/// 电表数据
class ElectricityRealtimeData {
  final double powerKW; // 功率 kW
  final double energyKWh; // 能耗 kWh
  final List<double> currentsA; // 三相电流 [I_0, I_1, I_2] A
  final String? timestamp;

  ElectricityRealtimeData({
    required this.powerKW,
    required this.energyKWh,
    required this.currentsA,
    this.timestamp,
  });

  factory ElectricityRealtimeData.fromJson(Map<String, dynamic> json) {
    final currents = json['currents_A'];
    List<double> currentsList;
    if (currents is List) {
      currentsList = currents.map<double>((e) => (e ?? 0).toDouble()).toList();
    } else {
      currentsList = [0.0, 0.0, 0.0];
    }
    return ElectricityRealtimeData(
      powerKW: (json['power_kW'] ?? 0).toDouble(),
      energyKWh: (json['energy_kWh'] ?? 0).toDouble(),
      currentsA: currentsList,
      timestamp: json['timestamp'],
    );
  }
}

/// 冷却水数据（单个）
class CoolingWaterData {
  final double flowM3h; // 流速 m³/h
  final double pressureKPa; // 水压 kPa
  final double totalM3; // 累计用量 m³

  CoolingWaterData({
    required this.flowM3h,
    required this.pressureKPa,
    required this.totalM3,
  });

  factory CoolingWaterData.fromJson(Map<String, dynamic> json) {
    return CoolingWaterData(
      flowM3h: (json['flow_m3h'] ?? 0.0).toDouble(),
      pressureKPa: (json['pressure_kPa'] ?? 0.0).toDouble(),
      totalM3: (json['total_m3'] ?? 0.0).toDouble(),
    );
  }
}

/// 冷却水汇总数据
class CoolingRealtimeData {
  final CoolingWaterData furnaceShell; // 炉皮冷却水
  final CoolingWaterData furnaceCover; // 炉盖冷却水
  final double filterPressureDiffKPa; // 前置过滤器压差 kPa
  final String? timestamp;

  CoolingRealtimeData({
    required this.furnaceShell,
    required this.furnaceCover,
    required this.filterPressureDiffKPa,
    this.timestamp,
  });

  factory CoolingRealtimeData.fromJson(Map<String, dynamic> json) {
    return CoolingRealtimeData(
      furnaceShell: CoolingWaterData.fromJson(json['furnace_shell'] ?? {}),
      furnaceCover: CoolingWaterData.fromJson(json['furnace_cover'] ?? {}),
      filterPressureDiffKPa: (json['filter_pressure_diff_kPa'] ?? 0).toDouble(),
      timestamp: json['timestamp'],
    );
  }
}

/// 料仓数据
class HopperRealtimeData {
  final double weightKg; // 当前重量 kg
  final double feedingTotalKg; // 当前批次投料总量 kg
  final bool success; // 读取是否成功
  final String? timestamp;

  HopperRealtimeData({
    required this.weightKg,
    required this.feedingTotalKg,
    required this.success,
    this.timestamp,
  });

  factory HopperRealtimeData.fromJson(Map<String, dynamic> json) {
    return HopperRealtimeData(
      weightKg: (json['weight_kg'] ?? 0).toDouble(),
      feedingTotalKg: (json['feeding_total_kg'] ?? 0).toDouble(),
      success: json['success'] ?? false,
      timestamp: json['timestamp'],
    );
  }
}

/// 批次信息
class BatchInfo {
  final String? batchCode;
  final String? startTime;
  final bool isSmelting;
  final double? durationSeconds;

  BatchInfo({
    this.batchCode,
    this.startTime,
    required this.isSmelting,
    this.durationSeconds,
  });

  factory BatchInfo.fromJson(Map<String, dynamic> json) {
    return BatchInfo(
      batchCode: json['batch_code'],
      startTime: json['start_time'],
      isSmelting: json['is_smelting'] ?? false,
      durationSeconds: json['duration_seconds']?.toDouble(),
    );
  }
}

/// 完整的实时数据响应
class RealtimeBatchData {
  final List<ElectrodeRealtimeData> electrodes;
  final ElectricityRealtimeData electricity;
  final CoolingRealtimeData cooling;
  final HopperRealtimeData hopper;
  final BatchInfo batch;

  RealtimeBatchData({
    required this.electrodes,
    required this.electricity,
    required this.cooling,
    required this.hopper,
    required this.batch,
  });

  factory RealtimeBatchData.fromJson(Map<String, dynamic> json) {
    final electrodesList = json['electrodes'] as List? ?? [];
    return RealtimeBatchData(
      electrodes:
          electrodesList.map((e) => ElectrodeRealtimeData.fromJson(e)).toList(),
      electricity: ElectricityRealtimeData.fromJson(json['electricity'] ?? {}),
      cooling: CoolingRealtimeData.fromJson(json['cooling'] ?? {}),
      hopper: HopperRealtimeData.fromJson(json['hopper'] ?? {}),
      batch: BatchInfo.fromJson(json['batch'] ?? {}),
    );
  }

  /// 创建空的默认数据（用于初始化或错误情况）
  factory RealtimeBatchData.empty() {
    return RealtimeBatchData(
      electrodes: [
        ElectrodeRealtimeData(
            id: 1, name: '电极1', depthMm: 0.0, currentA: 0.0, voltageV: 0.0),
        ElectrodeRealtimeData(
            id: 2, name: '电极2', depthMm: 0.0, currentA: 0.0, voltageV: 0.0),
        ElectrodeRealtimeData(
            id: 3, name: '电极3', depthMm: 0.0, currentA: 0.0, voltageV: 0.0),
      ],
      electricity: ElectricityRealtimeData(
        powerKW: 0.0,
        energyKWh: 0.0,
        currentsA: [0.0, 0.0, 0.0],
      ),
      cooling: CoolingRealtimeData(
        furnaceShell:
            CoolingWaterData(flowM3h: 0.0, pressureKPa: 0.0, totalM3: 0.0),
        furnaceCover:
            CoolingWaterData(flowM3h: 0.0, pressureKPa: 0.0, totalM3: 0.0),
        filterPressureDiffKPa: 0.0,
      ),
      hopper: HopperRealtimeData(
          weightKg: 0.0, feedingTotalKg: 0.0, success: false),
      batch: BatchInfo(isSmelting: false),
    );
  }
}
