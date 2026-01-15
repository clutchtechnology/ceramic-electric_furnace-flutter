import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../common/tech_line_widgets.dart';
import 'tech_chart.dart';

/// 科技风格柱状图组件
/// 用于历史轮次查询，对比不同批次的数据
class TechBarChart extends StatefulWidget {
  final Map<String, double> batchData; // 批次名称 -> 平均值
  final Color accentColor;
  final String? yAxisLabel;
  final bool showGrid;

  const TechBarChart({
    super.key,
    required this.batchData,
    this.accentColor = TechColors.glowCyan,
    this.yAxisLabel,
    this.showGrid = true,
  });

  @override
  State<TechBarChart> createState() => _TechBarChartState();
}

class _TechBarChartState extends State<TechBarChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.batchData.isEmpty) {
      return Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: TechColors.textSecondary, fontSize: 12),
        ),
      );
    }

    final entries = widget.batchData.entries.toList();
    final maxValue = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = entries.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    final effectiveMaxY = maxValue + range * 0.1;
    final effectiveMinY = (minValue > 0 ? 0.0 : minValue - range * 0.1);

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 8, top:0, bottom: 0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: effectiveMaxY,
          minY: effectiveMinY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => TechColors.bgLight.withOpacity(0.9),
              tooltipBorder: BorderSide(color: widget.accentColor.withOpacity(0.5)),
              tooltipRoundedRadius: 4,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final batch = entries[groupIndex].key;
                final value = entries[groupIndex].value;
                return BarTooltipItem(
                  '$batch\n${value.toStringAsFixed(2)}${widget.yAxisLabel ?? ''}',
                  const TextStyle(
                    color: TechColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    barTouchResponse == null ||
                    barTouchResponse.spot == null) {
                  _touchedIndex = null;
                  return;
                }
                _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
              });
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) return const SizedBox();
                  // 只显示批次编号的最后几位
                  final batch = entries[index].key;
                  final shortBatch = batch.length > 8 ? batch.substring(batch.length - 6) : batch;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      shortBatch,
                      style: TextStyle(
                        color: TechColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 58,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(
                      color: TechColors.textSecondary,
                      fontSize: 15,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: widget.showGrid,
            drawVerticalLine: false,
            horizontalInterval: (effectiveMaxY - effectiveMinY) / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: TechColors.borderGlow.withOpacity(0.15),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: TechColors.borderGlow.withOpacity(0.3)),
              bottom: BorderSide(color: TechColors.borderGlow.withOpacity(0.3)),
            ),
          ),
          barGroups: entries.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final isTouched = index == _touchedIndex;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data.value,
                  color: isTouched
                      ? widget.accentColor
                      : widget.accentColor.withOpacity(0.7),
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(3),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: effectiveMaxY,
                    color: TechColors.bgLight.withOpacity(0.1),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 分组柱状图组件 (用于电流面板的多电极对比)
class TechGroupedBarChart extends StatefulWidget {
  final Map<String, Map<String, double>> groupedData; // 批次 -> {电极1: 值, 电极2: 值, ...}
  final Color accentColor;
  final List<Color> colors;
  final String? yAxisLabel;
  final bool showGrid;

  const TechGroupedBarChart({
    super.key,
    required this.groupedData,
    this.accentColor = TechColors.glowCyan,
    this.colors = const [TechColors.glowCyan, TechColors.glowGreen, TechColors.glowOrange],
    this.yAxisLabel,
    this.showGrid = true,
  });

  @override
  State<TechGroupedBarChart> createState() => _TechGroupedBarChartState();
}

class _TechGroupedBarChartState extends State<TechGroupedBarChart> {
  int? _touchedGroupIndex;
  int? _touchedRodIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.groupedData.isEmpty) {
      return Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: TechColors.textSecondary, fontSize: 12),
        ),
      );
    }

    final batches = widget.groupedData.keys.toList();
    final electrodes = widget.groupedData.values.first.keys.toList();

    // 计算Y轴范围
    double maxValue = 0;
    double minValue = double.maxFinite;
    for (var batchData in widget.groupedData.values) {
      for (var value in batchData.values) {
        if (value > maxValue) maxValue = value;
        if (value < minValue) minValue = value;
      }
    }
    final range = maxValue - minValue;
    final effectiveMaxY = maxValue + range * 0.1;
    final effectiveMinY = (minValue > 0 ? 0.0 : minValue - range * 0.1);

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 8, top: 12, bottom: 4),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: effectiveMaxY,
          minY: effectiveMinY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => TechColors.bgLight.withOpacity(0.9),
              tooltipBorder: BorderSide(color: widget.accentColor.withOpacity(0.5)),
              tooltipRoundedRadius: 4,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final batch = batches[groupIndex];
                final electrode = electrodes[rodIndex];
                final value = widget.groupedData[batch]![electrode]!;
                return BarTooltipItem(
                  '$batch\n$electrode: ${value.toStringAsFixed(2)}${widget.yAxisLabel ?? ''}',
                  const TextStyle(
                    color: TechColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    barTouchResponse == null ||
                    barTouchResponse.spot == null) {
                  _touchedGroupIndex = null;
                  _touchedRodIndex = null;
                  return;
                }
                _touchedGroupIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                _touchedRodIndex = barTouchResponse.spot!.touchedRodDataIndex;
              });
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= batches.length) return const SizedBox();
                  final batch = batches[index];
                  final shortBatch = batch.length > 8 ? batch.substring(batch.length - 6) : batch;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      shortBatch,
                      style: TextStyle(
                        color: TechColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 58,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(
                      color: TechColors.textSecondary,
                      fontSize: 15,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: widget.showGrid,
            drawVerticalLine: false,
            horizontalInterval: (effectiveMaxY - effectiveMinY) / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: TechColors.borderGlow.withOpacity(0.15),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: TechColors.borderGlow.withOpacity(0.3)),
              bottom: BorderSide(color: TechColors.borderGlow.withOpacity(0.3)),
            ),
          ),
          barGroups: batches.asMap().entries.map((entry) {
            final groupIndex = entry.key;
            final batch = entry.value;
            final batchData = widget.groupedData[batch]!;

            return BarChartGroupData(
              x: groupIndex,
              barsSpace: 4,
              barRods: electrodes.asMap().entries.map((rodEntry) {
                final rodIndex = rodEntry.key;
                final electrode = rodEntry.value;
                final value = batchData[electrode]!;
                final isTouched =
                    groupIndex == _touchedGroupIndex && rodIndex == _touchedRodIndex;
                final color = widget.colors[rodIndex % widget.colors.length];

                return BarChartRodData(
                  toY: value,
                  color: isTouched ? color : color.withOpacity(0.7),
                  width: 12,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
