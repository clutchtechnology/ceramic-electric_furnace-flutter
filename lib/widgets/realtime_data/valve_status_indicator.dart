/// 蝶阀状态指示灯组件（只读，无交互）
/// 横向布局: [蝶阀名称] [开合度:XX%] [开] [关] [停] + 进度条
import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: TechColors.borderDark,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 上方行：蝶阀名称 + 开合度 + 状态按钮
          Row(
            children: [
              // 蝶阀名称
              Text(
                '蝶阀$valveId',
                style: const TextStyle(
                  color: TechColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              // 开合度标签
              Text(
                '开合度:',
                style: TextStyle(
                  color: TechColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              // 开合度数值
              SizedBox(
                width: 50,
                child: Text(
                  '${openPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto Mono',
                  ),
                ),
              ),
              const Spacer(),
              // 状态按钮组
              _buildStatusButtons(),
            ],
          ),
          const SizedBox(height: 6),
          // 下方：进度条
          _buildOpenPercentageBar(statusColor),
        ],
      ),
    );
  }

  /// 构建状态按钮组 (开/关/停)
  Widget _buildStatusButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusButton('开', '01', currentStatus == '01'),
        const SizedBox(width: 6),
        _buildStatusButton('关', '10', currentStatus == '10'),
        const SizedBox(width: 6),
        _buildStatusButton(
            '停', '00', currentStatus == '00' || currentStatus == '11'),
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
        buttonColor = TechColors.textSecondary;
      }
    } else {
      buttonColor = TechColors.textSecondary.withOpacity(0.4);
    }

    return Container(
      width: 32,
      height: 24,
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
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 构建开合度进度条
  Widget _buildOpenPercentageBar(Color statusColor) {
    return Stack(
      children: [
        // 背景条
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: TechColors.bgDark,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: TechColors.borderDark,
              width: 1,
            ),
          ),
        ),
        // 进度条
        FractionallySizedBox(
          widthFactor: openPercentage / 100.0,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: openPercentage >= 80
                    ? [TechColors.glowGreen, TechColors.glowCyan]
                    : openPercentage >= 50
                        ? [TechColors.glowOrange, TechColors.glowGreen]
                        : [TechColors.glowRed, TechColors.glowOrange],
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
