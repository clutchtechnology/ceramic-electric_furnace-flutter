import 'package:flutter/material.dart';
import '../widgets/common/tech_line_widgets.dart';
import '../widgets/history_curve/time_range_selector.dart';
import '../widgets/history_curve/tech_chart.dart';
import '../widgets/common/refresh_button.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'dart:math' as math;
import 'dart:io';

/// 历史曲线页面
/// 包含四个面板：电炉能耗曲线、电炉炉皮温度曲线、前置过滤器压差曲线、除尘器入口温度
class HistoryCurvePage extends StatefulWidget {
  const HistoryCurvePage({super.key});

  @override
  State<HistoryCurvePage> createState() => _HistoryCurvePageState();
}

class _HistoryCurvePageState extends State<HistoryCurvePage> {
  // 状态变量
  String _weightSelect = '料仓重量';
  String _filterSelect = '前置过滤器压差';
  final List<String> _currentSelects = ['电极1电流'];
  String _powerSelect = '瞬时功率';
  String _dustSelect = '除尘器温度';
  String _vibrationSelect = '风机振动幅度';

  // 下拉选项常量
  final List<String> _weightOptions = ['料仓重量', '投料重量'];
  final List<String> _filterOptions = ['前置过滤器压差', '冷却水流速', '冷却水水压'];
  final List<String> _currentOptions = ['电极1电流', '电极2电流', '电极3电流'];
  final List<String> _powerOptions = ['瞬时功率', '能耗'];
  final List<String> _dustOptions = ['除尘器温度', '除尘器PM10浓度', '瞬时功率', '能耗'];
  final List<String> _vibrationOptions = ['风机振动幅度', '频谱', '水泵振动幅度', '频谱'];

  // ============================================================
  // [FIX] 数据缓存 - 避免联动刷新问题
  // 每个图表的数据单独缓存，只有该图表刷新时才重新生成
  // ============================================================
  Map<String, List<ChartDataPoint>> _dataCache = {};

  @override
  void initState() {
    super.initState();
    // 初始化时为每个图表生成数据
    _refreshChartData('weight', _weightSelect);
    _refreshChartData('filter', _filterSelect);
    for (var item in _currentSelects) {
      _refreshChartData('current_$item', item);
    }
    _refreshChartData('power', _powerSelect);
    _refreshChartData('dust', _dustSelect);
    _refreshChartData('vibration', _vibrationSelect);
  }

  /// 刷新指定图表的数据
  void _refreshChartData(String cacheKey, String type) {
    _dataCache[cacheKey] = _generateMockData(type);
  }

  /// 获取缓存的图表数据
  List<ChartDataPoint> _getCachedData(String cacheKey, String type) {
    if (!_dataCache.containsKey(cacheKey)) {
      _refreshChartData(cacheKey, type);
    }
    return _dataCache[cacheKey]!;
  }

  // 辅助函数：生成模拟数据
  List<ChartDataPoint> _generateMockData(String type) {
    // 简单根据类型返回不同的模拟数据范围
    double base = 100;
    double variance = 20;

    if (type.contains('重量') || type.contains('kg')) {
      base = 2000;
      variance = 100;
    } else if (type.contains('压差')) {
      base = 125;
      variance = 10;
    } else if (type.contains('流速')) {
      base = 2.5;
      variance = 0.5;
    } else if (type.contains('水压')) {
      base = 0.18;
      variance = 0.02;
    } else if (type.contains('电流')) {
      base = 30;
      variance = 2;
    } else if (type.contains('幅值')) {
      base = 2.8;
      variance = 0.5;
    } else if (type.contains('频谱')) {
      base = 50;
      variance = 5;
    } else if (type.contains('温度')) {
      base = 85;
      variance = 10;
    } else if (type.contains('浓度')) {
      base = 12;
      variance = 3;
    } else if (type.contains('功率')) {
      base = 350;
      variance = 40;
    } else if (type.contains('能耗')) {
      base = 1500;
      variance = 500;
    }

    final random = math.Random();
    return List.generate(24, (index) {
      final value = base + (random.nextDouble() - 0.5) * variance;
      final time = DateTime.now().subtract(Duration(hours: 24 - index));
      return ChartDataPoint(
        label: '${time.hour.toString().padLeft(2, '0')}:00',
        value: value,
      );
    });
  }

  // 构建下拉菜单辅助组件
  Widget _buildDropdown(
      List<String> items, String value, ValueChanged<String?> onChanged,
      {required Color accentColor}) {
    return PopupMenuButton<String>(
      initialValue: value,
      tooltip: '选择显示项',
      color: TechColors.bgMedium,
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: accentColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      onSelected: onChanged,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        decoration: BoxDecoration(
          color: TechColors.bgLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: accentColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style:
                  const TextStyle(color: TechColors.textPrimary, fontSize: 12),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: accentColor, size: 18),
          ],
        ),
      ),
      itemBuilder: (context) {
        return items.map((String item) {
          final isSelected = item == value;
          return PopupMenuItem<String>(
            value: item,
            height: 32,
            child: Text(
              item,
              style: TextStyle(
                color: isSelected ? accentColor : TechColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList();
      },
    );
  }

  // 构建导出按钮
  Widget _buildExportButton(String title, List<ChartDataPoint> data,
      {required Color accentColor}) {
    return IconButton(
      icon: Icon(Icons.download, size: 18, color: accentColor),
      tooltip: '导出为Excel',
      onPressed: () => _exportToExcel(title, data),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      splashRadius: 16,
    );
  }

  // 导出数据为Excel文件
  Future<void> _exportToExcel(String title, List<ChartDataPoint> data) async {
    try {
      // 让用户选择保存目录
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择保存目录',
      );

      if (selectedDirectory == null) {
        // 用户取消了选择
        return;
      }

      final excelObj = excel.Excel.createExcel();
      final sheet = excelObj['Sheet1'];

      // 添加标题行
      sheet.appendRow([excel.TextCellValue('时间'), excel.TextCellValue(title)]);

      // 添加数据行
      for (var point in data) {
        sheet.appendRow([
          excel.TextCellValue(point.label),
          excel.TextCellValue(point.value.toStringAsFixed(2)),
        ]);
      }

      // 设置列宽
      sheet.setColumnWidth(0, 15);
      sheet.setColumnWidth(1, 15);

      // 生成文件名
      final timestamp = DateTime.now()
          .toString()
          .replaceAll(RegExp(r'[^\d]'), '')
          .substring(0, 12);
      final fileName = '${title}_$timestamp.xlsx';
      final filePath = '$selectedDirectory\\$fileName';

      // 保存文件
      final bytes = excelObj.encode();
      if (bytes != null) {
        await File(filePath).writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已导出到: $filePath'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  // 构建多选下拉菜单辅助组件 (使用 PopupMenu 实现)
  Widget _buildMultiSelectDropdown(List<String> items,
      List<String> selectedValues, ValueChanged<String> onToggle,
      {required Color accentColor}) {
    return PopupMenuButton<String>(
      tooltip: '选择显示项',
      color: TechColors.bgMedium,
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: accentColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: TechColors.bgLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: accentColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '已选 ${selectedValues.length} 项',
              style:
                  const TextStyle(color: TechColors.textPrimary, fontSize: 12),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: accentColor, size: 18),
          ],
        ),
      ),
      itemBuilder: (context) {
        return items.map((item) {
          final isSelected = selectedValues.contains(item);
          return CheckedPopupMenuItem<String>(
            value: item,
            checked: isSelected,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            height: 32,
            child: Text(
              item,
              style: TextStyle(
                color: isSelected ? accentColor : TechColors.textSecondary,
                fontSize: 12,
              ),
            ),
          );
        }).toList();
      },
      onSelected: onToggle,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 2列3行布局，每个区域高度计算
    // 减去总padding和间距
    // 3 rows = 3 * height + 2 * spacing(8)
    // height = (total - 16) / 3
    // 使用 Column + Expanded 构建行
    return Container(
      color: TechColors.bgDeep,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Row 1
          Expanded(
            child: Row(
              children: [
                // 1. 料仓重量/投料重量
                Expanded(
                  child: TechPanel(
                    title: '料仓',
                    accentColor: TechColors.glowOrange,
                    height: double.infinity,
                    headerActions: [
                      _buildDropdown(_weightOptions, _weightSelect, (v) {
                        setState(() {
                          _weightSelect = v!;
                          _refreshChartData('weight', _weightSelect);
                        });
                      }, accentColor: TechColors.glowOrange),
                      const SizedBox(width: 12),
                      TimeRangeSelector(
                        accentColor: TechColors.glowOrange,
                        onTimeRangeChanged: (start, end) =>
                            debugPrint('Time: $start - $end'),
                      ),
                      const SizedBox(width: 8),
                      RefreshButton(
                          accentColor: TechColors.glowOrange,
                          onPressed: () => setState(() => _refreshChartData('weight', _weightSelect))),
                      const SizedBox(width: 8),
                      _buildExportButton('料仓', _getCachedData('weight', _weightSelect),
                          accentColor: TechColors.glowOrange),
                    ],
                    child: TechLineChart(
                      data: _getCachedData('weight', _weightSelect),
                      accentColor: TechColors.glowOrange,
                      yAxisLabel: _weightSelect.contains('重量') ? 'kg' : '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 2. 前置过滤器/冷却水
                Expanded(
                  child: TechPanel(
                    title: '冷却水',
                    accentColor: TechColors.glowBlue,
                    height: double.infinity,
                    headerActions: [
                      _buildDropdown(_filterOptions, _filterSelect, (v) {
                        setState(() {
                          _filterSelect = v!;
                          _refreshChartData('filter', _filterSelect);
                        });
                      }, accentColor: TechColors.glowBlue),
                      const SizedBox(width: 12),
                      TimeRangeSelector(
                        accentColor: TechColors.glowBlue,
                        onTimeRangeChanged: (start, end) =>
                            debugPrint('Time: $start - $end'),
                      ),
                      const SizedBox(width: 8),
                      RefreshButton(
                          accentColor: TechColors.glowBlue,
                          onPressed: () => setState(() => _refreshChartData('filter', _filterSelect))),
                      const SizedBox(width: 8),
                      _buildExportButton('冷却水', _getCachedData('filter', _filterSelect),
                          accentColor: TechColors.glowBlue),
                    ],
                    child: TechLineChart(
                      data: _getCachedData('filter', _filterSelect),
                      accentColor: TechColors.glowBlue,
                      yAxisLabel: _filterSelect.contains('压')
                          ? (_filterSelect.contains('差') ? 'Pa' : 'MPa')
                          : 'm³/h',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Row 2
          Expanded(
            child: Row(
              children: [
                // 3. 电炉电流 (多选)
                Expanded(
                  child: TechPanel(
                    title: '电炉电流',
                    accentColor: TechColors.glowCyan,
                    height: double.infinity,
                    headerActions: [
                      _buildMultiSelectDropdown(
                          _currentOptions, _currentSelects, (item) {
                        setState(() {
                          if (_currentSelects.contains(item)) {
                            if (_currentSelects.length > 1) {
                              _currentSelects.remove(item);
                              _dataCache.remove('current_$item');
                            }
                          } else {
                            if (_currentSelects.length < 3) {
                              _currentSelects.add(item);
                              _refreshChartData('current_$item', item);
                            }
                          }
                        });
                      }, accentColor: TechColors.glowCyan),
                      const SizedBox(width: 12),
                      TimeRangeSelector(
                        accentColor: TechColors.glowCyan,
                        onTimeRangeChanged: (start, end) =>
                            debugPrint('Time: $start - $end'),
                      ),
                      const SizedBox(width: 8),
                      RefreshButton(
                          accentColor: TechColors.glowCyan,
                          onPressed: () {
                            setState(() {
                              for (var item in _currentSelects) {
                                _refreshChartData('current_$item', item);
                              }
                            });
                          }),
                      const SizedBox(width: 8),
                      _buildExportButton(
                          '电炉电流',
                          _getCachedData('current_${_currentSelects.first}', _currentSelects.first),
                          accentColor: TechColors.glowCyan),
                    ],
                    child: TechLineChart(
                      data: [], // Ignored when datas is provided
                      datas: _currentSelects
                          .map((type) => _getCachedData('current_$type', type))
                          .toList(),
                      colors: const [
                        TechColors.glowCyan,
                        TechColors.glowGreen,
                        TechColors.glowOrange
                      ],
                      accentColor: TechColors.glowCyan,
                      yAxisLabel: '电流 (A)',
                      showGrid: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 4. 电炉能耗/功率
                Expanded(
                  child: TechPanel(
                    title: '电炉功率能耗',
                    accentColor: TechColors.glowGreen,
                    height: double.infinity,
                    headerActions: [
                      _buildDropdown(_powerOptions, _powerSelect, (v) {
                        setState(() {
                          _powerSelect = v!;
                          _refreshChartData('power', _powerSelect);
                        });
                      }, accentColor: TechColors.glowGreen),
                      const SizedBox(width: 12),
                      TimeRangeSelector(
                        accentColor: TechColors.glowGreen,
                        onTimeRangeChanged: (start, end) =>
                            debugPrint('Time: $start - $end'),
                      ),
                      const SizedBox(width: 8),
                      RefreshButton(
                          accentColor: TechColors.glowGreen,
                          onPressed: () => setState(() => _refreshChartData('power', _powerSelect))),
                      const SizedBox(width: 8),
                      _buildExportButton('电炉功率能耗', _getCachedData('power', _powerSelect),
                          accentColor: TechColors.glowGreen),
                    ],
                    child: TechLineChart(
                      data: _getCachedData('power', _powerSelect),
                      accentColor: TechColors.glowGreen,
                      yAxisLabel: _powerSelect == '能耗' ? 'kWh' : 'kW',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Row 3
          Expanded(
            child: Row(
              children: [
                // 5. 除尘器 (四选一)
                Expanded(
                  child: TechPanel(
                    title: '除尘器',
                    accentColor: TechColors.glowBlue,
                    height: double.infinity,
                    headerActions: [
                      _buildDropdown(_dustOptions, _dustSelect, (v) {
                        setState(() {
                          _dustSelect = v!;
                          _refreshChartData('dust', _dustSelect);
                        });
                      }, accentColor: TechColors.glowBlue),
                      const SizedBox(width: 12),
                      TimeRangeSelector(
                        accentColor: TechColors.glowBlue,
                        onTimeRangeChanged: (start, end) =>
                            debugPrint('Time: $start - $end'),
                      ),
                      const SizedBox(width: 8),
                      RefreshButton(
                          accentColor: TechColors.glowBlue,
                          onPressed: () => setState(() => _refreshChartData('dust', _dustSelect))),
                      const SizedBox(width: 8),
                      _buildExportButton('除尘器', _getCachedData('dust', _dustSelect),
                          accentColor: TechColors.glowBlue),
                    ],
                    child: TechLineChart(
                      data: _getCachedData('dust', _dustSelect),
                      accentColor: TechColors.glowBlue,
                      yAxisLabel: _dustSelect.contains('温度')
                          ? '℃'
                          : (_dustSelect.contains('浓度') ? 'ug/m³' : ''),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 6. 振动 (遮罩)
                Expanded(
                  child: TechPanel(
                    title: '振动分析',
                    accentColor: TechColors.glowRed,
                    height: double.infinity,
                    headerActions: [
                      _buildDropdown(_vibrationOptions, _vibrationSelect, (v) {
                        setState(() {
                          _vibrationSelect = v!;
                          _refreshChartData('vibration', _vibrationSelect);
                        });
                      }, accentColor: TechColors.glowRed),
                      const SizedBox(width: 12),
                      TimeRangeSelector(
                        accentColor: TechColors.glowRed,
                        onTimeRangeChanged: (start, end) =>
                            debugPrint('Time: $start - $end'),
                      ),
                      const SizedBox(width: 8),
                      RefreshButton(
                          accentColor: TechColors.glowRed,
                          onPressed: () => setState(() => _refreshChartData('vibration', _vibrationSelect))),
                      const SizedBox(width: 8),
                      _buildExportButton('振动分析', _getCachedData('vibration', _vibrationSelect),
                          accentColor: TechColors.glowRed),
                    ],
                    child: Stack(
                      children: [
                        TechLineChart(
                          data: _getCachedData('vibration', _vibrationSelect),
                          accentColor: TechColors.glowRed,
                          yAxisLabel:
                              _vibrationSelect == '振动幅值' ? 'mm/s' : 'Hz',
                        ),
                        // 遮罩层
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
