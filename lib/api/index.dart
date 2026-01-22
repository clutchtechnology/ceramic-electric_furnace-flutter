// 网络请求统一入口
// 用于处理全局的网络请求配置、拦截器、基础请求方法等

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'api.dart';

/// 简易日志类
class _Logger {
  void info(String msg) => print('[INFO] $msg');
  void warning(String msg) => print('[WARN] $msg');
  void error(String msg, [Object? e]) => print('[ERROR] $msg ${e ?? ''}');
}

final _logger = _Logger();

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final String baseUrl = Api.baseUrl;

  // ===== HTTP Client 配置 =====
  // 1, HTTP Client 单例（定期刷新防止僵尸连接）
  static http.Client _httpClient = _createClient();
  static DateTime _lastRefresh = DateTime.now();
  static const Duration _refreshInterval = Duration(minutes: 10);
  static bool _isDisposed = false;

  // 2, 超时配置
  static const Duration _timeout = Duration(seconds: 10);
  static const Duration _connectionTimeout = Duration(seconds: 5);

  // 3, 连续失败计数
  static int _consecutiveFailures = 0;

  /// [CRITICAL] 创建带连接超时的 HTTP Client
  static http.Client _createClient() {
    final httpClient = HttpClient()
      ..connectionTimeout = _connectionTimeout
      ..idleTimeout = const Duration(seconds: 30);
    return IOClient(httpClient);
  }

  /// 获取 HTTP Client（自动刷新过期连接）
  static http.Client get _client {
    if (_isDisposed) {
      _httpClient = _createClient();
      _isDisposed = false;
      _lastRefresh = DateTime.now();
      _consecutiveFailures = 0;
    } else if (DateTime.now().difference(_lastRefresh) > _refreshInterval) {
      _logger.info('HTTP Client 定期刷新');
      _httpClient.close();
      _httpClient = _createClient();
      _lastRefresh = DateTime.now();
      _consecutiveFailures = 0;
    } else if (_consecutiveFailures >= 3) {
      _logger.warning('连续失败 $_consecutiveFailures 次，强制刷新 HTTP Client');
      _httpClient.close();
      _httpClient = _createClient();
      _lastRefresh = DateTime.now();
      _consecutiveFailures = 0;
    }
    return _httpClient;
  }

  Future<dynamic> get(String path, {Map<String, String>? params}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);

    try {
      final response = await _client.get(uri).timeout(_timeout);
      _consecutiveFailures = 0;
      return _processResponse(response, uri.toString());
    } on TimeoutException {
      _handleError('GET', uri.toString(), 'Request timeout');
      rethrow;
    } on SocketException catch (e) {
      _handleError('GET', uri.toString(), 'Socket error: $e');
      rethrow;
    } on http.ClientException catch (e) {
      _handleError('GET', uri.toString(), 'Client error: $e');
      rethrow;
    } catch (e) {
      _handleError('GET', uri.toString(), e.toString());
      rethrow;
    }
  }

  Future<dynamic> post(String path,
      {Map<String, String>? params, dynamic body}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);

    try {
      final response = await _client.post(
        uri,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      _consecutiveFailures = 0;
      return _processResponse(response, uri.toString());
    } on TimeoutException {
      _handleError('POST', uri.toString(), 'Request timeout');
      rethrow;
    } on SocketException catch (e) {
      _handleError('POST', uri.toString(), 'Socket error: $e');
      rethrow;
    } on http.ClientException catch (e) {
      _handleError('POST', uri.toString(), 'Client error: $e');
      rethrow;
    } catch (e) {
      _handleError('POST', uri.toString(), e.toString());
      rethrow;
    }
  }

  dynamic _processResponse(http.Response response, String url) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      try {
        return jsonDecode(response.body);
      } catch (e) {
        _logger.error('JSON解析失败: $url', e);
        return {'raw': response.body};
      }
    } else {
      final error = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
      _logger.error('API请求失败: $url - $error');
      throw HttpException(error, uri: Uri.parse(url));
    }
  }

  void _handleError(String method, String url, String error) {
    _consecutiveFailures++;
    _logger.error('[$method] $url - $error');
  }

  // ===== 业务 API 方法 =====

  /// 获取实时数据（批量）
  /// 返回: electrodes, electricity, cooling, hopper, batch
  Future<Map<String, dynamic>?> getRealtimeBatch() async {
    try {
      final response = await get(Api.realtimeBatch);
      if (response != null && response['success'] == true) {
        return response['data'];
      }
      _logger.warning('获取实时数据失败: ${response?['error']}');
      return null;
    } catch (e) {
      _logger.error('获取实时数据异常', e);
      return null;
    }
  }

  /// 获取健康状态
  Future<Map<String, dynamic>?> getHealth() async {
    try {
      final response = await get(Api.health);
      if (response != null && response['success'] == true) {
        return response['data'];
      }
      return null;
    } catch (e) {
      _logger.error('获取健康状态异常', e);
      return null;
    }
  }

  /// 开始冶炼
  Future<Map<String, dynamic>?> startSmelting({String? batchCode}) async {
    try {
      final body = batchCode != null ? {'batch_code': batchCode} : {};
      final response = await post(Api.smeltingStart, body: body);
      if (response != null && response['success'] == true) {
        return response['data'];
      }
      _logger.warning('开始冶炼失败: ${response?['error']}');
      return null;
    } catch (e) {
      _logger.error('开始冶炼异常', e);
      return null;
    }
  }

  /// 停止冶炼
  Future<Map<String, dynamic>?> stopSmelting() async {
    try {
      final response = await post(Api.smeltingStop);
      if (response != null && response['success'] == true) {
        return response['data'];
      }
      _logger.warning('停止冶炼失败: ${response?['error']}');
      return null;
    } catch (e) {
      _logger.error('停止冶炼异常', e);
      return null;
    }
  }

  /// 获取批次信息
  Future<Map<String, dynamic>?> getBatchInfo() async {
    try {
      final response = await get(Api.smeltingBatch);
      if (response != null && response['success'] == true) {
        return response['data'];
      }
      return null;
    } catch (e) {
      _logger.error('获取批次信息异常', e);
      return null;
    }
  }

  // ===== 历史数据 API =====

  /// 获取时间范围内的批次号列表
  /// [hours] 查询时间范围（小时），默认24小时
  /// [field] 可选字段筛选
  Future<List<String>> getBatchCodes({
    DateTime? start,
    DateTime? end,
    int hours = 24,
    String? field,
  }) async {
    try {
      final params = <String, String>{
        'hours': hours.toString(),
      };
      if (start != null) params['start'] = start.toUtc().toIso8601String();
      if (end != null) params['end'] = end.toUtc().toIso8601String();
      if (field != null) params['field'] = field;

      final response = await get(Api.historyBatches, params: params);
      if (response != null && response['success'] == true) {
        final data = response['data'] as List<dynamic>?;
        return data?.map((e) => e.toString()).toList() ?? [];
      }
      return [];
    } catch (e) {
      _logger.error('获取批次号列表异常', e);
      return [];
    }
  }

  /// 获取料仓历史数据
  /// [type] 数据类型: weight(料仓重量) / feed(投料重量)
  Future<List<Map<String, dynamic>>> getHopperHistory({
    required String type,
    DateTime? start,
    DateTime? end,
    int hours = 24,
    String interval = '1m',
    String? batchCode,
  }) async {
    try {
      final params = <String, String>{
        'type': type,
        'hours': hours.toString(),
        'interval': interval,
      };
      if (start != null) params['start'] = start.toUtc().toIso8601String();
      if (end != null) params['end'] = end.toUtc().toIso8601String();
      if (batchCode != null) params['batch_code'] = batchCode;

      final response = await get(Api.historyHopper, params: params);
      if (response != null && response['success'] == true) {
        final data = response['data'] as List<dynamic>?;
        return data?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      }
      return [];
    } catch (e) {
      _logger.error('获取料仓历史数据异常', e);
      return [];
    }
  }

  /// 获取冷却水历史数据
  /// [type] 数据类型: flow_shell/flow_cover/pressure_shell/pressure_cover/filter_diff
  Future<List<Map<String, dynamic>>> getCoolingHistory({
    required String type,
    DateTime? start,
    DateTime? end,
    int hours = 24,
    String interval = '1m',
    String? batchCode,
  }) async {
    try {
      final params = <String, String>{
        'type': type,
        'hours': hours.toString(),
        'interval': interval,
      };
      if (start != null) params['start'] = start.toUtc().toIso8601String();
      if (end != null) params['end'] = end.toUtc().toIso8601String();
      if (batchCode != null) params['batch_code'] = batchCode;

      final response = await get(Api.historyCooling, params: params);
      if (response != null && response['success'] == true) {
        final data = response['data'] as List<dynamic>?;
        return data?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      }
      return [];
    } catch (e) {
      _logger.error('获取冷却水历史数据异常', e);
      return [];
    }
  }

  /// 获取电极电流历史数据
  /// [electrodes] 电极编号列表，如 ['1', '2', '3']
  Future<Map<String, List<Map<String, dynamic>>>> getCurrentHistory({
    List<String> electrodes = const ['1', '2', '3'],
    DateTime? start,
    DateTime? end,
    int hours = 24,
    String interval = '1m',
    String? batchCode,
  }) async {
    try {
      final params = <String, String>{
        'electrodes': electrodes.join(','),
        'hours': hours.toString(),
        'interval': interval,
      };
      if (start != null) params['start'] = start.toUtc().toIso8601String();
      if (end != null) params['end'] = end.toUtc().toIso8601String();
      if (batchCode != null) params['batch_code'] = batchCode;

      final response = await get(Api.historyCurrent, params: params);
      if (response != null && response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        final result = <String, List<Map<String, dynamic>>>{};
        data?.forEach((key, value) {
          if (value is List) {
            result[key] = value.map((e) => e as Map<String, dynamic>).toList();
          }
        });
        return result;
      }
      return {};
    } catch (e) {
      _logger.error('获取电极电流历史数据异常', e);
      return {};
    }
  }

  /// 获取功率/能耗历史数据
  /// [type] 数据类型: power(瞬时功率) / energy(能耗)
  Future<List<Map<String, dynamic>>> getPowerHistory({
    required String type,
    DateTime? start,
    DateTime? end,
    int hours = 24,
    String interval = '1m',
    String? batchCode,
  }) async {
    try {
      final params = <String, String>{
        'type': type,
        'hours': hours.toString(),
        'interval': interval,
      };
      if (start != null) params['start'] = start.toUtc().toIso8601String();
      if (end != null) params['end'] = end.toUtc().toIso8601String();
      if (batchCode != null) params['batch_code'] = batchCode;

      final response = await get(Api.historyPower, params: params);
      if (response != null && response['success'] == true) {
        final data = response['data'] as List<dynamic>?;
        return data?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      }
      return [];
    } catch (e) {
      _logger.error('获取功率能耗历史数据异常', e);
      return [];
    }
  }

  /// 释放 HTTP Client (静态方法，供 main.dart 调用)
  static void dispose() {
    _httpClient.close();
    _isDisposed = true;
  }
}
