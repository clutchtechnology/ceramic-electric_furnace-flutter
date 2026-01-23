// ============================================================
// 控制 API - 轮询启动/停止
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

/// 启动轮询请求
class StartPollingRequest {
  final String batchCode;

  StartPollingRequest({required this.batchCode});

  Map<String, dynamic> toJson() => {'batch_code': batchCode};
}

/// 启动轮询响应
class StartPollingResponse {
  final String status;
  final String message;
  final String batchCode;
  final String startTime;

  StartPollingResponse({
    required this.status,
    required this.message,
    required this.batchCode,
    required this.startTime,
  });

  factory StartPollingResponse.fromJson(Map<String, dynamic> json) {
    return StartPollingResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      batchCode: json['batch_code'] ?? '',
      startTime: json['start_time'] ?? '',
    );
  }
}

/// 停止轮询响应
class StopPollingResponse {
  final String status;
  final String message;
  final String? batchCode;
  final String? startTime;
  final String? stopTime;
  final double? durationSeconds;

  StopPollingResponse({
    required this.status,
    required this.message,
    this.batchCode,
    this.startTime,
    this.stopTime,
    this.durationSeconds,
  });

  factory StopPollingResponse.fromJson(Map<String, dynamic> json) {
    return StopPollingResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      batchCode: json['batch_code'],
      startTime: json['start_time'],
      stopTime: json['stop_time'],
      durationSeconds: json['duration_seconds']?.toDouble(),
    );
  }
}

/// 轮询状态响应
class PollingStatusResponse {
  final bool isRunning;
  final String? batchCode;
  final String? startTime;
  final String currentTime;
  final double? durationSeconds;
  final Map<String, dynamic> statistics;

  PollingStatusResponse({
    required this.isRunning,
    this.batchCode,
    this.startTime,
    required this.currentTime,
    this.durationSeconds,
    required this.statistics,
  });

  factory PollingStatusResponse.fromJson(Map<String, dynamic> json) {
    return PollingStatusResponse(
      isRunning: json['is_running'] ?? false,
      batchCode: json['batch_code'],
      startTime: json['start_time'],
      currentTime: json['current_time'] ?? '',
      durationSeconds: json['duration_seconds']?.toDouble(),
      statistics: json['statistics'] ?? {},
    );
  }
}

/// 控制 API 服务
class ControlApi {
  /// 启动轮询服务
  static Future<StartPollingResponse> startPolling(String batchCode) async {
    try {
      final request = StartPollingRequest(batchCode: batchCode);
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/control/start'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StartPollingResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? '启动轮询失败');
      }
    } catch (e) {
      throw Exception('启动轮询异常: $e');
    }
  }

  /// 停止轮询服务
  static Future<StopPollingResponse> stopPolling() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/control/stop'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StopPollingResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? '停止轮询失败');
      }
    } catch (e) {
      throw Exception('停止轮询异常: $e');
    }
  }

  /// 查询轮询状态
  static Future<PollingStatusResponse> getStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/control/status'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PollingStatusResponse.fromJson(data);
      } else {
        throw Exception('查询状态失败');
      }
    } catch (e) {
      throw Exception('查询状态异常: $e');
    }
  }

  /// 生成批次号 (格式: FF + YY + MM + DD，无分隔符)
  ///
  /// - FF: 炉号 (01-99)
  /// - YY: 年份后两位 (26 = 2026)
  /// - MM: 月份 (01-12)
  /// - DD: 日期 (01-31)
  ///
  /// 示例: 03260123 = 3号炉 + 2026年1月23日
  static String generateBatchCode({int furnaceNumber = 3}) {
    final now = DateTime.now();
    final furnace = furnaceNumber.toString().padLeft(2, '0');
    final year = (now.year % 100).toString().padLeft(2, '0'); // 只取后两位
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '$furnace$year$month$day';
  }
}
