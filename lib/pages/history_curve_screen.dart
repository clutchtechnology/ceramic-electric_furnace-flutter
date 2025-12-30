import 'package:flutter/material.dart';
import '../widgets/tech_line_widgets.dart';
import '../widgets/time_range_selector.dart';
import '../widgets/tech_chart.dart';
import '../widgets/refresh_button.dart';
import 'dart:math' as math;

/// 历史曲线页面
/// 包含四个面板：电炉能耗曲线、电炉炉皮温度曲线、前置过滤器压差曲线、除尘器入口温度
class HistoryCurveScreen extends StatefulWidget {
  const HistoryCurveScreen({super.key});

  @override
  State<HistoryCurveScreen> createState() => _HistoryCurveScreenState();
}

class _HistoryCurveScreenState extends State<HistoryCurveScreen> {
  // 生成模拟数据
  List<ChartDataPoint> _generateMockData(int count, double baseValue, double variance) {
    final random = math.Random();
    return List.generate(count, (index) {
      final value = baseValue + (random.nextDouble() - 0.5) * variance;
      final time = DateTime.now().subtract(Duration(hours: count - index));
      return ChartDataPoint(
        label: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        value: value,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final leftPanelHeight = (screenHeight - 50 - 32) / 3; // 左侧3个面板
    final rightPanelHeight = (screenHeight - 50 - 24) / 2; // 右侧2个面板

    return Container(
      color: TechColors.bgDeep,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // 左侧列：3个面板
          Expanded(
            child: Column(
              children: [
                // 电炉能耗曲线
                SizedBox(
                  height: leftPanelHeight,
                  child: TechPanel(
                    title: '电炉能耗曲线',
                    accentColor: TechColors.glowCyan,
                    height: leftPanelHeight,
                    headerActions: [
                      TimeRangeSelector(
                        accentColor: TechColors.glowCyan,
                        onTimeRangeChanged: (start, end) {
                          // TODO: 处理时间范围变化
                          debugPrint('电炉能耗曲线时间范围: $start - $end');
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
                    ],
                    child: TechLineChart(
                      data: _generateMockData(24, 320, 40),
                      accentColor: TechColors.glowCyan,
                      yAxisLabel: '能耗 (kWh)',
                      showGrid: true,
                      showPoints: true,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 前置过滤器压差曲线
                SizedBox(
                  height: leftPanelHeight,
                  child: TechPanel(
                    title: '前置过滤器压差曲线',
                    accentColor: TechColors.glowGreen,
                    height: leftPanelHeight,
                    headerActions: [
                      TimeRangeSelector(
                        accentColor: TechColors.glowGreen,
                        onTimeRangeChanged: (start, end) {
                          // TODO: 处理时间范围变化
                          debugPrint('前置过滤器压差曲线时间范围: $start - $end');
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
                    ],
                    child: TechLineChart(
                      data: _generateMockData(24, 125, 20),
                      accentColor: TechColors.glowGreen,
                      yAxisLabel: '压差 (Pa)',
                      showGrid: true,
                      showPoints: true,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 除尘器风机振动幅值
                SizedBox(
                  height: leftPanelHeight,
                  child: TechPanel(
                    title: '除尘器风机振动幅值曲线',
                    accentColor: TechColors.glowRed,
                    height: leftPanelHeight,
                    headerActions: [
                      TimeRangeSelector(
                        accentColor: TechColors.glowRed,
                        onTimeRangeChanged: (start, end) {
                          // TODO: 处理时间范围变化
                          debugPrint('除尘器风机振动幅值曲线时间范围: $start - $end');
                        },
                      ),
                      const SizedBox(width: 8),
                      RefreshButton(
                        accentColor: TechColors.glowRed,
                        onPressed: () {
                          setState(() {
                            // 刷新数据
                          });
                        },
                      ),
                    ],
                    child: TechLineChart(
                      data: _generateMockData(24, 2.8, 0.8),
                      accentColor: TechColors.glowRed,
                      yAxisLabel: '振动幅值 (mm/s)',
                      showGrid: true,
                      showPoints: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 右侧列：2个面板
          Expanded(
            child: Column(
              children: [
                // 电炉炉皮温度曲线
                SizedBox(
                  height: rightPanelHeight,
                  child: TechPanel(
                    title: '电炉炉皮温度曲线',
                    accentColor: TechColors.glowOrange,
                    height: rightPanelHeight,
                    headerActions: [
                      TimeRangeSelector(
                        accentColor: TechColors.glowOrange,
                        onTimeRangeChanged: (start, end) {
                          // TODO: 处理时间范围变化
                          debugPrint('电炉炉皮温度曲线时间范围: $start - $end');
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
                    ],
                    child: TechLineChart(
                      data: _generateMockData(24, 405, 30),
                      accentColor: TechColors.glowOrange,
                      yAxisLabel: '温度 (℃)',
                      showGrid: true,
                      showPoints: true,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 除尘器入口温度
                SizedBox(
                  height: rightPanelHeight,
                  child: TechPanel(
                    title: '除尘器入口温度曲线',
                    accentColor: TechColors.glowBlue,
                    height: rightPanelHeight,
                    headerActions: [
                      TimeRangeSelector(
                        accentColor: TechColors.glowBlue,
                        onTimeRangeChanged: (start, end) {
                          // TODO: 处理时间范围变化
                          debugPrint('除尘器入口温度曲线时间范围: $start - $end');
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
                    ],
                    child: TechLineChart(
                      data: _generateMockData(24, 85, 10),
                      accentColor: TechColors.glowBlue,
                      yAxisLabel: '温度 (℃)',
                      showGrid: true,
                      showPoints: true,
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
