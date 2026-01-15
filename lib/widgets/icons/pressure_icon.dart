import 'package:flutter/material.dart';

/// 压力图标 (压力表)
class PressureIcon extends StatelessWidget {
  final double size;
  final Color color;

  const PressureIcon({
    super.key,
    this.size = 16,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PressurePainter(color: color),
    );
  }
}

class _PressurePainter extends CustomPainter {
  final Color color;

  _PressurePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scale = size.width / 1024;

    final path = Path();

    // 外圆环
    path.moveTo(512.7 * scale, 42.8 * scale);
    path.lineTo(512.7 * scale, 101.3 * scale);
    path.cubicTo(533.9 * scale, 101.3 * scale, 555.4 * scale, 103 * scale,
        576.5 * scale, 106.2 * scale);
    path.cubicTo(686.2 * scale, 123.1 * scale, 782.7 * scale, 181.7 * scale,
        848.3 * scale, 271.2 * scale);
    path.cubicTo(913.9 * scale, 360.7 * scale, 940.7 * scale, 470.4 * scale,
        923.8 * scale, 580.1 * scale);
    path.cubicTo(892.8 * scale, 780.9 * scale, 716.6 * scale, 932.3 * scale,
        513.8 * scale, 932.3 * scale);
    path.cubicTo(492.6 * scale, 932.3 * scale, 471.1 * scale, 930.6 * scale,
        449.9 * scale, 927.4 * scale);
    path.cubicTo(223.5 * scale, 892.4 * scale, 67.7 * scale, 679.9 * scale,
        102.6 * scale, 453.4 * scale);
    path.cubicTo(133.6 * scale, 252.6 * scale, 309.8 * scale, 101.2 * scale,
        512.6 * scale, 101.2 * scale);
    path.lineTo(512.7 * scale, 42.8 * scale);

    path.moveTo(512.6 * scale, 42.8 * scale);
    path.cubicTo(282.7 * scale, 42.8 * scale, 80.9 * scale, 210.4 * scale,
        44.8 * scale, 444.6 * scale);
    path.cubicTo(5 * scale, 703.2 * scale, 182.3 * scale, 945.2 * scale,
        441 * scale, 985.1 * scale);
    path.cubicTo(465.5 * scale, 988.9 * scale, 489.8 * scale, 990.7 * scale,
        513.8 * scale, 990.7 * scale);
    path.cubicTo(743.7 * scale, 990.7 * scale, 945.5 * scale, 823.1 * scale,
        981.6 * scale, 588.9 * scale);
    path.cubicTo(1021.5 * scale, 330.2 * scale, 844.1 * scale, 88.2 * scale,
        585.4 * scale, 48.3 * scale);
    path.cubicTo(560.9 * scale, 44.6 * scale, 536.6 * scale, 42.8 * scale,
        512.6 * scale, 42.8 * scale);
    path.close();

    // 内部弧线1
    path.moveTo(811.4 * scale, 571 * scale);
    path.cubicTo(810.3 * scale, 571 * scale, 809.2 * scale, 570.9 * scale,
        808.1 * scale, 570.8 * scale);
    path.cubicTo(792.1 * scale, 569 * scale, 780.5 * scale, 554.5 * scale,
        782.3 * scale, 538.5 * scale);
    path.cubicTo(798.2 * scale, 397.3 * scale, 700.5 * scale, 269.7 * scale,
        560 * scale, 248 * scale);
    path.cubicTo(524.8 * scale, 242.6 * scale, 500.2 * scale, 242.8 * scale,
        472.3 * scale, 248.9 * scale);
    path.cubicTo(456.5 * scale, 252.4 * scale, 441 * scale, 242.3 * scale,
        437.5 * scale, 226.6 * scale);
    path.cubicTo(434 * scale, 210.9 * scale, 444.1 * scale, 195.3 * scale,
        459.8 * scale, 191.8 * scale);
    path.cubicTo(494.9 * scale, 184.1 * scale, 526.5 * scale, 183.7 * scale,
        568.9 * scale, 190.2 * scale);
    path.cubicTo(740.6 * scale, 216.7 * scale, 859.9 * scale, 372.5 * scale,
        840.5 * scale, 545 * scale);
    path.cubicTo(838.8 * scale, 560 * scale, 826.1 * scale, 571 * scale,
        811.4 * scale, 571 * scale);
    path.close();

    // 内部弧线2
    path.moveTo(203.4 * scale, 558.1 * scale);
    path.cubicTo(187.2 * scale, 558.1 * scale, 174.1 * scale, 545 * scale,
        174.2 * scale, 528.8 * scale);
    path.cubicTo(174.2 * scale, 514 * scale, 175.3 * scale, 483.6 * scale,
        178.2 * scale, 465.1 * scale);
    path.cubicTo(191.4 * scale, 379.7 * scale, 229.1 * scale, 310.7 * scale,
        286.1 * scale, 258.1 * scale);
    path.cubicTo(297.5 * scale, 247.7 * scale, 314.8 * scale, 248.5 * scale,
        325.2 * scale, 259.9 * scale);
    path.cubicTo(335.6 * scale, 271.4 * scale, 334.8 * scale, 288.6 * scale,
        323.3 * scale, 299 * scale);
    path.cubicTo(276.5 * scale, 342.3 * scale, 246.3 * scale, 399.9 * scale,
        235.8 * scale, 472.1 * scale);
    path.cubicTo(233.6 * scale, 487.9 * scale, 232.7 * scale, 517.4 * scale,
        232.6 * scale, 529.5 * scale);
    path.cubicTo(232.5 * scale, 545.6 * scale, 219.5 * scale, 558.1 * scale,
        203.4 * scale, 558.1 * scale);
    path.close();

    // 指针/刻度相关元素
    path.moveTo(568.8 * scale, 502.1 * scale);
    path.lineTo(787.3 * scale, 374.6 * scale);
    path.cubicTo(800.8 * scale, 366.8 * scale, 818.2 * scale, 371.3 * scale,
        826.1 * scale, 384.8 * scale);
    path.cubicTo(833.9 * scale, 398.3 * scale, 829.4 * scale, 415.7 * scale,
        815.9 * scale, 423.6 * scale);
    path.lineTo(597.4 * scale, 551.1 * scale);
    path.cubicTo(589.8 * scale, 555.6 * scale, 581.5 * scale, 557.9 * scale,
        573.1 * scale, 558 * scale);
    path.cubicTo(539.8 * scale, 558.3 * scale, 513 * scale, 531.8 * scale,
        513.3 * scale, 498.5 * scale);
    path.cubicTo(513.5 * scale, 478.8 * scale, 523.3 * scale, 461.2 * scale,
        538.9 * scale, 451.9 * scale);
    path.cubicTo(554.5 * scale, 442.6 * scale, 573.6 * scale, 443.4 * scale,
        588.5 * scale, 454 * scale);
    path.cubicTo(594.9 * scale, 458.7 * scale, 600.1 * scale, 464.7 * scale,
        603.7 * scale, 471.5 * scale);
    path.cubicTo(607.3 * scale, 478.3 * scale, 609.2 * scale, 485.9 * scale,
        609.2 * scale, 493.5 * scale);
    path.cubicTo(609.2 * scale, 496.5 * scale, 589.7 * scale, 491.4 * scale,
        568.8 * scale, 502.1 * scale);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PressurePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
