import 'package:flutter/material.dart';
import '../widgets/tech_line_widgets.dart';
import '../widgets/time_range_selector.dart';

/// 历史曲线页面
/// 包含四个面板：电炉能耗曲线、电炉炉皮温度曲线、前置过滤器压差曲线、除尘器入口温度
class HistoryCurveScreen extends StatefulWidget {
  const HistoryCurveScreen({super.key});

  @override
  State<HistoryCurveScreen> createState() => _HistoryCurveScreenState();
}

class _HistoryCurveScreenState extends State<HistoryCurveScreen> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final panelHeight = (screenHeight - 50 - 24) / 2; // 减去顶部导航栏(50)和间距(16+8)，然后除以2行

    return Container(
      color: TechColors.bgDeep,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // 上半部分：电炉能耗曲线 和 电炉炉皮温度曲线
          SizedBox(
            height: panelHeight,
            child: Row(
              children: [
                // 电炉能耗曲线
                Expanded(
                  child: TechPanel(
                    title: '电炉能耗曲线',
                    accentColor: TechColors.glowCyan,
                    height: panelHeight,
                    headerActions: [
                      TimeRangeSelector(
                        accentColor: TechColors.glowCyan,
                        onTimeRangeChanged: (start, end) {
                          // TODO: 处理时间范围变化
                          debugPrint('电炉能耗曲线时间范围: $start - $end');
                        },
                      ),
                    ],
                    child: Center(
                      child: Text(
                        '曲线图表区域',
                        style: TextStyle(
                          color: TechColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 电炉炉皮温度曲线
                Expanded(
                  child: TechPanel(
                    title: '电炉炉皮温度曲线',
                    accentColor: TechColors.glowOrange,
                    height: panelHeight,
                    headerActions: [
                      TimeRangeSelector(
                        accentColor: TechColors.glowOrange,
                        onTimeRangeChanged: (start, end) {
                          // TODO: 处理时间范围变化
                          debugPrint('电炉炉皮温度曲线时间范围: $start - $end');
                        },
                      ),
                    ],
                    child: Center(
                      child: Text(
                        '曲线图表区域',
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
          const SizedBox(height: 8),
          // 下半部分：前置过滤器压差曲线 和 除尘器入口温度
          SizedBox(
            height: panelHeight,
            child: Row(
              children: [
                // 前置过滤器压差曲线
                Expanded(
                  child: TechPanel(
                    title: '前置过滤器压差曲线',
                    accentColor: TechColors.glowGreen,
                    height: panelHeight,
                    headerActions: [
                      TimeRangeSelector(
                        accentColor: TechColors.glowGreen,
                        onTimeRangeChanged: (start, end) {
                          // TODO: 处理时间范围变化
                          debugPrint('前置过滤器压差曲线时间范围: $start - $end');
                        },
                      ),
                    ],
                    child: Center(
                      child: Text(
                        '曲线图表区域',
                        style: TextStyle(
                          color: TechColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 除尘器入口温度
                Expanded(
                  child: TechPanel(
                    title: '除尘器入口温度曲线',
                    accentColor: TechColors.glowBlue,
                    height: panelHeight,
                    headerActions: [
                      TimeRangeSelector(
                        accentColor: TechColors.glowBlue,
                        onTimeRangeChanged: (start, end) {
                          // TODO: 处理时间范围变化
                          debugPrint('除尘器入口温度曲线时间范围: $start - $end');
                        },
                      ),
                    ],
                    child: Center(
                      child: Text(
                        '曲线图表区域',
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
      ),
    );
  }
}
