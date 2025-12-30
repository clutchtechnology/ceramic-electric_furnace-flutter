import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'tech_line_widgets.dart';

/// 科技风格曲线图组件
class TechLineChart extends StatefulWidget {
  final List<ChartDataPoint> data;
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
    this.accentColor = TechColors.glowCyan,
    this.yAxisLabel,
    this.xAxisLabel,
    this.minY,
    this.maxY,
    this.showGrid = true,
    this.showPoints = true,
  });

  @override
  State<TechLineChart> createState() => _TechLineChartState();
}

class _TechLineChartState extends State<TechLineChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Center(
        child: Text(
          '暂无数据',
          style: TextStyle(
            color: TechColors.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Y轴标签
          if (widget.yAxisLabel != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.yAxisLabel!,
                style: TextStyle(
                  color: TechColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          // 图表区域
          Expanded(
            child: MouseRegion(
              onExit: (_) => setState(() => _hoveredIndex = null),
              child: CustomPaint(
                painter: _ChartPainter(
                  data: widget.data,
                  accentColor: widget.accentColor,
                  minY: widget.minY,
                  maxY: widget.maxY,
                  showGrid: widget.showGrid,
                  showPoints: widget.showPoints,
                  hoveredIndex: _hoveredIndex,
                ),
                child: GestureDetector(
                  onTapDown: (details) => _handleTap(details),
                  onPanUpdate: (details) => _handlePan(details),
                ),
              ),
            ),
          ),
          // X轴标签
          if (widget.xAxisLabel != null)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                widget.xAxisLabel!,
                style: TextStyle(
                  color: TechColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          // 悬停提示
          if (_hoveredIndex != null && _hoveredIndex! < widget.data.length)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: widget.accentColor.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.data[_hoveredIndex!].label,
                    style: TextStyle(
                      color: TechColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.data[_hoveredIndex!].value.toStringAsFixed(2),
                    style: TextStyle(
                      color: widget.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto Mono',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _handleTap(TapDownDetails details) {
    _updateHoveredIndex(details.localPosition);
  }

  void _handlePan(DragUpdateDetails details) {
    _updateHoveredIndex(details.localPosition);
  }

  void _updateHoveredIndex(Offset position) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final padding = 16.0;
    final chartWidth = size.width - padding * 2;
    final relativeX = position.dx - padding;

    if (relativeX >= 0 && relativeX <= chartWidth) {
      final index = ((relativeX / chartWidth) * (widget.data.length - 1)).round();
      if (index >= 0 && index < widget.data.length) {
        setState(() => _hoveredIndex = index);
      }
    }
  }
}

/// 曲线图绘制器
class _ChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final Color accentColor;
  final double? minY;
  final double? maxY;
  final bool showGrid;
  final bool showPoints;
  final int? hoveredIndex;

  _ChartPainter({
    required this.data,
    required this.accentColor,
    this.minY,
    this.maxY,
    required this.showGrid,
    required this.showPoints,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double padding = 40;
    final double chartWidth = size.width - padding * 2;
    final double chartHeight = size.height - padding * 2;

    // 计算Y轴范围
    final values = data.map((d) => d.value).toList();
    final double dataMinY = minY ?? values.reduce(math.min);
    final double dataMaxY = maxY ?? values.reduce(math.max);
    final double yRange = dataMaxY - dataMinY;
    final double adjustedMinY = dataMinY - yRange * 0.1;
    final double adjustedMaxY = dataMaxY + yRange * 0.1;
    final double adjustedRange = adjustedMaxY - adjustedMinY;

    // 绘制网格
    if (showGrid) {
      _drawGrid(canvas, size, padding, chartWidth, chartHeight, adjustedMinY, adjustedMaxY);
    }

    // 绘制坐标轴
    _drawAxes(canvas, size, padding, chartWidth, chartHeight);

    // 绘制Y轴刻度
    _drawYAxisLabels(canvas, padding, chartHeight, adjustedMinY, adjustedMaxY);

    // 绘制曲线
    _drawLine(canvas, padding, chartWidth, chartHeight, adjustedMinY, adjustedRange);

    // 绘制数据点
    if (showPoints) {
      _drawPoints(canvas, padding, chartWidth, chartHeight, adjustedMinY, adjustedRange);
    }

    // 绘制悬停高亮
    if (hoveredIndex != null) {
      _drawHoverHighlight(canvas, padding, chartWidth, chartHeight, adjustedMinY, adjustedRange);
    }
  }

  void _drawGrid(Canvas canvas, Size size, double padding, double chartWidth, double chartHeight,
      double minY, double maxY) {
    final gridPaint = Paint()
      ..color = TechColors.gridLine
      ..strokeWidth = 0.5;

    // 横向网格线（5条）
    for (int i = 0; i <= 5; i++) {
      final y = padding + (chartHeight / 5) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(padding + chartWidth, y),
        gridPaint,
      );
    }

    // 纵向网格线（根据数据点数量）
    final gridCount = math.min(data.length - 1, 10);
    for (int i = 0; i <= gridCount; i++) {
      final x = padding + (chartWidth / gridCount) * i;
      canvas.drawLine(
        Offset(x, padding),
        Offset(x, padding + chartHeight),
        gridPaint,
      );
    }
  }

  void _drawAxes(Canvas canvas, Size size, double padding, double chartWidth, double chartHeight) {
    final axisPaint = Paint()
      ..color = TechColors.borderDark
      ..strokeWidth = 1.5;

    // Y轴
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, padding + chartHeight),
      axisPaint,
    );

    // X轴
    canvas.drawLine(
      Offset(padding, padding + chartHeight),
      Offset(padding + chartWidth, padding + chartHeight),
      axisPaint,
    );
  }

  void _drawYAxisLabels(Canvas canvas, double padding, double chartHeight, double minY, double maxY) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    for (int i = 0; i <= 5; i++) {
      final value = maxY - (maxY - minY) * (i / 5);
      final y = padding + (chartHeight / 5) * i;

      textPainter.text = TextSpan(
        text: value.toStringAsFixed(1),
        style: TextStyle(
          color: TechColors.textSecondary,
          fontSize: 10,
          fontFamily: 'Roboto Mono',
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(padding - textPainter.width - 8, y - textPainter.height / 2));
    }
  }

  void _drawLine(Canvas canvas, double padding, double chartWidth, double chartHeight,
      double minY, double range) {
    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.3)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = padding + (chartWidth / (data.length - 1)) * i;
      final normalizedValue = (data[i].value - minY) / range;
      final y = padding + chartHeight - (normalizedValue * chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  void _drawPoints(Canvas canvas, double padding, double chartWidth, double chartHeight,
      double minY, double range) {
    final pointPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final pointGlowPaint = Paint()
      ..color = accentColor.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < data.length; i++) {
      final x = padding + (chartWidth / (data.length - 1)) * i;
      final normalizedValue = (data[i].value - minY) / range;
      final y = padding + chartHeight - (normalizedValue * chartHeight);

      canvas.drawCircle(Offset(x, y), 5, pointGlowPaint);
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  void _drawHoverHighlight(Canvas canvas, double padding, double chartWidth, double chartHeight,
      double minY, double range) {
    if (hoveredIndex == null || hoveredIndex! >= data.length) return;

    final x = padding + (chartWidth / (data.length - 1)) * hoveredIndex!;
    final normalizedValue = (data[hoveredIndex!].value - minY) / range;
    final y = padding + chartHeight - (normalizedValue * chartHeight);

    // 绘制垂直辅助线
    final linePaint = Paint()
      ..color = accentColor.withOpacity(0.3)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x, padding), Offset(x, padding + chartHeight), linePaint);

    // 绘制高亮点
    final highlightPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final highlightGlowPaint = Paint()
      ..color = accentColor.withOpacity(0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(Offset(x, y), 8, highlightGlowPaint);
    canvas.drawCircle(Offset(x, y), 5, highlightPaint);
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.hoveredIndex != hoveredIndex;
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
