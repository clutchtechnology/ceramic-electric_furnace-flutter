import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 全局应用状态管理类
/// 负责持久化保存各个页面的操作状态
class AppState extends ChangeNotifier {
  static AppState? _instance;
  static AppState get instance => _instance!;

  late SharedPreferences _prefs;

  // 数据大屏页面状态
  bool fanRunning = true;
  bool vibrationFault = true;
  double pm10Value = 45.2;
  double pm10Threshold = 50.0;
  bool isSmelting = false;
  String smeltingCode = '';

  // 系统就绪状态 (后端+PLC都正常)
  bool isSystemReady = false;

  // 炉号配置
  String furnaceNumber = '3'; // 3号炉

  List<ValveState> valves = [
    ValveState(
        id: '1', name: '1号', status: ValveStatus.open, openingDegree: 75),
    ValveState(id: '2', name: '2号', status: ValveStatus.closed),
    ValveState(
        id: '3', name: '3号', status: ValveStatus.open, openingDegree: 85),
    ValveState(id: '4', name: '4号', status: ValveStatus.stopped),
  ];

  // 历史曲线页面状态
  DateTime furnaceEnergyStart =
      DateTime.now().subtract(const Duration(hours: 24));
  DateTime furnaceEnergyEnd = DateTime.now();
  DateTime furnaceTempStart =
      DateTime.now().subtract(const Duration(hours: 24));
  DateTime furnaceTempEnd = DateTime.now();
  DateTime preFilterStart = DateTime.now().subtract(const Duration(hours: 24));
  DateTime preFilterEnd = DateTime.now();
  DateTime dustInletStart = DateTime.now().subtract(const Duration(hours: 24));
  DateTime dustInletEnd = DateTime.now();
  DateTime fanVibrationStart =
      DateTime.now().subtract(const Duration(hours: 24));
  DateTime fanVibrationEnd = DateTime.now();

  // 数据查询页面状态
  String fanEnergyStatType = '日';
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  DateTime coolingWaterQueryStart =
      DateTime.now().subtract(const Duration(hours: 24));
  DateTime coolingWaterQueryEnd = DateTime.now();
  DateTime pm10QueryStart = DateTime.now().subtract(const Duration(hours: 24));
  DateTime pm10QueryEnd = DateTime.now();
  DateTime valveQueryStart = DateTime.now().subtract(const Duration(hours: 24));
  DateTime valveQueryEnd = DateTime.now();
  DateTime fanEnergyQueryStart =
      DateTime.now().subtract(const Duration(hours: 24));
  DateTime fanEnergyQueryEnd = DateTime.now();

  // 报警记录页面状态
  DateTime furnaceSkinStart =
      DateTime.now().subtract(const Duration(hours: 24));
  DateTime furnaceSkinEnd = DateTime.now();
  DateTime coolingWaterStart =
      DateTime.now().subtract(const Duration(hours: 24));
  DateTime coolingWaterEnd = DateTime.now();
  DateTime preFilterAlarmStart =
      DateTime.now().subtract(const Duration(hours: 24));
  DateTime preFilterAlarmEnd = DateTime.now();
  DateTime dustInletAlarmStart =
      DateTime.now().subtract(const Duration(hours: 24));
  DateTime dustInletAlarmEnd = DateTime.now();
  DateTime pm10AlarmStart = DateTime.now().subtract(const Duration(hours: 24));
  DateTime pm10AlarmEnd = DateTime.now();
  DateTime fanVibrationAlarmStart =
      DateTime.now().subtract(const Duration(hours: 24));
  DateTime fanVibrationAlarmEnd = DateTime.now();

  // 系统配置页面状态
  int systemConfigTabIndex = 0;

  /// 初始化状态管理
  static Future<void> initialize() async {
    if (_instance != null) return;

    final instance = AppState._();
    instance._prefs = await SharedPreferences.getInstance();
    await instance._loadState();
    _instance = instance;
  }

  AppState._();

  /// 从本地存储加载状态
  Future<void> _loadState() async {
    try {
      // 检查数据版本，如果版本不匹配则清除旧数据
      final dataVersion = _prefs.getInt('dataVersion') ?? 0;
      if (dataVersion < 2) {
        // 清除旧版本的蝶阀数据
        await _prefs.remove('valves');
        await _prefs.setInt('dataVersion', 2);
        debugPrint('数据版本升级，已清除旧的蝶阀数据');
      }

      // 加载数据大屏状态
      fanRunning = _prefs.getBool('fanRunning') ?? true;
      vibrationFault = _prefs.getBool('vibrationFault') ?? true;
      furnaceNumber = _prefs.getString('furnaceNumber') ?? '3';

      final valvesJson = _prefs.getString('valves');
      if (valvesJson != null) {
        try {
          final List<dynamic> valvesList = jsonDecode(valvesJson);
          valves = valvesList.map((e) => ValveState.fromJson(e)).toList();
        } catch (e) {
          debugPrint('加载蝶阀状态失败: $e，使用默认值');
          // 保持默认值不变
        }
      }

      // 加载历史曲线页面状态
      furnaceEnergyStart = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('furnaceEnergyStart') ??
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .millisecondsSinceEpoch,
      );
      furnaceEnergyEnd = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('furnaceEnergyEnd') ??
            DateTime.now().millisecondsSinceEpoch,
      );
      furnaceTempStart = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('furnaceTempStart') ??
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .millisecondsSinceEpoch,
      );
      furnaceTempEnd = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('furnaceTempEnd') ??
            DateTime.now().millisecondsSinceEpoch,
      );
      preFilterStart = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('preFilterStart') ??
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .millisecondsSinceEpoch,
      );
      preFilterEnd = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('preFilterEnd') ?? DateTime.now().millisecondsSinceEpoch,
      );
      dustInletStart = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('dustInletStart') ??
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .millisecondsSinceEpoch,
      );
      dustInletEnd = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('dustInletEnd') ?? DateTime.now().millisecondsSinceEpoch,
      );
      fanVibrationStart = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('fanVibrationStart') ??
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .millisecondsSinceEpoch,
      );
      fanVibrationEnd = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('fanVibrationEnd') ??
            DateTime.now().millisecondsSinceEpoch,
      );

      // 加载数据查询页面状态
      fanEnergyStatType = _prefs.getString('fanEnergyStatType') ?? '日';
      selectedMonth = _prefs.getInt('selectedMonth') ?? DateTime.now().month;
      selectedYear = _prefs.getInt('selectedYear') ?? DateTime.now().year;
      coolingWaterQueryStart = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('coolingWaterQueryStart') ??
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .millisecondsSinceEpoch,
      );
      coolingWaterQueryEnd = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('coolingWaterQueryEnd') ??
            DateTime.now().millisecondsSinceEpoch,
      );
      pm10QueryStart = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('pm10QueryStart') ??
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .millisecondsSinceEpoch,
      );
      pm10QueryEnd = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('pm10QueryEnd') ?? DateTime.now().millisecondsSinceEpoch,
      );
      valveQueryStart = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('valveQueryStart') ??
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .millisecondsSinceEpoch,
      );
      valveQueryEnd = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('valveQueryEnd') ?? DateTime.now().millisecondsSinceEpoch,
      );
      fanEnergyQueryStart = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('fanEnergyQueryStart') ??
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .millisecondsSinceEpoch,
      );
      fanEnergyQueryEnd = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('fanEnergyQueryEnd') ??
            DateTime.now().millisecondsSinceEpoch,
      );

      // 加载报警记录页面状态
      furnaceSkinStart = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('furnaceSkinStart') ??
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .millisecondsSinceEpoch,
      );
      furnaceSkinEnd = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('furnaceSkinEnd') ??
            DateTime.now().millisecondsSinceEpoch,
      );
      coolingWaterStart = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('coolingWaterStart') ??
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .millisecondsSinceEpoch,
      );
      coolingWaterEnd = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('coolingWaterEnd') ??
            DateTime.now().millisecondsSinceEpoch,
      );
      preFilterAlarmStart = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('preFilterAlarmStart') ??
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .millisecondsSinceEpoch,
      );
      preFilterAlarmEnd = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('preFilterAlarmEnd') ??
            DateTime.now().millisecondsSinceEpoch,
      );
      dustInletAlarmStart = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('dustInletAlarmStart') ??
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .millisecondsSinceEpoch,
      );
      dustInletAlarmEnd = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('dustInletAlarmEnd') ??
            DateTime.now().millisecondsSinceEpoch,
      );
      pm10AlarmStart = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('pm10AlarmStart') ??
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .millisecondsSinceEpoch,
      );
      pm10AlarmEnd = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('pm10AlarmEnd') ?? DateTime.now().millisecondsSinceEpoch,
      );
      fanVibrationAlarmStart = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('fanVibrationAlarmStart') ??
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .millisecondsSinceEpoch,
      );
      fanVibrationAlarmEnd = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('fanVibrationAlarmEnd') ??
            DateTime.now().millisecondsSinceEpoch,
      );

      // 加载系统配置页面状态
      systemConfigTabIndex = _prefs.getInt('systemConfigTabIndex') ?? 0;
    } catch (e) {
      debugPrint('加载状态失败: $e');
    }
  }

  /// 保存数据大屏状态
  Future<void> saveDataScreenState() async {
    await _prefs.setBool('fanRunning', fanRunning);
    await _prefs.setBool('vibrationFault', vibrationFault);
    await _prefs.setString(
        'valves', jsonEncode(valves.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  /// 更新蝶阀状态
  Future<void> updateValveState(String valveId, ValveStatus status,
      {double? openingDegree}) async {
    final index = valves.indexWhere((v) => v.id == valveId);
    if (index != -1) {
      valves[index] = ValveState(
        id: valves[index].id,
        name: valves[index].name,
        status: status,
        openingDegree: openingDegree ??
            (status == ValveStatus.open ? valves[index].openingDegree : 0),
      );
      await saveDataScreenState();
    }
  }

  /// 保存历史曲线页面状态
  Future<void> saveHistoryCurveState() async {
    await _prefs.setInt(
        'furnaceEnergyStart', furnaceEnergyStart.millisecondsSinceEpoch);
    await _prefs.setInt(
        'furnaceEnergyEnd', furnaceEnergyEnd.millisecondsSinceEpoch);
    await _prefs.setInt(
        'furnaceTempStart', furnaceTempStart.millisecondsSinceEpoch);
    await _prefs.setInt(
        'furnaceTempEnd', furnaceTempEnd.millisecondsSinceEpoch);
    await _prefs.setInt(
        'preFilterStart', preFilterStart.millisecondsSinceEpoch);
    await _prefs.setInt('preFilterEnd', preFilterEnd.millisecondsSinceEpoch);
    await _prefs.setInt(
        'dustInletStart', dustInletStart.millisecondsSinceEpoch);
    await _prefs.setInt('dustInletEnd', dustInletEnd.millisecondsSinceEpoch);
    await _prefs.setInt(
        'fanVibrationStart', fanVibrationStart.millisecondsSinceEpoch);
    await _prefs.setInt(
        'fanVibrationEnd', fanVibrationEnd.millisecondsSinceEpoch);
    notifyListeners();
  }

  /// 保存数据查询页面状态
  Future<void> saveDataQueryState() async {
    await _prefs.setString('fanEnergyStatType', fanEnergyStatType);
    await _prefs.setInt('selectedMonth', selectedMonth);
    await _prefs.setInt('selectedYear', selectedYear);
    await _prefs.setInt('coolingWaterQueryStart',
        coolingWaterQueryStart.millisecondsSinceEpoch);
    await _prefs.setInt(
        'coolingWaterQueryEnd', coolingWaterQueryEnd.millisecondsSinceEpoch);
    await _prefs.setInt(
        'pm10QueryStart', pm10QueryStart.millisecondsSinceEpoch);
    await _prefs.setInt('pm10QueryEnd', pm10QueryEnd.millisecondsSinceEpoch);
    await _prefs.setInt(
        'valveQueryStart', valveQueryStart.millisecondsSinceEpoch);
    await _prefs.setInt('valveQueryEnd', valveQueryEnd.millisecondsSinceEpoch);
    await _prefs.setInt(
        'fanEnergyQueryStart', fanEnergyQueryStart.millisecondsSinceEpoch);
    await _prefs.setInt(
        'fanEnergyQueryEnd', fanEnergyQueryEnd.millisecondsSinceEpoch);
    notifyListeners();
  }

  /// 保存报警记录页面状态
  Future<void> saveAlarmRecordState() async {
    await _prefs.setInt(
        'furnaceSkinStart', furnaceSkinStart.millisecondsSinceEpoch);
    await _prefs.setInt(
        'furnaceSkinEnd', furnaceSkinEnd.millisecondsSinceEpoch);
    await _prefs.setInt(
        'coolingWaterStart', coolingWaterStart.millisecondsSinceEpoch);
    await _prefs.setInt(
        'coolingWaterEnd', coolingWaterEnd.millisecondsSinceEpoch);
    await _prefs.setInt(
        'preFilterAlarmStart', preFilterAlarmStart.millisecondsSinceEpoch);
    await _prefs.setInt(
        'preFilterAlarmEnd', preFilterAlarmEnd.millisecondsSinceEpoch);
    await _prefs.setInt(
        'dustInletAlarmStart', dustInletAlarmStart.millisecondsSinceEpoch);
    await _prefs.setInt(
        'dustInletAlarmEnd', dustInletAlarmEnd.millisecondsSinceEpoch);
    await _prefs.setInt(
        'pm10AlarmStart', pm10AlarmStart.millisecondsSinceEpoch);
    await _prefs.setInt('pm10AlarmEnd', pm10AlarmEnd.millisecondsSinceEpoch);
    await _prefs.setInt('fanVibrationAlarmStart',
        fanVibrationAlarmStart.millisecondsSinceEpoch);
    await _prefs.setInt(
        'fanVibrationAlarmEnd', fanVibrationAlarmEnd.millisecondsSinceEpoch);
    notifyListeners();
  }

  /// 保存系统配置页面状态
  Future<void> saveSystemConfigState() async {
    await _prefs.setInt('systemConfigTabIndex', systemConfigTabIndex);
    notifyListeners();
  }

  /// 更新系统就绪状态 (后端+PLC都正常时为 true)
  void updateSystemReady(bool ready) {
    if (isSystemReady != ready) {
      isSystemReady = ready;
      notifyListeners();
    }
  }

  /// 刷新所有实时数据
  /// 从后端 API 获取最新数据
  Future<void> refreshAllData() async {
    try {
      // TODO: 当后端 API 实现后，这里调用 API 获取最新数据
      // final apiClient = ApiClient();
      // final data = await apiClient.getRealtimeBatch();
      // 更新各项数据...

      // 模拟网络延迟
      await Future.delayed(const Duration(milliseconds: 500));

      // 刷新成功后通知监听器
      notifyListeners();
      debugPrint('数据刷新成功');
    } catch (e) {
      debugPrint('数据刷新失败: $e');
      rethrow;
    }
  }
}

/// 蝶阀状态枚举
enum ValveStatus {
  open, // 开启
  closed, // 关闭
  stopped, // 停止
}

/// 蝶阀状态类
class ValveState {
  final String id;
  final String name;
  final ValveStatus status;
  final double openingDegree; // 开度百分比 (0-100)

  ValveState({
    required this.id,
    required this.name,
    required this.status,
    this.openingDegree = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status.index,
        'openingDegree': openingDegree,
      };

  factory ValveState.fromJson(Map<String, dynamic> json) {
    // 兼容旧数据格式（使用 isOpen 布尔值）
    ValveStatus status;
    if (json.containsKey('status') && json['status'] != null) {
      status = ValveStatus.values[json['status']];
    } else if (json.containsKey('isOpen')) {
      // 旧数据格式：将 isOpen 转换为新的 status
      status = json['isOpen'] == true ? ValveStatus.open : ValveStatus.closed;
    } else {
      status = ValveStatus.closed; // 默认值
    }

    return ValveState(
      id: json['id'],
      name: json['name'],
      status: status,
      openingDegree: (json['openingDegree'] ?? 75.0).toDouble(),
    );
  }
}
