import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 实时数据配置 Provider
/// 用于持久化存储电流设定值、告警阈值等配置参数
///
/// 电流设定值: 5978 A (梯形图设定值 2989 × 2)
/// 低位告警: 5978 * 85% = 5081.3 A
/// 高位告警: 5978 * 115% = 6874.7 A

/// 固定颜色配置
class ThresholdColors {
  static const Color normal = Color(0xFF00ff88); // 绿色 - 正常
  static const Color warning = Color(0xFFffcc00); // 黄色 - 警告
  static const Color alarm = Color(0xFFff3b30); // 红色 - 危险/报警
}

/// 电极电流阈值配置
class ElectrodeThresholdConfig {
  final String key; // 电极键值
  final String displayName; // 显示名称
  double setValueA; // 设定值 (A)
  double lowAlarmA; // 低位告警 (A)
  double highAlarmA; // 高位告警 (A)

  ElectrodeThresholdConfig({
    required this.key,
    required this.displayName,
    this.setValueA = 5978.0,
    this.lowAlarmA = 5081.3, // 5978 * 0.85
    this.highAlarmA = 6874.7, // 5978 * 1.15
  });

  /// 设定值 (kA)
  double get setValueKA => setValueA / 1000.0;

  /// 低位告警 (kA)
  double get lowAlarmKA => lowAlarmA / 1000.0;

  /// 高位告警 (kA)
  double get highAlarmKA => highAlarmA / 1000.0;

  Map<String, dynamic> toJson() => {
        'key': key,
        'displayName': displayName,
        'setValueA': setValueA,
        'lowAlarmA': lowAlarmA,
        'highAlarmA': highAlarmA,
      };

  factory ElectrodeThresholdConfig.fromJson(Map<String, dynamic> json) {
    return ElectrodeThresholdConfig(
      key: json['key'] as String,
      displayName: json['displayName'] as String,
      setValueA: (json['setValueA'] as num?)?.toDouble() ?? 5978.0,
      lowAlarmA: (json['lowAlarmA'] as num?)?.toDouble() ?? 5081.3,
      highAlarmA: (json['highAlarmA'] as num?)?.toDouble() ?? 6874.7,
    );
  }

  ElectrodeThresholdConfig copyWith({
    double? setValueA,
    double? lowAlarmA,
    double? highAlarmA,
  }) {
    return ElectrodeThresholdConfig(
      key: key,
      displayName: displayName,
      setValueA: setValueA ?? this.setValueA,
      lowAlarmA: lowAlarmA ?? this.lowAlarmA,
      highAlarmA: highAlarmA ?? this.highAlarmA,
    );
  }

  /// 根据电流值获取状态颜色
  /// value: 电流值 (A)
  Color getColor(double valueA) {
    if (valueA < lowAlarmA) {
      return ThresholdColors.alarm; // 低于低位告警 - 红色
    } else if (valueA > highAlarmA) {
      return ThresholdColors.alarm; // 高于高位告警 - 红色
    } else if (valueA < setValueA * 0.9 || valueA > setValueA * 1.1) {
      return ThresholdColors.warning; // 接近告警范围 - 黄色
    } else {
      return ThresholdColors.normal; // 正常范围 - 绿色
    }
  }

  /// 判断是否在告警范围内
  /// value: 电流值 (A)
  bool isInAlarm(double valueA) {
    return valueA < lowAlarmA || valueA > highAlarmA;
  }

  /// 判断是否在警告范围内
  /// value: 电流值 (A)
  bool isInWarning(double valueA) {
    return (valueA >= lowAlarmA && valueA < setValueA * 0.9) ||
        (valueA > setValueA * 1.1 && valueA <= highAlarmA);
  }
}

/// 通用阈值配置
class ThresholdConfig {
  final String key; // 设备键值
  final String displayName; // 显示名称
  double normalMax; // 正常上限
  double warningMax; // 警告上限（超过此值为报警）

  ThresholdConfig({
    required this.key,
    required this.displayName,
    this.normalMax = 0.0,
    this.warningMax = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'displayName': displayName,
        'normalMax': normalMax,
        'warningMax': warningMax,
      };

  factory ThresholdConfig.fromJson(Map<String, dynamic> json) {
    return ThresholdConfig(
      key: json['key'] as String,
      displayName: json['displayName'] as String,
      normalMax: (json['normalMax'] as num?)?.toDouble() ?? 0.0,
      warningMax: (json['warningMax'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ThresholdConfig copyWith({
    double? normalMax,
    double? warningMax,
  }) {
    return ThresholdConfig(
      key: key,
      displayName: displayName,
      normalMax: normalMax ?? this.normalMax,
      warningMax: warningMax ?? this.warningMax,
    );
  }

  /// 根据数值获取状态颜色
  Color getColor(double value) {
    if (value <= normalMax) {
      return ThresholdColors.normal;
    } else if (value <= warningMax) {
      return ThresholdColors.warning;
    } else {
      return ThresholdColors.alarm;
    }
  }
}

/// 实时数据配置 Provider
///
/// 🔧 性能优化:
/// - 使用 Map 缓存替代 List.firstWhere 线性查找 (O(n) → O(1))
/// - 缓存在配置加载后构建，避免每次 build 重复查找
class RealtimeConfigProvider extends ChangeNotifier {
  static const String _storageKey = 'realtime_threshold_config_v1';

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // 🔧 性能优化: 使用 Map 缓存加速查找 (O(1) 替代 O(n))
  final Map<String, ElectrodeThresholdConfig> _electrodeCache = {};
  final Map<String, ThresholdConfig> _distanceCache = {};
  final Map<String, ThresholdConfig> _pressureCache = {};
  final Map<String, ThresholdConfig> _dustCache = {};

  // ============================================================
  // 电极电流配置 (3个电极)
  // 设定值: 5978 A (梯形图设定值 2989 × 2)
  // 低位告警: 5978 * 85% = 5081.3 A
  // 高位告警: 5978 * 115% = 6874.7 A
  // ============================================================
  final List<ElectrodeThresholdConfig> electrodeConfigs = [
    ElectrodeThresholdConfig(
      key: 'electrode_1',
      displayName: '电极1电流',
      setValueA: 5978.0,
      lowAlarmA: 5081.3, // 5978 * 0.85
      highAlarmA: 6874.7, // 5978 * 1.15
    ),
    ElectrodeThresholdConfig(
      key: 'electrode_2',
      displayName: '电极2电流',
      setValueA: 5978.0,
      lowAlarmA: 5081.3,
      highAlarmA: 6874.7,
    ),
    ElectrodeThresholdConfig(
      key: 'electrode_3',
      displayName: '电极3电流',
      setValueA: 5978.0,
      lowAlarmA: 5081.3,
      highAlarmA: 6874.7,
    ),
  ];

  // ============================================================
  // 测距配置 (3个测距传感器)
  // 单位: mm, 低点150mm=0.15m, 高点1960mm=1.96m
  // ============================================================
  final List<ThresholdConfig> distanceConfigs = [
    ThresholdConfig(
      key: 'distance_1',
      displayName: '测距1',
      normalMax: 1960.0,
      warningMax: 2000.0,
    ),
    ThresholdConfig(
      key: 'distance_2',
      displayName: '测距2',
      normalMax: 1960.0,
      warningMax: 2000.0,
    ),
    ThresholdConfig(
      key: 'distance_3',
      displayName: '测距3',
      normalMax: 1960.0,
      warningMax: 2000.0,
    ),
  ];

  // ============================================================
  // 压力/流量配置
  // ============================================================
  final List<ThresholdConfig> pressureConfigs = [
    ThresholdConfig(
      key: 'water_pressure_1',
      displayName: '冷却水水压1',
      normalMax: 0.5,
      warningMax: 1.0,
    ),
    ThresholdConfig(
      key: 'water_pressure_2',
      displayName: '冷却水水压2',
      normalMax: 0.5,
      warningMax: 1.0,
    ),
    ThresholdConfig(
      key: 'filter_pressure_diff',
      displayName: '前置过滤器压差',
      normalMax: 0.3,
      warningMax: 0.5,
    ),
    ThresholdConfig(
      key: 'flow_rate',
      displayName: '冷却水流速',
      normalMax: 5.0,
      warningMax: 10.0,
    ),
  ];

  // ============================================================
  // 除尘器配置
  // ============================================================
  final List<ThresholdConfig> dustConfigs = [
    ThresholdConfig(
      key: 'dust_temp',
      displayName: '除尘器温度',
      normalMax: 150.0,
      warningMax: 200.0,
    ),
    ThresholdConfig(
      key: 'dust_pm10',
      displayName: '除尘器PM10浓度',
      normalMax: 50.0,
      warningMax: 100.0,
    ),
  ];

  /// 初始化加载配置
  Future<void> loadConfig() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _loadFromJson(json);
      }

      _buildCaches();
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('加载配置失败: $e');
      _buildCaches();
      _isLoaded = true;
    }
  }

  /// 🔧 构建缓存 Map (O(1) 查找替代 O(n) 遍历)
  void _buildCaches() {
    _electrodeCache.clear();
    for (var config in electrodeConfigs) {
      _electrodeCache[config.key] = config;
    }

    _distanceCache.clear();
    for (var config in distanceConfigs) {
      _distanceCache[config.key] = config;
    }

    _pressureCache.clear();
    for (var config in pressureConfigs) {
      _pressureCache[config.key] = config;
    }

    _dustCache.clear();
    for (var config in dustConfigs) {
      _dustCache[config.key] = config;
    }
  }

  void _loadFromJson(Map<String, dynamic> json) {
    // 加载电极配置
    if (json.containsKey('electrodes')) {
      final electrodesJson = json['electrodes'] as List<dynamic>;
      for (var i = 0; i < electrodesJson.length && i < electrodeConfigs.length; i++) {
        final configJson = electrodesJson[i] as Map<String, dynamic>;
        electrodeConfigs[i] = ElectrodeThresholdConfig.fromJson(configJson);
      }
    }

    // 加载测距配置
    if (json.containsKey('distances')) {
      final distancesJson = json['distances'] as List<dynamic>;
      for (var i = 0; i < distancesJson.length && i < distanceConfigs.length; i++) {
        final configJson = distancesJson[i] as Map<String, dynamic>;
        distanceConfigs[i] = ThresholdConfig.fromJson(configJson);
      }
    }

    // 加载压力配置
    if (json.containsKey('pressures')) {
      final pressuresJson = json['pressures'] as List<dynamic>;
      for (var i = 0; i < pressuresJson.length && i < pressureConfigs.length; i++) {
        final configJson = pressuresJson[i] as Map<String, dynamic>;
        pressureConfigs[i] = ThresholdConfig.fromJson(configJson);
      }
    }

    // 加载除尘器配置
    if (json.containsKey('dusts')) {
      final dustsJson = json['dusts'] as List<dynamic>;
      for (var i = 0; i < dustsJson.length && i < dustConfigs.length; i++) {
        final configJson = dustsJson[i] as Map<String, dynamic>;
        dustConfigs[i] = ThresholdConfig.fromJson(configJson);
      }
    }
  }

  Map<String, dynamic> _toJson() {
    return {
      'electrodes': electrodeConfigs.map((e) => e.toJson()).toList(),
      'distances': distanceConfigs.map((e) => e.toJson()).toList(),
      'pressures': pressureConfigs.map((e) => e.toJson()).toList(),
      'dusts': dustConfigs.map((e) => e.toJson()).toList(),
    };
  }

  /// 保存配置
  Future<bool> saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_toJson());
      await prefs.setString(_storageKey, jsonString);
      return true;
    } catch (e) {
      debugPrint('保存配置失败: $e');
      return false;
    }
  }

  /// 更新电极配置
  void updateElectrodeConfig(int index, {
    double? setValueA,
    double? lowAlarmA,
    double? highAlarmA,
  }) {
    if (index < 0 || index >= electrodeConfigs.length) return;
    electrodeConfigs[index] = electrodeConfigs[index].copyWith(
      setValueA: setValueA,
      lowAlarmA: lowAlarmA,
      highAlarmA: highAlarmA,
    );
    _electrodeCache[electrodeConfigs[index].key] = electrodeConfigs[index];
    notifyListeners();
  }

  /// 按百分比更新电极告警阈值
  /// setValueA: 设定值 (A)
  /// lowPercent: 低位告警百分比 (例如 0.85 表示 85%)
  /// highPercent: 高位告警百分比 (例如 1.15 表示 115%)
  void updateElectrodeConfigByPercent(int index, {
    required double setValueA,
    double lowPercent = 0.85,
    double highPercent = 1.15,
  }) {
    if (index < 0 || index >= electrodeConfigs.length) return;
    electrodeConfigs[index] = electrodeConfigs[index].copyWith(
      setValueA: setValueA,
      lowAlarmA: setValueA * lowPercent,
      highAlarmA: setValueA * highPercent,
    );
    _electrodeCache[electrodeConfigs[index].key] = electrodeConfigs[index];
    notifyListeners();
  }

  /// 批量更新所有电极配置
  void updateAllElectrodeConfigs({
    required double setValueA,
    double lowPercent = 0.85,
    double highPercent = 1.15,
  }) {
    for (var i = 0; i < electrodeConfigs.length; i++) {
      electrodeConfigs[i] = electrodeConfigs[i].copyWith(
        setValueA: setValueA,
        lowAlarmA: setValueA * lowPercent,
        highAlarmA: setValueA * highPercent,
      );
      _electrodeCache[electrodeConfigs[i].key] = electrodeConfigs[i];
    }
    notifyListeners();
  }

  /// 重置为默认配置
  void resetToDefault() {
    // 重置电极配置
    for (var i = 0; i < electrodeConfigs.length; i++) {
      electrodeConfigs[i] = ElectrodeThresholdConfig(
        key: electrodeConfigs[i].key,
        displayName: electrodeConfigs[i].displayName,
        setValueA: 2989.0,
        lowAlarmA: 2540.65,
        highAlarmA: 3437.35,
      );
    }

    // 重置测距配置
    for (var i = 0; i < distanceConfigs.length; i++) {
      distanceConfigs[i] = ThresholdConfig(
        key: distanceConfigs[i].key,
        displayName: distanceConfigs[i].displayName,
        normalMax: 1960.0,
        warningMax: 2000.0,
      );
    }

    _buildCaches();
    notifyListeners();
  }

  // ============================================================
  // 便捷获取方法
  // 🔧 性能优化: 使用缓存 Map 替代 List.firstWhere (O(1) vs O(n))
  // ============================================================

  /// 获取电极设定值 (kA)
  /// index: 电极索引 (0, 1, 2)
  double getElectrodeSetValueKA(int index) {
    if (index < 0 || index >= electrodeConfigs.length) return 29.89;
    return electrodeConfigs[index].setValueKA;
  }

  /// 获取电极低位告警 (kA)
  double getElectrodeLowAlarmKA(int index) {
    if (index < 0 || index >= electrodeConfigs.length) return 25.41;
    return electrodeConfigs[index].lowAlarmKA;
  }

  /// 获取电极高位告警 (kA)
  double getElectrodeHighAlarmKA(int index) {
    if (index < 0 || index >= electrodeConfigs.length) return 34.37;
    return electrodeConfigs[index].highAlarmKA;
  }

  /// 根据电流值获取颜色
  /// index: 电极索引 (0, 1, 2)
  /// valueA: 电流值 (A)
  Color getElectrodeColor(int index, double valueA) {
    if (index < 0 || index >= electrodeConfigs.length) {
      return ThresholdColors.normal;
    }
    return electrodeConfigs[index].getColor(valueA);
  }

  /// 判断电流是否在告警范围
  bool isElectrodeInAlarm(int index, double valueA) {
    if (index < 0 || index >= electrodeConfigs.length) return false;
    return electrodeConfigs[index].isInAlarm(valueA);
  }

  /// 获取测距阈值配置
  ThresholdConfig? getDistanceThreshold(String key) {
    return _distanceCache[key];
  }

  /// 获取压力阈值配置
  ThresholdConfig? getPressureThreshold(String key) {
    return _pressureCache[key];
  }

  /// 获取除尘器阈值配置
  ThresholdConfig? getDustThreshold(String key) {
    return _dustCache[key];
  }
}
