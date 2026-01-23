/// 蝶阀状态 API 服务
///
/// [CRITICAL] HTTP Client 管理规范:
/// - 使用单例 HTTP Client，避免每次请求创建新连接
/// - 定期刷新防止僵尸连接 (10分钟)
/// - 连续失败3次强制刷新
/// - 所有请求必须设置超时 (10秒)
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/valve_status.dart';
import 'api.dart';

class ValveApi {
  // 单例模式
  static final ValveApi _instance = ValveApi._internal();
  factory ValveApi() => _instance;
  ValveApi._internal();

  // ===== HTTP Client 配置 (与 ApiClient 保持一致) =====
  static http.Client _httpClient = _createClient();
  static DateTime _lastRefresh = DateTime.now();
  static const Duration _refreshInterval = Duration(minutes: 10);
  static const Duration _timeout = Duration(seconds: 10);
  static const Duration _connectionTimeout = Duration(seconds: 5);
  static int _consecutiveFailures = 0;

  /// 创建带连接超时的 HTTP Client
  static http.Client _createClient() {
    final httpClient = HttpClient()
      ..connectionTimeout = _connectionTimeout
      ..idleTimeout = const Duration(seconds: 30);
    return IOClient(httpClient);
  }

  /// 获取 HTTP Client（自动刷新过期连接）
  static http.Client get _client {
    if (DateTime.now().difference(_lastRefresh) > _refreshInterval) {
      _httpClient.close();
      _httpClient = _createClient();
      _lastRefresh = DateTime.now();
      _consecutiveFailures = 0;
    } else if (_consecutiveFailures >= 3) {
      _httpClient.close();
      _httpClient = _createClient();
      _lastRefresh = DateTime.now();
      _consecutiveFailures = 0;
    }
    return _httpClient;
  }

  /// 记录请求成功
  static void _onSuccess() {
    _consecutiveFailures = 0;
  }

  /// 记录请求失败
  static void _onFailure() {
    _consecutiveFailures++;
  }

  /// 获取蝶阀状态队列（完整历史）
  ///
  /// Returns:
  ///   ValveStatusQueues 包含4个蝶阀的完整队列
  Future<ValveStatusQueues> getValveStatusQueues() async {
    try {
      final response = await _client
          .get(Uri.parse('${Api.baseUrl}/api/valve/status/queues'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        _onSuccess();
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ValveStatusQueues.fromJson(data);
      } else {
        _onFailure();
        throw Exception('获取蝶阀状态队列失败: ${response.statusCode}');
      }
    } on TimeoutException {
      _onFailure();
      throw Exception('获取蝶阀状态队列超时');
    } on SocketException catch (e) {
      _onFailure();
      throw Exception('网络连接错误: $e');
    } catch (e) {
      _onFailure();
      throw Exception('获取蝶阀状态队列失败: $e');
    }
  }

  /// 获取蝶阀最新状态
  ///
  /// Returns:
  ///   LatestValveStatus 包含4个蝶阀的最新状态
  Future<LatestValveStatus> getLatestValveStatus() async {
    try {
      final response = await _client
          .get(Uri.parse('${Api.baseUrl}/api/valve/status/latest'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        _onSuccess();
        final data = json.decode(response.body) as Map<String, dynamic>;
        return LatestValveStatus.fromJson(data);
      } else {
        _onFailure();
        throw Exception('获取最新蝶阀状态失败: ${response.statusCode}');
      }
    } on TimeoutException {
      _onFailure();
      throw Exception('获取蝶阀最新状态超时');
    } on SocketException catch (e) {
      _onFailure();
      throw Exception('网络连接错误: $e');
    } catch (e) {
      _onFailure();
      throw Exception('获取最新蝶阀状态失败: $e');
    }
  }

  /// 获取蝶阀状态统计
  ///
  /// Returns:
  ///   Map 包含4个蝶阀的统计信息
  Future<Map<String, dynamic>> getValveStatistics() async {
    try {
      final response = await _client
          .get(Uri.parse('${Api.baseUrl}/api/valve/status/statistics'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        _onSuccess();
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['data'] as Map<String, dynamic>;
      } else {
        _onFailure();
        throw Exception('获取蝶阀统计信息失败: ${response.statusCode}');
      }
    } on TimeoutException {
      _onFailure();
      throw Exception('获取蝶阀统计信息超时');
    } on SocketException catch (e) {
      _onFailure();
      throw Exception('网络连接错误: $e');
    } catch (e) {
      _onFailure();
      throw Exception('获取蝶阀统计信息失败: $e');
    }
  }

  // ============================================================
  // 蝶阀配置 API
  // ============================================================

  /// 获取蝶阀配置（全开/全关时间）
  ///
  /// Returns:
  ///   Map<String, ValveConfig> 包含4个蝶阀的配置
  Future<Map<String, ValveConfig>> getValveConfig() async {
    try {
      final response = await _client
          .get(Uri.parse('${Api.baseUrl}/api/valve/config'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        _onSuccess();
        final data = json.decode(response.body) as Map<String, dynamic>;
        final configData = data['data'] as Map<String, dynamic>;
        return configData.map((key, value) =>
            MapEntry(key, ValveConfig.fromJson(value as Map<String, dynamic>)));
      } else {
        _onFailure();
        throw Exception('获取蝶阀配置失败: ${response.statusCode}');
      }
    } on TimeoutException {
      _onFailure();
      throw Exception('获取蝶阀配置超时');
    } on SocketException catch (e) {
      _onFailure();
      throw Exception('网络连接错误: $e');
    } catch (e) {
      _onFailure();
      throw Exception('获取蝶阀配置失败: $e');
    }
  }

  /// 更新单个蝶阀配置
  ///
  /// Args:
  ///   valveId: 蝶阀编号 (1-4)
  ///   fullOpenTime: 全开时间(秒)
  ///   fullCloseTime: 全关时间(秒)
  Future<bool> updateValveConfig(
      int valveId, double? fullOpenTime, double? fullCloseTime) async {
    try {
      final body = <String, dynamic>{};
      if (fullOpenTime != null) body['full_open_time'] = fullOpenTime;
      if (fullCloseTime != null) body['full_close_time'] = fullCloseTime;

      final response = await _client
          .put(
            Uri.parse('${Api.baseUrl}/api/valve/config/$valveId'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        _onSuccess();
        return true;
      } else {
        _onFailure();
        throw Exception('更新蝶阀配置失败: ${response.statusCode}');
      }
    } on TimeoutException {
      _onFailure();
      throw Exception('更新蝶阀配置超时');
    } on SocketException catch (e) {
      _onFailure();
      throw Exception('网络连接错误: $e');
    } catch (e) {
      _onFailure();
      throw Exception('更新蝶阀配置失败: $e');
    }
  }

  /// 批量更新蝶阀配置
  ///
  /// Args:
  ///   configs: Map<int, ValveConfig> 蝶阀编号 -> 配置
  Future<bool> updateAllValveConfig(Map<int, ValveConfig> configs) async {
    try {
      final body = <String, dynamic>{};
      configs.forEach((valveId, config) {
        body['valve_$valveId'] = {
          'full_open_time': config.fullOpenTime,
          'full_close_time': config.fullCloseTime,
        };
      });

      final response = await _client
          .put(
            Uri.parse('${Api.baseUrl}/api/valve/config'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        _onSuccess();
        return true;
      } else {
        _onFailure();
        throw Exception('批量更新蝶阀配置失败: ${response.statusCode}');
      }
    } on TimeoutException {
      _onFailure();
      throw Exception('批量更新蝶阀配置超时');
    } on SocketException catch (e) {
      _onFailure();
      throw Exception('网络连接错误: $e');
    } catch (e) {
      _onFailure();
      throw Exception('批量更新蝶阀配置失败: $e');
    }
  }

  // ============================================================
  // 蝶阀开度 API
  // ============================================================

  /// 获取所有蝶阀开度
  ///
  /// Returns:
  ///   Map<String, ValveOpenness> 包含4个蝶阀的开度
  Future<Map<String, ValveOpenness>> getValveOpenness() async {
    try {
      final response = await _client
          .get(Uri.parse('${Api.baseUrl}/api/valve/openness'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        _onSuccess();
        final data = json.decode(response.body) as Map<String, dynamic>;
        final opennessData = data['data'] as Map<String, dynamic>;
        return opennessData.map((key, value) => MapEntry(
            key, ValveOpenness.fromJson(value as Map<String, dynamic>)));
      } else {
        _onFailure();
        throw Exception('获取蝶阀开度失败: ${response.statusCode}');
      }
    } on TimeoutException {
      _onFailure();
      throw Exception('获取蝶阀开度超时');
    } on SocketException catch (e) {
      _onFailure();
      throw Exception('网络连接错误: $e');
    } catch (e) {
      _onFailure();
      throw Exception('获取蝶阀开度失败: $e');
    }
  }

  /// 重置蝶阀开度
  ///
  /// Args:
  ///   valveId: 蝶阀编号 (1-4), null=全部重置
  ///   batchCode: 新批次号
  Future<bool> resetValveOpenness({int? valveId, String? batchCode}) async {
    try {
      final body = <String, dynamic>{};
      if (valveId != null) body['valve_id'] = valveId;
      if (batchCode != null) body['batch_code'] = batchCode;

      final response = await _client
          .post(
            Uri.parse('${Api.baseUrl}/api/valve/openness/reset'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        _onSuccess();
        return true;
      } else {
        _onFailure();
        throw Exception('重置蝶阀开度失败: ${response.statusCode}');
      }
    } on TimeoutException {
      _onFailure();
      throw Exception('重置蝶阀开度超时');
    } on SocketException catch (e) {
      _onFailure();
      throw Exception('网络连接错误: $e');
    } catch (e) {
      _onFailure();
      throw Exception('重置蝶阀开度失败: $e');
    }
  }

  /// 释放资源
  void dispose() {
    _httpClient.close();
  }
}

// ============================================================
// 数据模型
// ============================================================

/// 蝶阀配置
class ValveConfig {
  final int valveId;
  final double fullOpenTime;
  final double fullCloseTime;
  final String? updatedAt;

  ValveConfig({
    required this.valveId,
    required this.fullOpenTime,
    required this.fullCloseTime,
    this.updatedAt,
  });

  factory ValveConfig.fromJson(Map<String, dynamic> json) {
    return ValveConfig(
      valveId: json['valve_id'] as int? ?? 0,
      fullOpenTime: (json['full_open_time'] as num?)?.toDouble() ?? 30.0,
      fullCloseTime: (json['full_close_time'] as num?)?.toDouble() ?? 30.0,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'valve_id': valveId,
        'full_open_time': fullOpenTime,
        'full_close_time': fullCloseTime,
        'updated_at': updatedAt,
      };

  ValveConfig copyWith({
    int? valveId,
    double? fullOpenTime,
    double? fullCloseTime,
    String? updatedAt,
  }) {
    return ValveConfig(
      valveId: valveId ?? this.valveId,
      fullOpenTime: fullOpenTime ?? this.fullOpenTime,
      fullCloseTime: fullCloseTime ?? this.fullCloseTime,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 蝶阀开度
class ValveOpenness {
  final int valveId;
  final double opennessPercent;
  final String currentStatus;
  final String? lastCalibration;
  final String? calibrationTime;
  final String? batchCode;

  ValveOpenness({
    required this.valveId,
    required this.opennessPercent,
    required this.currentStatus,
    this.lastCalibration,
    this.calibrationTime,
    this.batchCode,
  });

  factory ValveOpenness.fromJson(Map<String, dynamic> json) {
    return ValveOpenness(
      valveId: json['valve_id'] as int? ?? 0,
      opennessPercent: (json['openness_percent'] as num?)?.toDouble() ?? 0.0,
      currentStatus: json['current_status'] as String? ?? '00',
      lastCalibration: json['last_calibration'] as String?,
      calibrationTime: json['calibration_time'] as String?,
      batchCode: json['batch_code'] as String?,
    );
  }
}
