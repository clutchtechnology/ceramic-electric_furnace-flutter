/// 蝶阀状态数据模型
/// 注意：使用 ValveStatusData 避免与 app_state.dart 中的 ValveStatus enum 冲突

class ValveStatusData {
  final String status; // "00", "01", "10", "11"
  final String timestamp; // ISO 8601 格式
  final String stateName; // "closed", "open", "error", "unknown"

  ValveStatusData({
    required this.status,
    required this.timestamp,
    required this.stateName,
  });

  factory ValveStatusData.fromJson(Map<String, dynamic> json) {
    return ValveStatusData(
      status: json['status'] as String? ?? '00',
      timestamp: json['timestamp'] as String? ?? '',
      stateName: json['state_name'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp,
      'state_name': stateName,
    };
  }
}

class ValveStatusQueues {
  final Map<int, List<ValveStatusData>>
      queues; // {1: [...], 2: [...], 3: [...], 4: [...]}
  final String timestamp;
  final Map<int, int> queueLength;

  ValveStatusQueues({
    required this.queues,
    required this.timestamp,
    required this.queueLength,
  });

  factory ValveStatusQueues.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    Map<int, List<ValveStatusData>> queues = {};

    // 解析4个蝶阀的队列
    for (int i = 1; i <= 4; i++) {
      String key = i.toString();
      if (data.containsKey(key)) {
        List<dynamic> queueData = data[key] as List<dynamic>;
        queues[i] = queueData
            .map((item) =>
                ValveStatusData.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        queues[i] = [];
      }
    }

    // 解析队列长度
    Map<int, int> queueLength = {};
    final lengthData = json['queue_length'] as Map<String, dynamic>? ?? {};
    for (int i = 1; i <= 4; i++) {
      String key = i.toString();
      queueLength[i] = lengthData[key] as int? ?? 0;
    }

    return ValveStatusQueues(
      queues: queues,
      timestamp: json['timestamp'] as String? ?? '',
      queueLength: queueLength,
    );
  }

  /// 获取指定蝶阀的状态队列
  List<String> getStatusQueue(int valveId) {
    return queues[valveId]?.map((v) => v.status).toList() ?? [];
  }

  /// 获取指定蝶阀的最新状态
  String? getLatestStatus(int valveId) {
    final queue = queues[valveId];
    if (queue == null || queue.isEmpty) {
      return null;
    }
    return queue.last.status;
  }
}

class LatestValveStatus {
  final Map<int, ValveStatusData>
      valves; // {1: ValveStatusData, 2: ..., 3: ..., 4: ...}
  final String timestamp;

  LatestValveStatus({
    required this.valves,
    required this.timestamp,
  });

  factory LatestValveStatus.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    Map<int, ValveStatusData> valves = {};

    for (int i = 1; i <= 4; i++) {
      String key = i.toString();
      if (data.containsKey(key)) {
        valves[i] = ValveStatusData.fromJson(data[key] as Map<String, dynamic>);
      }
    }

    return LatestValveStatus(
      valves: valves,
      timestamp: json['timestamp'] as String? ?? '',
    );
  }

  /// 获取指定蝶阀的最新状态码
  String? getStatus(int valveId) {
    return valves[valveId]?.status;
  }

  /// 获取指定蝶阀的完整状态对象
  ValveStatusData? getValveStatus(int valveId) {
    return valves[valveId];
  }
}
