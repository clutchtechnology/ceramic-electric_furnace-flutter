import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../common/tech_line_widgets.dart';

/// 科技风格曲线图组件
/// 使用 fl_chart 实现，支持单线或多线显示
class TechLineChart extends StatefulWidget {
  final List<ChartDataPoint> data; // 单线数据 (主数据)
  final List<List<ChartDataPoint>>? datas; // 多线数据 (可选，若提供则优先显示)
  final List<Color>? colors; // 多线颜色 (可选)

  final Color accentColor;
  final String? yAxisLabel;
  final String? xAxisLabel;
  final double? minY;
  final double? maxY;
  final bool showGrid;
  final bool showPoints;

  const TechLineChart({
    super.key,
    required this.data,
    this.datas,
    this.colors,
    this.accentColor = TechColors.glowCyan,
    this.yAxisLabel,
    this.xAxisLabel,
    this.minY,
    this.maxY,
    this.showGrid = true,
    this.showPoints = false, // 默认改为false，类似工控风格
  });

  @override
  State<TechLineChart> createState() => _TechLineChartState();
}

class _TechLineChartState extends State<TechLineChart> {
  @override
  Widget build(BuildContext context) {
    // 准备显示的数据系列
    final List<List<ChartDataPoint>> seriesList = widget.datas ?? [widget.data];
    final List<Color> seriesColors = widget.colors ??
        List.generate(seriesList.length, (index) => widget.accentColor);

    // 检查是否有数据
    if (seriesList.isEmpty || seriesList.every((s) => s.isEmpty)) {
      return Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: TechColors.textSecondary, fontSize: 12),
        ),
      );
    }

    // 计算 Y 轴范围
    double minVal = double.maxFinite;
    double maxVal = -double.maxFinite;
    for (var series in seriesList) {
      for (var p in series) {
        if (p.value < minVal) minVal = p.value;
        if (p.value > maxVal) maxVal = p.value;
      }
    }
    // 添加 buffer
    double range = maxVal - minVal;
    if (range == 0) range = 10;
    // 如果没有指定 minY/maxY，则自动计算，并上下留白 10%
    final effectiveMinY = widget.minY ?? (minVal - range * 0.1);
    final effectiveMaxY = widget.maxY ?? (maxVal + range * 0.1);

    return Padding(
      padding: const EdgeInsets.only(
        left: 4, // 左边距，留给Y轴标签
        right: 8, // 右边距，留给X轴最后一个标签
        top: 12, // 顶部留给 Tooltip 空间
        bottom: 4,
      ),
      child: LineChart(
        LineChartData(
          // 触控交互配置
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => TechColors.bgLight.withOpacity(0.9),
              tooltipBorder: const BorderSide(color: TechColors.borderGlow),
              tooltipRoundedRadius: 4,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final flSpot = barSpot;
                  final seriesIndex = barSpot.barIndex;
                  // 找到原始数据
                  if (seriesIndex >= seriesList.length) return null;

                  // 获取对应时间标签
                  final index = flSpot.x.toInt();
                  String timeLabel = '';
                  if (index >= 0 && index < seriesList[seriesIndex].length) {
                    timeLabel = seriesList[seriesIndex][index].label;
                  }

                  return LineTooltipItem(
                    '$timeLabel\n${flSpot.y.toStringAsFixed(2)}',
                    TextStyle(
                      color: seriesColors[seriesIndex % seriesColors.length],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),

          // 网格配置
          gridData: FlGridData(
            show: widget.showGrid,
            drawVerticalLine: false,
            horizontalInterval: (effectiveMaxY - effectiveMinY) / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: TechColors.gridLine.withOpacity(0.5),
                strokeWidth: 1,
              );
            },
          ),

          // 坐标轴标题配置
          titlesData: FlTitlesData(
            show: true,
            // 右侧不显示
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            // 顶部显示单位 (如果需要) 或不显示
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            // 底部 X 轴
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (seriesList.first.length / 6).ceilToDouble(), // 约6个标签
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < seriesList.first.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        seriesList.first[index].label,
                        style: const TextStyle(
                          color: TechColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            // 左侧 Y 轴
            leftTitles: AxisTitles(
              axisNameWidget: widget.yAxisLabel != null
                  ? Text(widget.yAxisLabel!,
                      style: const TextStyle(
                          color: TechColors.textSecondary, fontSize: 15))
                  : null,
              axisNameSize: 20,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: (effectiveMaxY - effectiveMinY) / 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(
                      color: TechColors.textSecondary,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.right,
                  );
                },
              ),
            ),
          ),

          // 边框配置
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: TechColors.borderDark),
          ),

          // 范围配置
          minX: 0,
          maxX: (seriesList.first.length - 1).toDouble(),
          minY: effectiveMinY,
          maxY: effectiveMaxY,

          // 线条数据
          lineBarsData: List.generate(seriesList.length, (i) {
            final series = seriesList[i];
            final color = seriesColors[i % seriesColors.length];
            return LineChartBarData(
              spots: List.generate(series.length, (index) {
                return FlSpot(index.toDouble(), series[index].value);
              }),
              isCurved: true, // 曲线平滑
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: widget.showPoints), // 根据配置显示点
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(0.3),
                    color.withOpacity(0.0),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// 图表数据点
class ChartDataPoint {
  final String label;
  final double value;

  const ChartDataPoint({
    required this.label,
    required this.value,
  });
}
