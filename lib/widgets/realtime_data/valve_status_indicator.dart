/// 蝶阀状态指示灯组件（只读，无交互）
/// 横向布局: [编号] [仪表盘] [按钮组]
import 'package:flutter/material.dart';
import 'dart:math';
import '../common/tech_line_widgets.dart';
import '../../tools/valve_calculator.dart';

class ValveStatusIndicator extends StatelessWidget {
  final int valveId; // 蝶阀编号 (1-4)
  final String currentStatus; // 当前状态码 ("00", "01", "10", "11")
  final double openPercentage; // 开合度百分比 (0-100)

  const ValveStatusIndicator({
    super.key,
    required this.valveId,
    required this.currentStatus,
    required this.openPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(ValveCalculator.getStatusColor(currentStatus));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: TechColors.borderDark,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧：编号（左下角对齐）
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                '$valveId#',
                style: const TextStyle(
                  color: TechColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 中间：仪表盘
          Expanded(
            flex: 2,
            child: _buildGaugeDial(statusColor),
          ),
          const SizedBox(width: 8),
          // 右侧：按钮组
          Expanded(
            flex: 4,
            child: _buildStatusButtons(),
          ),
        ],
      ),
    );
  }

  /// 构建仪表盘部件
  Widget _buildGaugeDial(Color statusColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 进一步缩小仪表盘大小，确保不超出卡片
        final size = constraints.maxHeight * 0.85;
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _GaugePainter(
              percentage: openPercentage,
              color: statusColor,
            ),
          ),
        );
      },
    );
  }

  /// 构建状态按钮组 (关/停/开)
  Widget _buildStatusButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatusButton('关', '10', currentStatus == '10'),
        const SizedBox(width: 6),
        _buildStatusButton(
            '停', '00', currentStatus == '00' || currentStatus == '11'),
        const SizedBox(width: 6),
        _buildStatusButton('开', '01', currentStatus == '01'),
      ],
    );
  }

  /// 构建单个状态按钮
  Widget _buildStatusButton(String label, String statusCode, bool isActive) {
    Color buttonColor;
    if (isActive) {
      if (statusCode == '01') {
        buttonColor = TechColors.glowGreen;
      } else if (statusCode == '10') {
        buttonColor = TechColors.glowRed;
      } else {
        buttonColor = TechColors.glowCyan;
      }
    } else {
      buttonColor = TechColors.textSecondary.withOpacity(0.4);
    }

    return Expanded(
      child: Container(
        height: 35,
        decoration: BoxDecoration(
          color: isActive ? buttonColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? buttonColor : TechColors.borderDark,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: buttonColor,
              fontSize: 20,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// 仪表盘绘制器
class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  _GaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3.2;

    // 绘制外圆
    final circlePaint = Paint()
      ..color = TechColors.borderDark.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, circlePaint);

    // 绘制背景刻度弧（整个270度弧）- 使用更深的颜色
    final arcPaint = Paint()
      ..color = TechColors.bgDark.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    const startAngle = -3.14 * 0.75; // 从左下开始（全关位置）
    const sweepAngle = 3.14 * 1.5; // 扫过270度到右下（全开位置）

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 3),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // 绘制进度弧（从全关到当前指针位置）- 使用鲜艳的颜色
    if (percentage > 0) {
      final Color progressColor;
      if (percentage < 30) {
        progressColor = Color(0xFFFF3366); // 鲜红色
      } else if (percentage < 70) {
        progressColor = Color(0xFFFFAA00); // 鲜橙色
      } else {
        progressColor = Color(0xFF00FF88); // 鲜绿色
      }

      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 3),
        startAngle,
        sweepAngle * (percentage / 100),
        false,
        progressPaint,
      );
    }

    // 绘制指针
    final needleAngle = startAngle + sweepAngle * (percentage / 100);
    final needleEnd = Offset(
      center.dx + (radius - 10) * cos(needleAngle),
      center.dy + (radius - 10) * sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);

    // 绘制中心点
    final centerDotPaint = Paint()
      ..color = Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerDotPaint);

    // 绘制刻度标签（在仪表盘内部）
    _drawLabels(canvas, center, radius, size);

    // 在下半圆部分绘制百分比
    _drawPercentage(canvas, center, radius, size);
  }

  void _drawLabels(Canvas canvas, Offset center, double radius, Size size) {
    final textStyle = TextStyle(
      color: Color(0xFF00DDFF), // 鲜艳的青色
      fontSize: 13,
      fontWeight: FontWeight.bold,
    );

    // 左侧标签：全关（正左方，180度位置）
    final leftAngle = 3.14; // π，正左方
    final leftPos = Offset(
      center.dx + (radius + 18) * cos(leftAngle),
      center.dy + (radius + 18) * sin(leftAngle),
    );
    _drawText(canvas, '全关', textStyle, leftPos, align: TextAlign.center);

    // 顶部标签：1/2（正上方，270度位置）
    final topAngle = -3.14 / 2; // -π/2，正上方
    final topPos = Offset(
      center.dx + (radius + 15) * cos(topAngle),
      center.dy + (radius + 15) * sin(topAngle),
    );
    _drawText(canvas, '1/2', textStyle, topPos, align: TextAlign.center);

    // 右侧标签：全开（正右方，0度位置）
    final rightAngle = 0.0; // 0，正右方
    final rightPos = Offset(
      center.dx + (radius + 18) * cos(rightAngle),
      center.dy + (radius + 18) * sin(rightAngle),
    );
    _drawText(canvas, '全开', textStyle, rightPos, align: TextAlign.center);
  }

  void _drawPercentage(Canvas canvas, Offset center, double radius, Size size) {
    final textStyle = TextStyle(
      color: Color(0xFFFFDD00), // 鲜艳的黄色
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'Roboto Mono',
    );

    final percentageText = '${percentage.toStringAsFixed(0)}%';
    // 在下半圆位置（中心下方）
    final percentagePos = Offset(
      center.dx,
      center.dy + radius * 0.35,
    );
    _drawText(canvas, percentageText, textStyle, percentagePos,
        align: TextAlign.center);
  }

  void _drawText(Canvas canvas, String text, TextStyle style, Offset position,
      {TextAlign align = TextAlign.left}) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: align,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final offset = align == TextAlign.center
        ? Offset(position.dx - textPainter.width / 2, position.dy)
        : position;

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}
