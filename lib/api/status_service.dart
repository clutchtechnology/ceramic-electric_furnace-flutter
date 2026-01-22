import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../api/api.dart';
import '../models/status_model.dart';

/// 设备状态服务
///
/// 提供 DB30 (通信状态) 和 DB41 (数据状态) 的查询功能
///
/// [CRITICAL] HTTP Client 管理规范:
/// - 使用单例 HTTP Client，避免每次请求创建新连接
/// - 定期刷新防止僵尸连接 (10分钟)
/// - 连续失败3次强制刷新
/// - 所有请求必须设置超时 (10秒)
class StatusService {
  // 单例模式
  static final StatusService _instance = StatusService._internal();
  factory StatusService() => _instance;
  StatusService._internal();

  // ===== HTTP Client 配置 (与 ApiClient 保持一致) =====
  static http.Client _client = _createClient();
  static DateTime _lastRefresh = DateTime.now();
  static const _refreshInterval = Duration(minutes: 10);
  static const _timeout = Duration(seconds: 10);
  static const _connectionTimeout = Duration(seconds: 5);
  static int _consecutiveFailures = 0;

  /// 创建带连接超时的 HTTP Client
  static http.Client _createClient() {
    final httpClient = HttpClient()
      ..connectionTimeout = _connectionTimeout
      ..idleTimeout = const Duration(seconds: 30);
    return IOClient(httpClient);
  }

  /// 获取 HTTP Client（自动刷新过期连接）
  http.Client get client {
    if (DateTime.now().difference(_lastRefresh) > _refreshInterval) {
      _client.close();
      _client = _createClient();
      _lastRefresh = DateTime.now();
      _consecutiveFailures = 0;
    } else if (_consecutiveFailures >= 3) {
      _client.close();
      _client = _createClient();
      _lastRefresh = DateTime.now();
      _consecutiveFailures = 0;
    }
    return _client;
  }

  /// 记录请求成功
  void _onSuccess() {
    _consecutiveFailures = 0;
  }

  /// 记录请求失败
  void _onFailure() {
    _consecutiveFailures++;
  }

  // ============================================================
  // DB30 通信状态
  // ============================================================

  /// 获取 DB30 设备列表及状态
  Future<Db30StatusResponse> getDb30Devices() async {
    try {
      final uri = Uri.parse('${Api.baseUrl}${Api.statusDb30Devices}');
      final response = await client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        _onSuccess();
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Db30StatusResponse.fromJson(json);
      } else {
        _onFailure();
        return Db30StatusResponse.error(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on TimeoutException {
      _onFailure();
      return Db30StatusResponse.error('请求超时');
    } on SocketException catch (e) {
      _onFailure();
      return Db30StatusResponse.error('网络连接错误: $e');
    } catch (e) {
      _onFailure();
      return Db30StatusResponse.error('网络错误: $e');
    }
  }

  // ============================================================
  // DB41 数据状态
  // ============================================================

  /// 获取 DB41 设备列表及状态
  Future<Db41StatusResponse> getDb41Devices() async {
    try {
      final uri = Uri.parse('${Api.baseUrl}${Api.statusDb41Devices}');
      final response = await client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        _onSuccess();
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Db41StatusResponse.fromJson(json);
      } else {
        _onFailure();
        return Db41StatusResponse.error(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on TimeoutException {
      _onFailure();
      return Db41StatusResponse.error('请求超时');
    } on SocketException catch (e) {
      _onFailure();
      return Db41StatusResponse.error('网络连接错误: $e');
    } catch (e) {
      _onFailure();
      return Db41StatusResponse.error('网络错误: $e');
    }
  }

  // ============================================================
  // 资源释放
  // ============================================================

  void dispose() {
    _client.close();
  }
}
