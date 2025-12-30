import 'package:flutter/material.dart';
import '../widgets/tech_line_widgets.dart';
import '../widgets/data_table.dart';
import '../widgets/time_range_selector.dart';
import '../widgets/export_button.dart';
import '../widgets/tech_dropdown.dart';
import '../widgets/refresh_button.dart';
import '../models/app_state.dart';

/// 数据查询页面
class DataQueryScreen extends StatefulWidget {
  const DataQueryScreen({super.key});

  @override
  State<DataQueryScreen> createState() => _DataQueryScreenState();
}

class _DataQueryScreenState extends State<DataQueryScreen> {
  late AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState.instance;
    _appState.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // 炉皮冷却水数据
  final List<List<String>> _coolingWaterData = [
    ['2025-12-30', '08:00:00', '2.5 m³/h', '0.35 MPa'],
    ['2025-12-30', '08:30:00', '2.6 m³/h', '0.36 MPa'],
    ['2025-12-30', '09:00:00', '2.4 m³/h', '0.34 MPa'],
    ['2025-12-30', '09:30:00', '2.5 m³/h', '0.35 MPa'],
    ['2025-12-30', '10:00:00', '2.7 m³/h', '0.37 MPa'],
    ['2025-12-30', '10:30:00', '2.5 m³/h', '0.35 MPa'],
    ['2025-12-30', '11:00:00', '2.6 m³/h', '0.36 MPa'],
    ['2025-12-30', '11:30:00', '2.4 m³/h', '0.34 MPa'],
  ];

  // 除尘排风口PM10数据
  final List<List<String>> _pm10Data = [
    ['2025-12-30', '08:00:00', '15.2 mg/m³'],
    ['2025-12-30', '08:30:00', '14.8 mg/m³'],
    ['2025-12-30', '09:00:00', '16.1 mg/m³'],
    ['2025-12-30', '09:30:00', '15.5 mg/m³'],
    ['2025-12-30', '10:00:00', '14.3 mg/m³'],
    ['2025-12-30', '10:30:00', '15.0 mg/m³'],
    ['2025-12-30', '11:00:00', '15.8 mg/m³'],
    ['2025-12-30', '11:30:00', '14.6 mg/m³'],
  ];

  // 蝶阀数据
  final List<List<String>> _valveData = [
    ['1', '2025-12-30', '08:00:00', '开启'],
    ['2', '2025-12-30', '08:15:00', '关闭'],
    ['3', '2025-12-30', '09:00:00', '开启'],
    ['1', '2025-12-30', '09:45:00', '调节至50%'],
    ['4', '2025-12-30', '10:00:00', '开启'],
    ['2', '2025-12-30', '10:30:00', '关闭'],
    ['3', '2025-12-30', '11:00:00', '开启'],
    ['1', '2025-12-30', '11:30:00', '调节至75%'],
  ];

  // 除尘风机能耗数据
  final List<List<String>> _fanEnergyData = [
    ['2025-12-30', '08:00:00', '125.6 kWh'],
    ['2025-12-30', '08:30:00', '128.3 kWh'],
    ['2025-12-30', '09:00:00', '130.1 kWh'],
    ['2025-12-30', '09:30:00', '127.8 kWh'],
    ['2025-12-30', '10:00:00', '132.5 kWh'],
    ['2025-12-30', '10:30:00', '129.0 kWh'],
    ['2025-12-30', '11:00:00', '126.4 kWh'],
    ['2025-12-30', '11:30:00', '131.2 kWh'],
  ];

  // 生成除尘风机能耗数据（按日统计）
  List<List<String>> _generateDailyFanEnergyData() {
    final year = DateTime.now().year;
    final daysInMonth = DateTime(year, _appState.selectedMonth + 1, 0).day;
    
    return List.generate(daysInMonth, (index) {
      final day = index + 1;
      final energy = (120 + (day * 3) % 20).toStringAsFixed(1);
      return [
        '$year-${_appState.selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
        '$energy kWh',
      ];
    });
  }

  // 生成除尘风机能耗数据（按月统计）
  List<List<String>> _generateMonthlyFanEnergyData() {
    return List.generate(12, (index) {
      final month = index + 1;
      final energy = (3500 + (month * 150) % 500).toStringAsFixed(1);
      return [
        '${_appState.selectedYear}-${month.toString().padLeft(2, '0')}',
        '$energy kWh',
      ];
    });
  }

  // 获取当前除尘风机能耗的表头
  List<String> _getFanEnergyColumns() {
    if (_appState.fanEnergyStatType == '日') {
      return ['日期', '能耗'];
    } else {
      return ['月份', '能耗'];
    }
  }

  // 获取当前除尘风机能耗的数据
  List<List<String>> _getFanEnergyData() {
    if (_appState.fanEnergyStatType == '日') {
      return _generateDailyFanEnergyData();
    } else {
      return _generateMonthlyFanEnergyData();
    }
  }

  /// 构建统计类型切换器（日/月）
  Widget _buildStatTypeSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatTypeButton('日'),
        const SizedBox(width: 4),
        _buildStatTypeButton('月'),
      ],
    );
  }

  /// 构建统计类型按钮
  Widget _buildStatTypeButton(String type) {
    final isSelected = _appState.fanEnergyStatType == type;
    return GestureDetector(
      onTap: () async {
        _appState.fanEnergyStatType = type;
        await _appState.saveDataQueryState();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? TechColors.glowBlue.withOpacity(0.2)
              : TechColors.glowBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? TechColors.glowBlue
                : TechColors.glowBlue.withOpacity(0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? TechColors.glowBlue : TechColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 构建月份/年份选择器
  Widget _buildPeriodSelector() {
    if (_appState.fanEnergyStatType == '日') {
      // 月份选择器
      return TechDropdown<int>(
        value: _appState.selectedMonth,
        width: 100,
        accentColor: TechColors.glowBlue,
        items: List.generate(12, (index) {
          final month = index + 1;
          return TechDropdownItem<int>(
            value: month,
            label: '$month月',
            icon: Icons.calendar_month,
          );
        }),
        onChanged: (value) async {
          if (value != null) {
            _appState.selectedMonth = value;
            await _appState.saveDataQueryState();
          }
        },
      );
    } else {
      // 年份选择器
      final currentYear = DateTime.now().year;
      return TechDropdown<int>(
        value: _appState.selectedYear,
        width: 100,
        accentColor: TechColors.glowBlue,
        items: List.generate(5, (index) {
          final year = currentYear - 2 + index;
          return TechDropdownItem<int>(
            value: year,
            label: '$year年',
            icon: Icons.calendar_today,
          );
        }),
        onChanged: (value) async {
          if (value != null) {
            _appState.selectedYear = value;
            await _appState.saveDataQueryState();
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TechColors.bgDeep,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // 左侧面板组
                Expanded(
                  child: Column(
                    children: [
                      // 炉皮冷却水
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          child: TechPanel(
                            title: '炉皮冷却水',
                            accentColor: TechColors.glowCyan,
                            height: double.infinity,
                            headerActions: [
                              TimeRangeSelector(
                                accentColor: TechColors.glowCyan,
                                onTimeRangeChanged: (start, end) async {
                                  _appState.coolingWaterQueryStart = start;
                                  _appState.coolingWaterQueryEnd = end;
                                  await _appState.saveDataQueryState();
                                  // TODO: 根据时间范围查询数据
                                },
                              ),
                              const SizedBox(width: 8),
                              RefreshButton(
                                accentColor: TechColors.glowCyan,
                                onPressed: () {
                                  setState(() {
                                    // 刷新数据
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              ExportButton(
                                accentColor: TechColors.glowCyan,
                                exportTitle: '炉皮冷却水',
                                columns: const ['日期', '时间', '流速', '水压'],
                                data: _coolingWaterData,
                              ),
                            ],
                            child: TechDataTable(
                              columns: const ['日期', '时间', '流速', '水压'],
                              data: _coolingWaterData,
                              accentColor: TechColors.glowCyan,
                            ),
                          ),
                        ),
                      ),
                      // 蝶阀
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: TechPanel(
                            title: '蝶阀',
                            accentColor: TechColors.glowGreen,
                            height: double.infinity,
                            headerActions: [
                              TimeRangeSelector(
                                accentColor: TechColors.glowGreen,
                                onTimeRangeChanged: (start, end) async {
                                  _appState.valveQueryStart = start;
                                  _appState.valveQueryEnd = end;
                                  await _appState.saveDataQueryState();
                                  // TODO: 根据时间范围查询数据
                                },
                              ),
                              const SizedBox(width: 8),
                              RefreshButton(
                                accentColor: TechColors.glowGreen,
                                onPressed: () {
                                  setState(() {
                                    // 刷新数据
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              ExportButton(
                                accentColor: TechColors.glowGreen,
                                exportTitle: '蝶阀',
                                columns: const ['号码', '日期', '时间', '操作'],
                                data: _valveData,
                              ),
                            ],
                            child: TechDataTable(
                              columns: const ['号码', '日期', '时间', '操作'],
                              data: _valveData,
                              accentColor: TechColors.glowGreen,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 右侧面板组
                Expanded(
                  child: Column(
                    children: [
                      // 除尘器排风口 PM10
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                          child: TechPanel(
                            title: '除尘器排风口 PM10',
                            accentColor: TechColors.glowOrange,
                            height: double.infinity,
                            headerActions: [
                              TimeRangeSelector(
                                accentColor: TechColors.glowOrange,
                                onTimeRangeChanged: (start, end) async {
                                  _appState.pm10QueryStart = start;
                                  _appState.pm10QueryEnd = end;
                                  await _appState.saveDataQueryState();
                                  // TODO: 根据时间范围查询数据
                                },
                              ),
                              const SizedBox(width: 8),
                              RefreshButton(
                                accentColor: TechColors.glowOrange,
                                onPressed: () {
                                  setState(() {
                                    // 刷新数据
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              ExportButton(
                                accentColor: TechColors.glowOrange,
                                exportTitle: '除尘器排风口PM10',
                                columns: const ['日期', '时间', '浓度'],
                                data: _pm10Data,
                              ),
                            ],
                            child: TechDataTable(
                              columns: const ['日期', '时间', '浓度'],
                              data: _pm10Data,
                              accentColor: TechColors.glowOrange,
                            ),
                          ),
                        ),
                      ),
                      // 除尘器风机能耗
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 0, 12, 12),
                          child: TechPanel(
                            title: '除尘器风机能耗',
                            accentColor: TechColors.glowBlue,
                            height: double.infinity,
                            headerActions: [
                              // 日/月切换器
                              _buildStatTypeSelector(),
                              const SizedBox(width: 8),
                              // 月份/年份选择器
                              _buildPeriodSelector(),
                              const SizedBox(width: 8),
                              ExportButton(
                                accentColor: TechColors.glowBlue,
                                exportTitle: '除尘器风机能耗_${_appState.fanEnergyStatType}统计',
                                columns: _getFanEnergyColumns(),
                                data: _getFanEnergyData(),
                              ),
                            ],
                            child: TechDataTable(
                              columns: _getFanEnergyColumns(),
                              data: _getFanEnergyData(),
                              accentColor: TechColors.glowBlue,
                            ),
                          ),
                        ),
                      ),
                    ],
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
