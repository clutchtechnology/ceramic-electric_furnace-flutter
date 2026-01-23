// ============================================================
// 文件说明: batch_api.dart - 批次管理 API 调用
// ============================================================
// 功能:
//   1. 开始冶炼 (start)
//   2. 暂停冶炼 (pause)
//   3. 恢复冶炼 (resume)
//   4. 停止冶炼 (stop)
//   5. 获取状态 (status) - 用于断电恢复
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

/// 批次管理 API
class BatchApi {
  // 使用 Api.baseUrl 而非 ApiConfig.baseUrl，避免 /api 重复
  static const String _baseUrl = Api.baseUrl;
  static const Duration _timeout = Duration(seconds: 10);

  /// 开始冶炼
  ///
  /// [batchCode] 批次编号，格式: 03-2026-01-15
  /// 返回: {"success": bool, "message": str, "batch_code": str}
  static Future<BatchResponse> startSmelting(String batchCode) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/batch/start'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'batch_code': batchCode}),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return BatchResponse(
          success: data['success'] ?? true,
          message: data['message'] ?? '冶炼开始成功',
          batchCode: data['batch_code'],
        );
      } else {
        return BatchResponse(
          success: false,
          message: data['detail'] ?? '启动失败: ${response.statusCode}',
          batchCode: null,
        );
      }
    } catch (e) {
      return BatchResponse(
        success: false,
        message: '网络错误: $e',
        batchCode: null,
      );
    }
  }

  /// 暂停冶炼 (保留批次号)
  static Future<BatchResponse> pauseSmelting() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/batch/pause'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return BatchResponse(
          success: data['success'] ?? true,
          message: data['message'] ?? '冶炼已暂停',
          batchCode: data['batch_code'],
        );
      } else {
        return BatchResponse(
          success: false,
          message: data['detail'] ?? '暂停失败: ${response.statusCode}',
          batchCode: null,
        );
      }
    } catch (e) {
      return BatchResponse(
        success: false,
        message: '网络错误: $e',
        batchCode: null,
      );
    }
  }

  /// 恢复冶炼 (从暂停状态恢复)
  static Future<BatchResponse> resumeSmelting() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/batch/resume'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return BatchResponse(
          success: data['success'] ?? true,
          message: data['message'] ?? '冶炼已恢复',
          batchCode: data['batch_code'],
        );
      } else {
        return BatchResponse(
          success: false,
          message: data['detail'] ?? '恢复失败: ${response.statusCode}',
          batchCode: null,
        );
      }
    } catch (e) {
      return BatchResponse(
        success: false,
        message: '网络错误: $e',
        batchCode: null,
      );
    }
  }

  /// 停止冶炼 (结束批次)
  static Future<BatchResponse> stopSmelting() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/batch/stop'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return BatchResponse(
          success: data['success'] ?? true,
          message: data['message'] ?? '冶炼已停止',
          batchCode: null,
        );
      } else {
        return BatchResponse(
          success: false,
          message: data['detail'] ?? '停止失败: ${response.statusCode}',
          batchCode: null,
        );
      }
    } catch (e) {
      return BatchResponse(
        success: false,
        message: '网络错误: $e',
        batchCode: null,
      );
    }
  }

  /// 获取当前冶炼状态 (用于断电恢复)
  ///
  /// 返回完整状态信息，前端启动时应调用此接口检查是否有未完成的批次
  static Future<BatchStatus> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/batch/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BatchStatus.fromJson(data);
      } else {
        return BatchStatus.empty();
      }
    } catch (e) {
      print('[BatchApi] 获取状态失败: $e');
      return BatchStatus.empty();
    }
  }

  /// 获取最新批次序号
  ///
  /// [furnaceNumber] 炉号，默认 "03"
  /// [year] 年份，默认当前年
  /// [month] 月份，默认当前月
  ///
  /// 返回: 最新序号信息，用于自动填充批次号输入框
  static Future<LatestSequenceResponse> getLatestSequence({
    String furnaceNumber = "03",
    int? year,
    int? month,
  }) async {
    try {
      final now = DateTime.now();
      final params = {
        'furnace_number': furnaceNumber,
        'year': (year ?? now.year).toString(),
        'month': (month ?? now.month).toString(),
      };

      final uri = Uri.parse('$_baseUrl/api/batch/latest-sequence')
          .replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LatestSequenceResponse.fromJson(data);
      } else {
        return LatestSequenceResponse.empty();
      }
    } catch (e) {
      print('[BatchApi] 获取最新序号失败: $e');
      return LatestSequenceResponse.empty();
    }
  }
}

/// 批次操作响应
class BatchResponse {
  final bool success;
  final String message;
  final String? batchCode;

  BatchResponse({
    required this.success,
    required this.message,
    this.batchCode,
  });
}

/// 批次状态 (用于断电恢复)
class BatchStatus {
  final String state; // idle, running, paused, stopped
  final bool isSmelting; // 是否有活跃批次
  final bool isRunning; // 是否正在写数据库
  final String? batchCode; // 批次编号
  final String? startTime; // 开始时间
  final String? pauseTime; // 暂停时间
  final double elapsedSeconds; // 有效运行时长
  final double totalPauseDuration; // 累计暂停时长

  BatchStatus({
    required this.state,
    required this.isSmelting,
    required this.isRunning,
    this.batchCode,
    this.startTime,
    this.pauseTime,
    required this.elapsedSeconds,
    required this.totalPauseDuration,
  });

  factory BatchStatus.fromJson(Map<String, dynamic> json) {
    return BatchStatus(
      state: json['state'] ?? 'idle',
      isSmelting: json['is_smelting'] ?? false,
      isRunning: json['is_running'] ?? false,
      batchCode: json['batch_code'],
      startTime: json['start_time'],
      pauseTime: json['pause_time'],
      elapsedSeconds: (json['elapsed_seconds'] ?? 0).toDouble(),
      totalPauseDuration: (json['total_pause_duration'] ?? 0).toDouble(),
    );
  }

  factory BatchStatus.empty() {
    return BatchStatus(
      state: 'idle',
      isSmelting: false,
      isRunning: false,
      batchCode: null,
      startTime: null,
      pauseTime: null,
      elapsedSeconds: 0,
      totalPauseDuration: 0,
    );
  }

  /// 是否需要恢复 (断电恢复检测)
  bool get needsRecovery => isSmelting && state == 'paused';

  /// 格式化运行时长
  String get formattedElapsedTime {
    final hours = (elapsedSeconds / 3600).floor();
    final minutes = ((elapsedSeconds % 3600) / 60).floor();
    final seconds = (elapsedSeconds % 60).floor();
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// 最新批次序号响应
class LatestSequenceResponse {
  final bool success;
  final String furnaceNumber;
  final int year;
  final int month;
  final int latestSequence; // 数据库中最新序号，无记录则为 0
  final int nextSequence; // 建议的下一个序号
  final String? latestBatchCode; // 最新批次号完整值

  LatestSequenceResponse({
    required this.success,
    required this.furnaceNumber,
    required this.year,
    required this.month,
    required this.latestSequence,
    required this.nextSequence,
    this.latestBatchCode,
  });

  factory LatestSequenceResponse.fromJson(Map<String, dynamic> json) {
    return LatestSequenceResponse(
      success: json['success'] ?? false,
      furnaceNumber: json['furnace_number'] ?? '03',
      year: json['year'] ?? DateTime.now().year,
      month: json['month'] ?? DateTime.now().month,
      latestSequence: json['latest_sequence'] ?? 0,
      nextSequence: json['next_sequence'] ?? 1,
      latestBatchCode: json['latest_batch_code'],
    );
  }

  factory LatestSequenceResponse.empty() {
    final now = DateTime.now();
    return LatestSequenceResponse(
      success: false,
      furnaceNumber: '03',
      year: now.year,
      month: now.month,
      latestSequence: 0,
      nextSequence: 1,
      latestBatchCode: null,
    );
  }
}
