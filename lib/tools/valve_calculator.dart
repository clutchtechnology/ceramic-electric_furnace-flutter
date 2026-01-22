/// 蝶阀开合度增量计算工具
///
/// 功能：
/// 1. 每5秒增量计算开合度（而不是统计窗口）
/// 2. 支持请求失败补偿（记录失败次数，下次成功时补偿）
/// 3. 状态逻辑：
///    - "01"（开）→ 开合度 +16.67%
///    - "10"（关）→ 开合度 -16.67%
///    - "00"（停）→ 开合度不变
///    - "11"（错误）→ 开合度不变

class ValveCalculator {
  /// 轮询间隔（秒）
  static const int pollingInterval = 5;

  /// 完全开启/关闭所需时间（秒）
  static const int fullActionTime = 30;

  /// 每次状态变化的百分比增量
  /// 30秒 = 100%，每5秒 = 100/6 ≈ 16.67%
  static const double percentagePerPoll =
      100.0 / (fullActionTime / pollingInterval);

  /// 每个蝶阀的当前开合度
  static final Map<int, double> _currentPercentages = {
    1: 0.0,
    2: 0.0,
    3: 0.0,
    4: 0.0,
  };

  /// 每个蝶阀的失败计数（记录请求失败次数）
  static final Map<int, int> _failedCounts = {
    1: 0,
    2: 0,
    3: 0,
    4: 0,
  };

  /// 每个蝶阀的上一次状态（用于失败补偿时推断）
  static final Map<int, String> _lastKnownStatus = {
    1: "00",
    2: "00",
    3: "00",
    4: "00",
  };

  /// 根据当前状态增量更新开合度
  ///
  /// Args:
  ///   valveId: 蝶阀编号 (1-4)
  ///   currentStatus: 当前状态 ("00", "01", "10", "11")
  ///
  /// Returns:
  ///   更新后的开合度百分比 (0-100)
  ///
  /// 逻辑：
  ///   - "01"（开）→ 开合度 +16.67%
  ///   - "10"（关）→ 开合度 -16.67%
  ///   - "00"（停）→ 不变
  ///   - "11"（错误）→ 不变
  static double updateOpenPercentage(int valveId, String currentStatus) {
    if (valveId < 1 || valveId > 4) {
      return 0.0;
    }

    double currentPercentage = _currentPercentages[valveId] ?? 0.0;

    // 首先处理失败补偿
    int failedCount = _failedCounts[valveId] ?? 0;
    if (failedCount > 0) {
      // 使用上一次已知状态进行补偿计算
      String lastStatus = _lastKnownStatus[valveId] ?? "00";
      currentPercentage =
          _applyStatusChange(currentPercentage, lastStatus, failedCount);
      _failedCounts[valveId] = 0; // 清除失败计数
    }

    // 然后处理当前状态
    currentPercentage = _applyStatusChange(currentPercentage, currentStatus, 1);

    // 保存当前状态作为下一次的"上一次状态"
    _lastKnownStatus[valveId] = currentStatus;

    // 保存更新后的百分比
    _currentPercentages[valveId] = currentPercentage;

    return currentPercentage;
  }

  /// 应用状态变化到百分比
  static double _applyStatusChange(
      double percentage, String status, int times) {
    switch (status) {
      case "01": // 开启中
        percentage += percentagePerPoll * times;
        break;
      case "10": // 关闭中
        percentage -= percentagePerPoll * times;
        break;
      case "00": // 停止
      case "11": // 错误
      default:
        // 不变
        break;
    }

    // 限制在 0-100 范围内
    return percentage.clamp(0.0, 100.0);
  }

  /// 记录请求失败（下次成功时会补偿）
  ///
  /// Args:
  ///   valveId: 蝶阀编号 (1-4)，如果为null则记录所有蝶阀
  static void recordFailure({int? valveId}) {
    if (valveId != null) {
      _failedCounts[valveId] = (_failedCounts[valveId] ?? 0) + 1;
    } else {
      // 记录所有蝶阀的失败
      for (int i = 1; i <= 4; i++) {
        _failedCounts[i] = (_failedCounts[i] ?? 0) + 1;
      }
    }
  }

  /// 获取当前开合度（不更新）
  static double getOpenPercentage(int valveId) {
    return _currentPercentages[valveId] ?? 0.0;
  }

  /// 获取失败计数
  static int getFailedCount(int valveId) {
    return _failedCounts[valveId] ?? 0;
  }

  /// 重置指定蝶阀的状态
  static void resetValve(int valveId, {double initialPercentage = 0.0}) {
    _currentPercentages[valveId] = initialPercentage;
    _failedCounts[valveId] = 0;
    _lastKnownStatus[valveId] = "00";
  }

  /// 重置所有蝶阀状态
  static void resetAll({double initialPercentage = 0.0}) {
    for (int i = 1; i <= 4; i++) {
      resetValve(i, initialPercentage: initialPercentage);
    }
  }

  /// 批量更新所有蝶阀开合度
  ///
  /// Args:
  ///   statuses: 状态映射 {1: "01", 2: "10", 3: "00", 4: "01"}
  ///
  /// Returns:
  ///   更新后的开合度映射 {1: 16.67, 2: 0.0, 3: 0.0, 4: 16.67}
  static Map<int, double> batchUpdateOpenPercentages(
      Map<int, String> statuses) {
    Map<int, double> result = {};
    for (int i = 1; i <= 4; i++) {
      String status = statuses[i] ?? "00";
      result[i] = updateOpenPercentage(i, status);
    }
    return result;
  }

  /// 获取蝶阀状态名称
  ///
  /// Args:
  ///   status: 状态码 ("00", "01", "10", "11")
  ///
  /// Returns:
  ///   状态名称（中文）
  static String getStatusName(String status) {
    switch (status) {
      case "00":
        return "停止";
      case "01":
        return "开启中";
      case "10":
        return "关闭中";
      case "11":
        return "故障";
      default:
        return "未知";
    }
  }

  /// 获取蝶阀状态颜色
  ///
  /// Args:
  ///   status: 状态码 ("00", "01", "10", "11")
  ///
  /// Returns:
  ///   状态对应的颜色代码
  static int getStatusColor(String status) {
    switch (status) {
      case "00":
        return 0xFF484f58; // 灰色（停止）
      case "01":
        return 0xFF00ff88; // 绿色（开启中）
      case "10":
        return 0xFFff3b30; // 红色（关闭中）
      case "11":
        return 0xFFffcc00; // 黄色（故障）
      default:
        return 0xFF8b949e; // 浅灰色（未知）
    }
  }

  /// 判断状态是否为活动状态（正在开/关）
  static bool isActiveStatus(String status) {
    return status == "01" || status == "10";
  }

  /// 判断状态是否正常
  static bool isNormalStatus(String status) {
    return status != "11";
  }

  /// 获取调试信息
  static String getDebugInfo() {
    StringBuffer sb = StringBuffer();
    sb.writeln('=== ValveCalculator Debug Info ===');
    for (int i = 1; i <= 4; i++) {
      sb.writeln('Valve $i: ${_currentPercentages[i]?.toStringAsFixed(2)}% '
          '| LastStatus: ${_lastKnownStatus[i]} '
          '| FailedCount: ${_failedCounts[i]}');
    }
    return sb.toString();
  }
}
