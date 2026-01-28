import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common/tech_line_widgets.dart';
import '../widgets/history_curve/time_range_selector.dart';
import '../widgets/history_curve/tech_chart.dart';
import '../widgets/history_curve/tech_bar_chart.dart';
import '../widgets/common/refresh_button.dart';
import '../api/history_api.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'dart:io';

/// 历史曲线页面
/// 包含四个面板：电炉电流、料仓重量、炉皮冷却水、炉盖冷却水
class HistoryCurvePage extends StatefulWidget {
  const HistoryCurvePage({super.key});

  @override
  State<HistoryCurvePage> createState() => _HistoryCurvePageState();
}

class _HistoryCurvePageState extends State<HistoryCurvePage> {
  // API客户端
  final HistoryApi _historyApi = HistoryApi();

  // ====== 加载状态 ======
  bool _isLoadingBatches = true; // 正在加载批次列表
  bool _isLoadingData = false; // 正在加载历史数据
  bool _isLoadingSummary = false; // 正在加载批次摘要

  // ====== 状态变量 ======
  bool _isHistoryMode = false; // 是否为历史轮次查询模式
  String? _selectedBatch; // 当前选中的批次（单选）
  List<String> _selectedBatches = []; // 历史模式下的多选批次
  String _weightSelect = '料仓重量';
  String _shellCoolingSelect = '冷却水流速'; // 炉皮冷却水
  String _lidCoolingSelect = '冷却水流速'; // 炉盖冷却水
  List<String> _currentSelects = ['电极1电流'];
  String _dustSelect = '除尘器振动';
  String _powerSelect = '瞬时功率';

  // 时间范围筛选 (可选)
  DateTime? _startTime;
  DateTime? _endTime;

  // ====== 下拉选项 ======
  List<String> _batchOptions = []; // 从后端API加载
  final List<String> _weightOptions = ['料仓重量', '投料重量'];
  final List<String> _coolingOptions = ['冷却水流速', '冷却水水压', '冷却水用量'];
  final List<String> _currentOptions = ['电极1电流', '电极2电流', '电极3电流'];
  final List<String> _dustOptions = ['除尘器振动'];
  final List<String> _powerOptions = ['瞬时功率', '能耗'];

  // ====== 图表数据缓存（来自API） ======
  Map<String, List<HistoryDataPoint>> _currentData = {}; // 电极电流数据
  List<HistoryDataPoint> _hopperData = []; // 料仓数据
  List<HistoryDataPoint> _shellCoolingData = []; // 炉皮冷却水数据
  List<HistoryDataPoint> _coverCoolingData = []; // 炉盖冷却水数据

  // ====== 历史模式柱状图数据 ======
  List<BatchSummary> _batchSummaries = [];

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  /// 加载历史批次列表
  Future<void> _loadBatches() async {
    setState(() => _isLoadingBatches = true);

    try {
      final batches = await _historyApi.getBatches(hours: 720); // 30天

      if (mounted) {
        setState(() {
          _batchOptions = batches;
          _isLoadingBatches = false;

          // 如果有批次，默认选择第一个
          if (batches.isNotEmpty) {
            _selectedBatch = batches.first;
            _selectedBatches = [batches.first];
            // 加载该批次的数据
            _loadBatchData();
          }
        });
      }
    } catch (e) {
      print('[HistoryCurvePage] 加载批次列表失败: $e');
      if (mounted) {
        setState(() => _isLoadingBatches = false);
      }
    }
  }

  /// 加载选中批次的历史数据（折线图模式）
  Future<void> _loadBatchData() async {
    if (_selectedBatch == null) return;

    setState(() => _isLoadingData = true);

    try {
      // 并行发送4个API请求
      final results = await Future.wait([
        // 1. 电极电流
        _historyApi.getCurrentHistory(
          electrodes: _currentSelects
              .map((e) => e.replaceAll('电极', '').replaceAll('电流', ''))
              .toList(),
          batchCode: _selectedBatch,
          interval: '10m',
          start: _startTime?.toIso8601String(),
          end: _endTime?.toIso8601String(),
          hours: 720,
        ),
        // 2. 料仓数据
        _historyApi.getHopperHistory(
          type: _weightSelect == '投料重量' ? 'feed' : 'weight',
          batchCode: _selectedBatch,
          interval: '10m',
          start: _startTime?.toIso8601String(),
          end: _endTime?.toIso8601String(),
          hours: 720,
        ),
        // 3. 炉皮冷却水
        _historyApi.getCoolingHistory(
          type: _mapCoolingType(_shellCoolingSelect, 'shell'),
          batchCode: _selectedBatch,
          interval: '10m',
          start: _startTime?.toIso8601String(),
          end: _endTime?.toIso8601String(),
          hours: 720,
        ),
        // 4. 炉盖冷却水
        _historyApi.getCoolingHistory(
          type: _mapCoolingType(_lidCoolingSelect, 'cover'),
          batchCode: _selectedBatch,
          interval: '10m',
          start: _startTime?.toIso8601String(),
          end: _endTime?.toIso8601String(),
          hours: 720,
        ),
      ]);

      if (mounted) {
        setState(() {
          _currentData = results[0] as Map<String, List<HistoryDataPoint>>;
          _hopperData = results[1] as List<HistoryDataPoint>;
          _shellCoolingData = results[2] as List<HistoryDataPoint>;
          _coverCoolingData = results[3] as List<HistoryDataPoint>;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('[HistoryCurvePage] 加载历史数据失败: $e');
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  /// 加载批次摘要数据（柱状图模式）
  Future<void> _loadBatchSummaries() async {
    if (_selectedBatches.isEmpty) return;

    setState(() => _isLoadingSummary = true);

    try {
      final summaries = await _historyApi.getBatchSummaries(_selectedBatches);

      if (mounted) {
        setState(() {
          _batchSummaries = summaries;
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      print('[HistoryCurvePage] 加载批次摘要失败: $e');
      if (mounted) {
        setState(() => _isLoadingSummary = false);
      }
    }
  }

  /// 映射冷却水类型到API参数
  String _mapCoolingType(String uiSelect, String position) {
    switch (uiSelect) {
      case '冷却水流速':
        return 'flow_$position';
      case '冷却水水压':
        return 'pressure_$position';
      case '冷却水用量':
        return 'flow_$position'; // 用量也用flow，前端累加或后端有WATER_TOTAL
      default:
        return 'flow_$position';
    }
  }

  /// 将 HistoryDataPoint 转换为 ChartDataPoint
  List<ChartDataPoint> _convertToChartData(List<HistoryDataPoint> data) {
    return data.map((point) {
      final time = DateTime.tryParse(point.time);
      final label = time != null
          ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
          : point.time;
      return ChartDataPoint(label: label, value: point.value);
    }).toList();
  }

  /// 获取电极电流图表数据
  List<List<ChartDataPoint>> _getCurrentChartData() {
    final result = <List<ChartDataPoint>>[];
    for (final electrode in _currentSelects) {
      final key =
          'electrode_${electrode.replaceAll('电极', '').replaceAll('电流', '')}';
      final data = _currentData[key] ?? [];
      result.add(_convertToChartData(data));
    }
    return result;
  }

  /// 获取料仓柱状图数据（历史模式）
  Map<String, double> _getFeedWeightBatchData() {
    final result = <String, double>{};
    for (final summary in _batchSummaries) {
      result[summary.batchCode] = summary.feedWeight ?? 0.0;
    }
    return result;
  }

  /// 获取炉皮冷却水柱状图数据（历史模式）
  Map<String, double> _getShellWaterBatchData() {
    final result = <String, double>{};
    for (final summary in _batchSummaries) {
      result[summary.batchCode] = summary.shellWaterTotal ?? 0.0;
    }
    return result;
  }

  /// 获取炉盖冷却水柱状图数据（历史模式）
  Map<String, double> _getCoverWaterBatchData() {
    final result = <String, double>{};
    for (final summary in _batchSummaries) {
      result[summary.batchCode] = summary.coverWaterTotal ?? 0.0;
    }
    return result;
  }

  /// 刷新所有数据
  void _refreshAllData() {
    if (_isHistoryMode) {
      _loadBatchSummaries();
    } else {
      _loadBatchData();
    }
  }

  /// 处理批次选择变化（单选模式）
  void _onBatchSelected(String? batch) {
    if (batch == null) return;
    setState(() {
      _selectedBatch = batch;
    });
    _loadBatchData();
  }

  /// 处理批次多选变化（历史模式）
  void _onBatchToggled(String batch) {
    setState(() {
      if (_selectedBatches.contains(batch)) {
        if (_selectedBatches.length > 1) {
          _selectedBatches.remove(batch);
        }
      } else {
        _selectedBatches.add(batch);
      }
    });
    _loadBatchSummaries();
  }

  /// 处理时间范围变化
  void _onTimeRangeChanged(DateTime start, DateTime end) {
    setState(() {
      _startTime = start;
      _endTime = end;
    });
    _loadBatchData();
  }

  // 构建下拉菜单辅助组件
  Widget _buildDropdown(List<String> items, String? value,
      ValueChanged<String?> onChanged,
      {required Color accentColor}) {
    final displayValue = value ?? (items.isNotEmpty ? items.first : '无数据');
    return PopupMenuButton<String>(
      initialValue: value,
      tooltip: '选择显示项',
      color: AppTheme.bgMedium(context),
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
          color: AppTheme.bgLight(context).withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: accentColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayValue,
              style:
                  TextStyle(color: AppTheme.textPrimary(context), fontSize: 16),
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
                color:
                    isSelected ? accentColor : AppTheme.textSecondary(context),
                fontSize: 14,
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
      color: AppTheme.bgMedium(context),
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: accentColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.bgLight(context).withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: accentColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '已选 ${selectedValues.length} 项',
              style:
                  TextStyle(color: AppTheme.textPrimary(context), fontSize: 12),
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
                color:
                    isSelected ? accentColor : AppTheme.textSecondary(context),
                fontSize: 12,
              ),
            ),
          );
        }).toList();
      },
      onSelected: onToggle,
    );
  }

  /// 构建页面控制栏
  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgDark(context),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.glowCyan(context).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 历史轮次查询按钮
          InkWell(
            onTap: () {
              setState(() {
                _isHistoryMode = !_isHistoryMode;
                if (_isHistoryMode) {
                  // 切换到历史模式，确保有选中的批次
                  if (_selectedBatches.isEmpty && _selectedBatch != null) {
                    _selectedBatches = [_selectedBatch!];
                  }
                  _loadBatchSummaries();
                } else {
                  // 切换回折线图模式
                  _loadBatchData();
                }
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isHistoryMode
                    ? AppTheme.glowCyan(context).withOpacity(0.2)
                    : AppTheme.bgLight(context).withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _isHistoryMode
                      ? AppTheme.glowCyan(context)
                      : AppTheme.glowCyan(context).withOpacity(0.5),
                  width: _isHistoryMode ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isHistoryMode ? Icons.bar_chart : Icons.timeline,
                    color: AppTheme.glowCyan(context),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '历史轮次查询',
                    style: TextStyle(
                      color: _isHistoryMode
                          ? AppTheme.glowCyan(context)
                          : AppTheme.textPrimary(context),
                      fontSize: 14,
                      fontWeight:
                          _isHistoryMode ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          // 批次编号选择器（根据模式切换单选/多选）
          if (_isLoadingBatches)
            const SizedBox(
              width: 100,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_isHistoryMode)
            _buildMultiSelectDropdown(
              _batchOptions,
              _selectedBatches,
              _onBatchToggled,
              accentColor: AppTheme.glowCyan(context),
            )
          else
            _buildDropdown(
              _batchOptions,
              _selectedBatch,
              _onBatchSelected,
              accentColor: AppTheme.glowCyan(context),
            ),
          const SizedBox(width: 24),
          // 时间选择器（历史模式下隐藏）
          if (!_isHistoryMode)
            TimeRangeSelector(
              accentColor: AppTheme.glowCyan(context),
              onTimeRangeChanged: _onTimeRangeChanged,
            ),
          const Spacer(),
          // 加载状态指示器
          if (_isLoadingData || _isLoadingSummary)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.glowCyan(context)),
              ),
            ),
          // 刷新按钮
          RefreshButton(
            accentColor: AppTheme.glowCyan(context),
            onPressed: _refreshAllData,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TechColors.bgDeep,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // 页面控制栏
          _buildControlBar(),
          const SizedBox(height: 8),
          // 历史轮次查询模式：垂直滚动布局 (每个图表固定高度，防止变形)
          if (_isHistoryMode) ...[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: Column(
                  children: [
                    // 1. 投料重量对比 - 固定高度容器
                    SizedBox(
                      height: 400, // 固定高度 400px
                      child: TechPanel(
                        title: '投料重量对比',
                        accentColor: TechColors.glowOrange,
                        height: double.infinity,
                        child: _isLoadingSummary
                            ? const Center(child: CircularProgressIndicator())
                            : TechBarChart(
                                batchData: _getFeedWeightBatchData(),
                                accentColor: TechColors.glowOrange,
                                yAxisLabel: 'kg',
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 2. 炉皮冷却水用量对比 - 固定高度容器
                    SizedBox(
                      height: 400, // 固定高度 400px
                      child: TechPanel(
                        title: '炉皮冷却水用量对比',
                        accentColor: TechColors.glowBlue,
                        height: double.infinity,
                        child: _isLoadingSummary
                            ? const Center(child: CircularProgressIndicator())
                            : TechBarChart(
                                batchData: _getShellWaterBatchData(),
                                accentColor: TechColors.glowBlue,
                                yAxisLabel: 'm³',
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 3. 炉盖冷却水用量对比 - 固定高度容器
                    SizedBox(
                      height: 400, // 固定高度 400px
                      child: TechPanel(
                        title: '炉盖冷却水用量对比',
                        accentColor: TechColors.glowCyan,
                        height: double.infinity,
                        child: _isLoadingSummary
                            ? const Center(child: CircularProgressIndicator())
                            : TechBarChart(
                                batchData: _getCoverWaterBatchData(),
                                accentColor: TechColors.glowCyan,
                                yAxisLabel: 'm³',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]
          // 非历史模式：2列3行布局 (折线图)
          // 顺序：电炉电流 | 料仓重量
          //      炉皮冷却水 | 炉盖冷却水
          //      除尘器振动 | 电炉功率（暂无数据）
          else ...[
            // Row 1: 电炉电流 | 料仓重量
            Expanded(
              child: Row(
                children: [
                  // 1. 电炉电流 (多选)
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
                              }
                            } else {
                              if (_currentSelects.length < 3) {
                                _currentSelects.add(item);
                              }
                            }
                          });
                          // 重新加载电流数据
                          _loadBatchData();
                        }, accentColor: TechColors.glowCyan),
                        const SizedBox(width: 8),
                        _buildExportButton(
                            '电炉电流',
                            _convertToChartData(_currentData.values.isNotEmpty
                                ? _currentData.values.first
                                : []),
                            accentColor: TechColors.glowCyan),
                      ],
                      child: _isLoadingData
                          ? const Center(child: CircularProgressIndicator())
                          : TechLineChart(
                              data: const [],
                              datas: _getCurrentChartData(),
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
                  // 2. 料仓重量/投料重量
                  Expanded(
                    child: TechPanel(
                      title: '料仓',
                      accentColor: TechColors.glowOrange,
                      height: double.infinity,
                      headerActions: [
                        _buildDropdown(_weightOptions, _weightSelect, (v) {
                          setState(() => _weightSelect = v!);
                          _loadBatchData();
                        }, accentColor: TechColors.glowOrange),
                        const SizedBox(width: 8),
                        _buildExportButton(
                            '料仓', _convertToChartData(_hopperData),
                            accentColor: TechColors.glowOrange),
                      ],
                      child: _isLoadingData
                          ? const Center(child: CircularProgressIndicator())
                          : TechLineChart(
                              data: _convertToChartData(_hopperData),
                              accentColor: TechColors.glowOrange,
                              yAxisLabel:
                                  _weightSelect.contains('重量') ? 'kg' : '',
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Row 2: 炉皮冷却水 | 炉盖冷却水
            Expanded(
              child: Row(
                children: [
                  // 3. 炉皮冷却水
                  Expanded(
                    child: TechPanel(
                      title: '炉皮冷却水',
                      accentColor: TechColors.glowBlue,
                      height: double.infinity,
                      headerActions: [
                        _buildDropdown(_coolingOptions, _shellCoolingSelect,
                            (v) {
                          setState(() => _shellCoolingSelect = v!);
                          _loadBatchData();
                        }, accentColor: TechColors.glowBlue),
                        const SizedBox(width: 8),
                        _buildExportButton(
                            '炉皮冷却水', _convertToChartData(_shellCoolingData),
                            accentColor: TechColors.glowBlue),
                      ],
                      child: _isLoadingData
                          ? const Center(child: CircularProgressIndicator())
                          : TechLineChart(
                              data: _convertToChartData(_shellCoolingData),
                              accentColor: TechColors.glowBlue,
                              yAxisLabel: _shellCoolingSelect.contains('压')
                                  ? 'MPa'
                                  : (_shellCoolingSelect.contains('用量')
                                      ? 'm³'
                                      : 'm³/h'),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 4. 炉盖冷却水
                  Expanded(
                    child: TechPanel(
                      title: '炉盖冷却水',
                      accentColor: TechColors.glowOrange,
                      height: double.infinity,
                      headerActions: [
                        _buildDropdown(_coolingOptions, _lidCoolingSelect, (v) {
                          setState(() => _lidCoolingSelect = v!);
                          _loadBatchData();
                        }, accentColor: TechColors.glowOrange),
                        const SizedBox(width: 8),
                        _buildExportButton(
                            '炉盖冷却水', _convertToChartData(_coverCoolingData),
                            accentColor: TechColors.glowOrange),
                      ],
                      child: _isLoadingData
                          ? const Center(child: CircularProgressIndicator())
                          : TechLineChart(
                              data: _convertToChartData(_coverCoolingData),
                              accentColor: TechColors.glowOrange,
                              yAxisLabel: _lidCoolingSelect.contains('压')
                                  ? 'MPa'
                                  : (_lidCoolingSelect.contains('用量')
                                      ? 'm³'
                                      : 'm³/h'),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Row 3: 除尘器振动 | 电炉功率 （暂无数据，显示空）
            Expanded(
              child: Row(
                children: [
                  // 5. 除尘器振动 (暂无数据)
                  Expanded(
                    child: TechPanel(
                      title: '除尘器振动',
                      accentColor: TechColors.glowBlue,
                      height: double.infinity,
                      headerActions: [
                        _buildDropdown(_dustOptions, _dustSelect,
                            (v) => setState(() => _dustSelect = v!),
                            accentColor: TechColors.glowBlue),
                      ],
                      child: const Center(
                        child: Text(
                          '暂无数据',
                          style: TextStyle(
                            color: TechColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 6. 电炉功率 (暂无数据)
                  Expanded(
                    child: TechPanel(
                      title: '电炉功率',
                      accentColor: TechColors.glowGreen,
                      height: double.infinity,
                      headerActions: [
                        _buildDropdown(_powerOptions, _powerSelect,
                            (v) => setState(() => _powerSelect = v!),
                            accentColor: TechColors.glowGreen),
                      ],
                      child: const Center(
                        child: Text(
                          '暂无数据',
                          style: TextStyle(
                            color: TechColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
