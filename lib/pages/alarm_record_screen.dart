import 'package:flutter/material.dart';
import '../widgets/tech_line_widgets.dart';
import '../widgets/data_table.dart';
import '../widgets/time_range_selector.dart';
import '../widgets/export_button.dart';
import '../widgets/refresh_button.dart';

/// 报警记录页面 - 六个监控面板
class AlarmRecordScreen extends StatefulWidget {
  const AlarmRecordScreen({super.key});

  @override
  State<AlarmRecordScreen> createState() => _AlarmRecordScreenState();
}

class _AlarmRecordScreenState extends State<AlarmRecordScreen> {
  // 各面板的时间范围
  DateTime _furnaceSkinStartTime = DateTime.now().subtract(const Duration(hours: 24));
  DateTime _furnaceSkinEndTime = DateTime.now();
  DateTime _coolingWaterStartTime = DateTime.now().subtract(const Duration(hours: 24));
  DateTime _coolingWaterEndTime = DateTime.now();
  DateTime _preFilterStartTime = DateTime.now().subtract(const Duration(hours: 24));
  DateTime _preFilterEndTime = DateTime.now();
  DateTime _dustInletStartTime = DateTime.now().subtract(const Duration(hours: 24));
  DateTime _dustInletEndTime = DateTime.now();
  DateTime _pm10StartTime = DateTime.now().subtract(const Duration(hours: 24));
  DateTime _pm10EndTime = DateTime.now();
  DateTime _fanVibrationStartTime = DateTime.now().subtract(const Duration(hours: 24));
  DateTime _fanVibrationEndTime = DateTime.now();

  // 电炉炉皮数据
  final List<List<String>> _furnaceSkinData = [
    ['2025-12-30', '08:00:00', 'A1', '650℃'],
    ['2025-12-30', '08:30:00', 'A2', '680℃'],
    ['2025-12-30', '09:00:00', 'A3', '720℃'],
    ['2025-12-30', '09:30:00', 'B1', '695℃'],
    ['2025-12-30', '10:00:00', 'B2', '710℃'],
    ['2025-12-30', '10:30:00', 'B3', '685℃'],
    ['2025-12-30', '11:00:00', 'C1', '730℃'],
    ['2025-12-30', '11:30:00', 'C2', '705℃'],
  ];

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

  // 前置过滤器数据
  final List<List<String>> _preFilterData = [
    ['2025-12-30', '08:00:00', '1.2 kPa'],
    ['2025-12-30', '08:30:00', '1.3 kPa'],
    ['2025-12-30', '09:00:00', '1.5 kPa'],
    ['2025-12-30', '09:30:00', '1.4 kPa'],
    ['2025-12-30', '10:00:00', '1.6 kPa'],
    ['2025-12-30', '10:30:00', '1.5 kPa'],
    ['2025-12-30', '11:00:00', '1.7 kPa'],
    ['2025-12-30', '11:30:00', '1.4 kPa'],
  ];

  // 除尘器入口数据
  final List<List<String>> _dustInletData = [
    ['2025-12-30', '08:00:00', '120℃'],
    ['2025-12-30', '08:30:00', '125℃'],
    ['2025-12-30', '09:00:00', '130℃'],
    ['2025-12-30', '09:30:00', '128℃'],
    ['2025-12-30', '10:00:00', '135℃'],
    ['2025-12-30', '10:30:00', '132℃'],
    ['2025-12-30', '11:00:00', '138℃'],
    ['2025-12-30', '11:30:00', '130℃'],
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

  // 除尘器风机振动数据
  final List<List<String>> _fanVibrationData = [
    ['2025-12-30', '08:00:00', '2.5 mm/s', '25 Hz'],
    ['2025-12-30', '08:30:00', '2.6 mm/s', '26 Hz'],
    ['2025-12-30', '09:00:00', '2.8 mm/s', '28 Hz'],
    ['2025-12-30', '09:30:00', '2.7 mm/s', '27 Hz'],
    ['2025-12-30', '10:00:00', '3.0 mm/s', '30 Hz'],
    ['2025-12-30', '10:30:00', '2.9 mm/s', '29 Hz'],
    ['2025-12-30', '11:00:00', '3.2 mm/s', '32 Hz'],
    ['2025-12-30', '11:30:00', '2.8 mm/s', '28 Hz'],
  ];

  // 六个面板的数据
  final List<_AlarmPanelData> _panels = [
    _AlarmPanelData(title: '电炉炉皮'),
    _AlarmPanelData(title: '炉皮冷却水'),
    _AlarmPanelData(title: '前置过滤器'),
    _AlarmPanelData(title: '除尘器入口'),
    _AlarmPanelData(title: '除尘器排风口PM10'),
    _AlarmPanelData(title: '除尘器风机振动'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TechColors.bgDeep,
      child: Column(
        children: [
          // 第一行：2个面板
          Expanded(
            child: Row(
              children: [
                // 电炉炉皮
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    child: TechPanel(
                      title: _panels[0].title,
                      accentColor: TechColors.glowCyan,
                      height: double.infinity,
                      headerActions: [
                        TimeRangeSelector(
                          accentColor: TechColors.glowCyan,
                          onTimeRangeChanged: (start, end) {
                            setState(() {
                              _furnaceSkinStartTime = start;
                              _furnaceSkinEndTime = end;
                            });
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
                          exportTitle: '电炉炉皮',
                          columns: const ['日期', '时间', '点位', '温度'],
                          data: _furnaceSkinData,
                        ),
                      ],
                      child: TechDataTable(
                        columns: const ['日期', '时间', '点位', '温度'],
                        data: _furnaceSkinData,
                        accentColor: TechColors.glowCyan,
                      ),
                    ),
                  ),
                ),
                // 炉皮冷却水
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                    child: TechPanel(
                      title: _panels[1].title,
                      accentColor: TechColors.glowBlue,
                      height: double.infinity,
                      headerActions: [
                        TimeRangeSelector(
                          accentColor: TechColors.glowBlue,
                          onTimeRangeChanged: (start, end) {
                            setState(() {
                              _coolingWaterStartTime = start;
                              _coolingWaterEndTime = end;
                            });
                            // TODO: 根据时间范围查询数据
                          },
                        ),
                        const SizedBox(width: 8),
                        RefreshButton(
                          accentColor: TechColors.glowBlue,
                          onPressed: () {
                            setState(() {
                              // 刷新数据
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ExportButton(
                          accentColor: TechColors.glowBlue,
                          exportTitle: '炉皮冷却水',
                          columns: const ['日期', '时间', '流速', '水压'],
                          data: _coolingWaterData,
                        ),
                      ],
                      child: TechDataTable(
                        columns: const ['日期', '时间', '流速', '水压'],
                        data: _coolingWaterData,
                        accentColor: TechColors.glowBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 第二行：2个面板
          Expanded(
            child: Row(
              children: [
                // 前置过滤器
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: TechPanel(
                      title: _panels[2].title,
                      accentColor: TechColors.glowGreen,
                      height: double.infinity,
                      headerActions: [
                        TimeRangeSelector(
                          accentColor: TechColors.glowGreen,
                          onTimeRangeChanged: (start, end) {
                            setState(() {
                              _preFilterStartTime = start;
                              _preFilterEndTime = end;
                            });
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
                          exportTitle: '前置过滤器',
                          columns: const ['日期', '时间', '压差'],
                          data: _preFilterData,
                        ),
                      ],
                      child: TechDataTable(
                        columns: const ['日期', '时间', '压差'],
                        data: _preFilterData,
                        accentColor: TechColors.glowGreen,
                      ),
                    ),
                  ),
                ),
                // 除尘器入口
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 0, 12, 12),
                    child: TechPanel(
                      title: _panels[3].title,
                      accentColor: TechColors.glowOrange,
                      height: double.infinity,
                      headerActions: [
                        TimeRangeSelector(
                          accentColor: TechColors.glowOrange,
                          onTimeRangeChanged: (start, end) {
                            setState(() {
                              _dustInletStartTime = start;
                              _dustInletEndTime = end;
                            });
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
                          exportTitle: '除尘器入口',
                          columns: const ['日期', '时间', '温度'],
                          data: _dustInletData,
                        ),
                      ],
                      child: TechDataTable(
                        columns: const ['日期', '时间', '温度'],
                        data: _dustInletData,
                        accentColor: TechColors.glowOrange,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 第三行：2个面板
          Expanded(
            child: Row(
              children: [
                // 除尘器排风口PM10
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: TechPanel(
                      title: _panels[4].title,
                      accentColor: TechColors.statusAlarm,
                      height: double.infinity,
                      headerActions: [
                        TimeRangeSelector(
                          accentColor: TechColors.statusAlarm,
                          onTimeRangeChanged: (start, end) {
                            setState(() {
                              _pm10StartTime = start;
                              _pm10EndTime = end;
                            });
                            // TODO: 根据时间范围查询数据
                          },
                        ),
                        const SizedBox(width: 8),
                        RefreshButton(
                          accentColor: TechColors.statusAlarm,
                          onPressed: () {
                            setState(() {
                              // 刷新数据
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ExportButton(
                          accentColor: TechColors.statusAlarm,
                          exportTitle: '除尘器排风口PM10',
                          columns: const ['日期', '时间', '浓度'],
                          data: _pm10Data,
                        ),
                      ],
                      child: TechDataTable(
                        columns: const ['日期', '时间', '浓度'],
                        data: _pm10Data,
                        accentColor: TechColors.statusAlarm,
                      ),
                    ),
                  ),
                ),
                // 除尘器风机振动
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 0, 12, 12),
                    child: TechPanel(
                      title: _panels[5].title,
                      accentColor: TechColors.statusWarning,
                      height: double.infinity,
                      headerActions: [
                        TimeRangeSelector(
                          accentColor: TechColors.statusWarning,
                          onTimeRangeChanged: (start, end) {
                            setState(() {
                              _fanVibrationStartTime = start;
                              _fanVibrationEndTime = end;
                            });
                            // TODO: 根据时间范围查询数据
                          },
                        ),
                        const SizedBox(width: 8),
                        RefreshButton(
                          accentColor: TechColors.statusWarning,
                          onPressed: () {
                            setState(() {
                              // 刷新数据
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ExportButton(
                          accentColor: TechColors.statusWarning,
                          exportTitle: '除尘器风机振动',
                          columns: const ['日期', '时间', '幅值', '频率'],
                          data: _fanVibrationData,
                        ),
                      ],
                      child: TechDataTable(
                        columns: const ['日期', '时间', '幅值', '频率'],
                        data: _fanVibrationData,
                        accentColor: TechColors.statusWarning,
                      ),
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

// ============================================================================
// 数据模型
// ============================================================================

class _AlarmPanelData {
  final String title;

  _AlarmPanelData({
    required this.title,
  });
}
