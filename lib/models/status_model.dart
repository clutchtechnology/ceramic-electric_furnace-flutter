/// 设备状态数据模型 (DB30 / DB41)
///
/// DB30: Modbus 通信状态 (Done/Busy/Error/Status)
/// DB41: 传感器数据状态 (Error/Status)

// ============================================================
// DB30 设备状态 (Modbus 通信状态)
// ============================================================

class Db30DeviceStatus {
  final String deviceId;
  final String deviceName;
  final String plcName;
  final bool done;
  final bool busy;
  final bool error;
  final int status;
  final String statusHex;
  final bool healthy;
  final String? dataDeviceId;
  final String? description;

  Db30DeviceStatus({
    required this.deviceId,
    required this.deviceName,
    required this.plcName,
    required this.done,
    required this.busy,
    required this.error,
    required this.status,
    required this.statusHex,
    required this.healthy,
    this.dataDeviceId,
    this.description,
  });

  factory Db30DeviceStatus.fromJson(Map<String, dynamic> json) {
    return Db30DeviceStatus(
      deviceId: json['device_id'] ?? '',
      deviceName: json['device_name'] ?? '',
      plcName: json['plc_name'] ?? '',
      done: json['done'] ?? false,
      busy: json['busy'] ?? false,
      error: json['error'] ?? false,
      status: json['status'] ?? 0,
      statusHex: json['status_hex'] ?? '0x0000',
      healthy: json['healthy'] ?? false,
      dataDeviceId: json['data_device_id'],
      description: json['description'],
    );
  }

  /// 是否正常 (同 healthy)
  bool get isNormal => healthy;

  /// 状态文本
  String get statusText {
    if (error) return '错误';
    if (busy) return '忙碌';
    if (done) return '完成';
    return '未知';
  }
}

// ============================================================
// DB41 设备状态 (数据采集状态)
// ============================================================

class Db41DeviceStatus {
  final String deviceId;
  final String deviceName;
  final String plcName;
  final bool error;
  final int status;
  final String statusHex;
  final bool healthy;
  final String? dataDeviceId;
  final String? description;

  Db41DeviceStatus({
    required this.deviceId,
    required this.deviceName,
    required this.plcName,
    required this.error,
    required this.status,
    required this.statusHex,
    required this.healthy,
    this.dataDeviceId,
    this.description,
  });

  factory Db41DeviceStatus.fromJson(Map<String, dynamic> json) {
    return Db41DeviceStatus(
      deviceId: json['device_id'] ?? '',
      deviceName: json['device_name'] ?? '',
      plcName: json['plc_name'] ?? '',
      error: json['error'] ?? false,
      status: json['status'] ?? 0,
      statusHex: json['status_hex'] ?? '0x0000',
      healthy: json['healthy'] ?? false,
      dataDeviceId: json['data_device_id'],
      description: json['description'],
    );
  }

  /// 是否正常 (同 healthy)
  bool get isNormal => healthy;

  /// 状态文本
  String get statusText {
    if (error) return '错误';
    return '正常';
  }
}

// ============================================================
// 状态摘要
// ============================================================

class StatusSummary {
  final int total;
  final int healthy;
  final int error;

  StatusSummary({
    required this.total,
    required this.healthy,
    required this.error,
  });

  factory StatusSummary.fromJson(Map<String, dynamic> json) {
    return StatusSummary(
      total: json['total'] ?? 0,
      healthy: json['healthy'] ?? 0,
      error: json['error'] ?? 0,
    );
  }

  factory StatusSummary.empty() {
    return StatusSummary(total: 0, healthy: 0, error: 0);
  }
}

// ============================================================
// DB30 状态响应
// ============================================================

class Db30StatusResponse {
  final bool success;
  final List<Db30DeviceStatus> devices;
  final StatusSummary summary;
  final String? timestamp;
  final String? message;

  Db30StatusResponse({
    required this.success,
    required this.devices,
    required this.summary,
    this.timestamp,
    this.message,
  });

  factory Db30StatusResponse.fromJson(Map<String, dynamic> json) {
    final devicesList = (json['devices'] as List<dynamic>? ?? [])
        .map((d) => Db30DeviceStatus.fromJson(d as Map<String, dynamic>))
        .toList();

    return Db30StatusResponse(
      success: json['success'] ?? false,
      devices: devicesList,
      summary: json['summary'] != null
          ? StatusSummary.fromJson(json['summary'])
          : StatusSummary.empty(),
      timestamp: json['timestamp'],
      message: json['message'],
    );
  }

  factory Db30StatusResponse.error(String errorMessage) {
    return Db30StatusResponse(
      success: false,
      devices: [],
      summary: StatusSummary.empty(),
      message: errorMessage,
    );
  }
}

// ============================================================
// DB41 状态响应
// ============================================================

class Db41StatusResponse {
  final bool success;
  final List<Db41DeviceStatus> devices;
  final StatusSummary summary;
  final String? timestamp;
  final String? message;

  Db41StatusResponse({
    required this.success,
    required this.devices,
    required this.summary,
    this.timestamp,
    this.message,
  });

  factory Db41StatusResponse.fromJson(Map<String, dynamic> json) {
    final devicesList = (json['devices'] as List<dynamic>? ?? [])
        .map((d) => Db41DeviceStatus.fromJson(d as Map<String, dynamic>))
        .toList();

    return Db41StatusResponse(
      success: json['success'] ?? false,
      devices: devicesList,
      summary: json['summary'] != null
          ? StatusSummary.fromJson(json['summary'])
          : StatusSummary.empty(),
      timestamp: json['timestamp'],
      message: json['message'],
    );
  }

  factory Db41StatusResponse.error(String errorMessage) {
    return Db41StatusResponse(
      success: false,
      devices: [],
      summary: StatusSummary.empty(),
      message: errorMessage,
    );
  }
}
