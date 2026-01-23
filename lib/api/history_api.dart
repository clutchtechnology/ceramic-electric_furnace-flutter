/// 历史数据 API 客户端
/// 用于查询 InfluxDB 中的历史数据

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api.dart';

/// 历史数据点
class HistoryDataPoint {
  final String time;
  final double value;
  final String? field;

  HistoryDataPoint({
    required this.time,
    required this.value,
    this.field,
  });

  factory HistoryDataPoint.fromJson(Map<String, dynamic> json) {
    return HistoryDataPoint(
      time: json['time'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      field: json['field'],
    );
  }
}

/// 批次摘要信息（用于历史轮次对比）
class BatchSummary {
  final String batchCode;
  final double? feedWeight; // 投料重量 (kg)
  final double? shellWaterTotal; // 炉皮冷却水用量 (m³)
  final double? coverWaterTotal; // 炉盖冷却水用量 (m³)
  final String? startTime;
  final String? endTime;

  BatchSummary({
    required this.batchCode,
    this.feedWeight,
    this.shellWaterTotal,
    this.coverWaterTotal,
    this.startTime,
    this.endTime,
  });
}

/// 历史数据 API 客户端
class HistoryApi {
  static final HistoryApi _instance = HistoryApi._internal();
  factory HistoryApi() => _instance;
  HistoryApi._internal();

  final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 15);

  /// 获取所有历史批次号列表
  ///
  /// [hours] - 查询最近多少小时的批次（默认720小时=30天）
  /// [prefix] - 批次号前缀筛选：SM(主动冶炼) / SX(被动创建)
  Future<List<String>> getBatches({
    int hours = 720,
    String? prefix,
  }) async {
    try {
      final params = <String, String>{
        'hours': hours.toString(),
      };
      if (prefix != null) params['prefix'] = prefix;

      final uri = Uri.parse('${Api.baseUrl}${Api.historyBatches}')
          .replace(queryParameters: params);

      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['data'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('[HistoryApi] 获取批次列表失败: $e');
      return [];
    }
  }

  /// 查询电极电流历史数据
  ///
  /// [electrodes] - 电极编号列表 (1,2,3)
  /// [batchCode] - 批次号
  /// [interval] - 聚合间隔 (默认10m)
  /// [start] - 开始时间 ISO格式
  /// [end] - 结束时间 ISO格式
  Future<Map<String, List<HistoryDataPoint>>> getCurrentHistory({
    List<String> electrodes = const ['1', '2', '3'],
    String? batchCode,
    String interval = '10m',
    String? start,
    String? end,
    int hours = 24,
  }) async {
    try {
      final params = <String, String>{
        'electrodes': electrodes.join(','),
        'interval': interval,
        'hours': hours.toString(),
      };
      if (batchCode != null) params['batch_code'] = batchCode;
      if (start != null) params['start'] = start;
      if (end != null) params['end'] = end;

      final uri = Uri.parse('${Api.baseUrl}${Api.historyCurrent}')
          .replace(queryParameters: params);

      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final result = <String, List<HistoryDataPoint>>{};
          final dataMap = data['data'] as Map<String, dynamic>? ?? {};

          dataMap.forEach((key, value) {
            if (value is List) {
              result[key] = value
                  .map((e) =>
                      HistoryDataPoint.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
          });
          return result;
        }
      }
      return {};
    } catch (e) {
      print('[HistoryApi] 查询电流历史失败: $e');
      return {};
    }
  }

  /// 查询料仓历史数据
  ///
  /// [type] - 数据类型: weight(料仓重量) / feed(投料重量)
  Future<List<HistoryDataPoint>> getHopperHistory({
    String type = 'weight',
    String? batchCode,
    String interval = '10m',
    String? start,
    String? end,
    int hours = 24,
  }) async {
    try {
      final params = <String, String>{
        'type': type,
        'interval': interval,
        'hours': hours.toString(),
      };
      if (batchCode != null) params['batch_code'] = batchCode;
      if (start != null) params['start'] = start;
      if (end != null) params['end'] = end;

      final uri = Uri.parse('${Api.baseUrl}${Api.historyHopper}')
          .replace(queryParameters: params);

      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final list = data['data'] as List? ?? [];
          return list
              .map((e) => HistoryDataPoint.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('[HistoryApi] 查询料仓历史失败: $e');
      return [];
    }
  }

  /// 查询冷却水历史数据
  ///
  /// [type] - 数据类型:
  ///   flow_shell(炉皮流速) / flow_cover(炉盖流速)
  ///   pressure_shell(炉皮水压) / pressure_cover(炉盖水压)
  Future<List<HistoryDataPoint>> getCoolingHistory({
    required String type,
    String? batchCode,
    String interval = '10m',
    String? start,
    String? end,
    int hours = 24,
  }) async {
    try {
      final params = <String, String>{
        'type': type,
        'interval': interval,
        'hours': hours.toString(),
      };
      if (batchCode != null) params['batch_code'] = batchCode;
      if (start != null) params['start'] = start;
      if (end != null) params['end'] = end;

      final uri = Uri.parse('${Api.baseUrl}${Api.historyCooling}')
          .replace(queryParameters: params);

      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final list = data['data'] as List? ?? [];
          return list
              .map((e) => HistoryDataPoint.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('[HistoryApi] 查询冷却水历史失败: $e');
      return [];
    }
  }

  /// 查询功率/能耗历史数据
  ///
  /// [type] - 数据类型: power(瞬时功率) / energy(能耗)
  Future<List<HistoryDataPoint>> getPowerHistory({
    String type = 'power',
    String? batchCode,
    String interval = '10m',
    String? start,
    String? end,
    int hours = 24,
  }) async {
    try {
      final params = <String, String>{
        'type': type,
        'interval': interval,
        'hours': hours.toString(),
      };
      if (batchCode != null) params['batch_code'] = batchCode;
      if (start != null) params['start'] = start;
      if (end != null) params['end'] = end;

      final uri = Uri.parse('${Api.baseUrl}${Api.historyPower}')
          .replace(queryParameters: params);

      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final list = data['data'] as List? ?? [];
          return list
              .map((e) => HistoryDataPoint.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('[HistoryApi] 查询功率历史失败: $e');
      return [];
    }
  }

  /// 通用历史数据查询
  Future<List<HistoryDataPoint>> queryHistory({
    required String field,
    String? batchCode,
    String interval = '10m',
    String? start,
    String? end,
    int hours = 24,
  }) async {
    try {
      final params = <String, String>{
        'field': field,
        'interval': interval,
        'hours': hours.toString(),
      };
      if (batchCode != null) params['batch_code'] = batchCode;
      if (start != null) params['start'] = start;
      if (end != null) params['end'] = end;

      final uri = Uri.parse('${Api.baseUrl}${Api.historyQuery}')
          .replace(queryParameters: params);

      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final list = data['data'] as List? ?? [];
          return list
              .map((e) => HistoryDataPoint.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('[HistoryApi] 通用历史查询失败: $e');
      return [];
    }
  }

  /// 获取批次摘要数据（用于历史轮次对比柱状图）
  ///
  /// 查询每个批次的最新值：投料重量、冷却水用量等
  /// 直接调用后端 /api/history/batch/summary 接口
  Future<List<BatchSummary>> getBatchSummaries(List<String> batchCodes) async {
    if (batchCodes.isEmpty) return [];

    try {
      final params = <String, String>{
        'batch_codes': batchCodes.join(','),
      };

      final uri = Uri.parse('${Api.baseUrl}${Api.historyBatchSummary}')
          .replace(queryParameters: params);

      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final list = data['data'] as List? ?? [];
          return list
              .map((item) => BatchSummary(
                    batchCode: item['batch_code'] ?? '',
                    feedWeight: (item['feed_weight'] as num?)?.toDouble(),
                    shellWaterTotal:
                        (item['shell_water_total'] as num?)?.toDouble(),
                    coverWaterTotal:
                        (item['cover_water_total'] as num?)?.toDouble(),
                  ))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('[HistoryApi] 获取批次摘要失败: $e');
      return [];
    }
  }

  void dispose() {
    _client.close();
  }
}
