import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../common/tech_line_widgets.dart';
import '../../theme/app_theme.dart';

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
    Color? accentColor,
    this.yAxisLabel,
    this.xAxisLabel,
    this.minY,
    this.maxY,
    this.showGrid = true,
    this.showPoints = false, // 默认改为false，类似工控风格
  }) : accentColor = accentColor ?? const Color(0xFF00d4ff);

  @override
  State<TechLineChart> createState() => _TechLineChartState();
}

class _TechLineChartState extends State<TechLineChart> {
  /// 构建顶部坐标轴，显示单位标签（靠右）
  AxisTitles _buildTopAxisWithUnit(String? label) {
    if (label == null || label.isEmpty) {
      return const AxisTitles(sideTitles: SideTitles(showTitles: false));
    }

    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 20,
        getTitlesWidget: (value, meta) {
          // 只在最右侧显示单位标签
          if (value == meta.max) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
              child: Text(
                label,
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 准备显示的数据系列
    final List<List<ChartDataPoint>> seriesList = widget.datas ?? [widget.data];
    final List<Color> seriesColors = widget.colors ??
        List.generate(seriesList.length, (index) => widget.accentColor);

    // 检查是否有数据
    if (seriesList.isEmpty || seriesList.every((s) => s.isEmpty)) {
      // 无数据时显示空图表（仅坐标轴）
      return Padding(
        padding: const EdgeInsets.only(
          left: 8,
          right: 16,
          top: 24,
          bottom: 10,
        ),
        child: LineChart(
          LineChartData(
            lineTouchData: LineTouchData(enabled: false),
            gridData: FlGridData(
              show: widget.showGrid,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: AppTheme.gridLine(context).withOpacity(0.5),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: _buildTopAxisWithUnit(widget.yAxisLabel),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (value, meta) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 20,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(1),
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.right,
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: AppTheme.borderDark(context)),
            ),
            minX: 0,
            maxX: 10,
            minY: 0,
            maxY: 100,
            lineBarsData: [],
          ),
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
        left: 8, // 左边距，留给Y轴标签
        right: 16, // 右边距，留给X轴最后一个标签
        top: 24, // 顶部留给 Tooltip 空间
        bottom: 10,
      ),
      child: LineChart(
        LineChartData(
          // 触控交互配置
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  AppTheme.bgLight(context).withOpacity(0.9),
              tooltipBorder: BorderSide(color: AppTheme.borderGlow(context)),
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
                      fontSize: 12,
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
                color: AppTheme.gridLine(context).withOpacity(0.5),
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
            // 顶部显示单位标签（靠右）
            topTitles: _buildTopAxisWithUnit(widget.yAxisLabel),
            // 底部 X 轴
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: (seriesList.first.length / 6).ceilToDouble(), // 约6个标签
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < seriesList.first.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        seriesList.first[index].label,
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            // 左侧 Y 轴（移除 axisNameWidget，单位已在顶部显示）
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: (effectiveMaxY - effectiveMinY) / 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 10,
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
            border: Border.all(color: AppTheme.borderDark(context)),
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
