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

  /// 释放资源
  void dispose() {
    _httpClient.close();
  }
}
