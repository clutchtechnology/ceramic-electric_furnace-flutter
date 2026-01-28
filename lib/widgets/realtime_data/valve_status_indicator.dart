/// 蝶阀状态指示灯组件（只读，无交互）
/// 上下布局: 上部[编号 | 百分比 | 状态] 下部[进度条+刻度]
import 'package:flutter/material.dart';
import 'dart:math';
import '../common/tech_line_widgets.dart';
import '../../tools/valve_calculator.dart';
import '../../theme/app_theme.dart';

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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.bgMedium(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderDark(context),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 上部分：编号 | 百分比 | 状态
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左侧：编号
                Expanded(
                  flex: 2,
                  child: Text(
                    '$valveId#',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
                // 中间：百分比
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      '${openPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: _getProgressColor(openPercentage),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto Mono',
                        shadows: [
                          Shadow(
                            color: _getProgressColor(openPercentage)
                                .withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 右侧：状态显示
                Expanded(
                  flex: 4,
                  child: _buildStatusButtons(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          // 下部分：进度条
          Expanded(
            flex: 2,
            child: _buildProgressBar(context),
          ),
        ],
      ),
    );
  }

  /// 根据百分比获取颜色
  Color _getProgressColor(double percentage) {
    if (percentage < 30) {
      return Color(0xFFFF3366); // 鲜红色
    } else if (percentage < 70) {
      return Color(0xFFFFAA00); // 鲜橙色
    } else {
      return Color(0xFF00FF88); // 鲜绿色
    }
  }

  /// 构建状态显示组 (关/停/开)
  Widget _buildStatusButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatusButton(context, '关', '10', currentStatus == '10'),
        const SizedBox(width: 3),
        _buildStatusButton(
            context, '停', '00', currentStatus == '00' || currentStatus == '11'),
        const SizedBox(width: 3),
        _buildStatusButton(context, '开', '01', currentStatus == '01'),
      ],
    );
  }

  /// 构建单个状态显示器
  Widget _buildStatusButton(
      BuildContext context, String label, String statusCode, bool isActive) {
    Color buttonColor;
    if (isActive) {
      if (statusCode == '01') {
        buttonColor = AppTheme.glowGreen(context);
      } else if (statusCode == '10') {
        buttonColor = AppTheme.glowRed(context);
      } else {
        buttonColor = AppTheme.borderGlow(context);
      }
    } else {
      buttonColor = AppTheme.textSecondary(context).withOpacity(0.3);
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? buttonColor.withOpacity(0.15)
              : AppTheme.bgDeep(context).withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive
                ? buttonColor
                : AppTheme.borderDark(context).withOpacity(0.5),
            width: isActive ? 1.5 : 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: buttonColor,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建进度条
  Widget _buildProgressBar(BuildContext context) {
    return Column(
      children: [
        // 进度条
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final progressWidth = barWidth * (openPercentage / 100);

              return Stack(
                children: [
                  // 背景轨道
                  Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark(context).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.borderDark(context),
                        width: 1,
                      ),
                    ),
                  ),
                  // 进度填充
                  Container(
                    width: progressWidth,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getProgressColor(openPercentage).withOpacity(0.6),
                          _getProgressColor(openPercentage),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _getProgressColor(openPercentage)
                              .withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  // 刻度标记
                  Positioned(
                    left: barWidth * 0.5 - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: AppTheme.textSecondary(context).withOpacity(0.5),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 3),
        // 刻度标签
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '全关',
              style: TextStyle(
                color: AppTheme.borderGlow(context),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '1/2',
              style: TextStyle(
                color: AppTheme.borderGlow(context),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '全开',
              style: TextStyle(
                color: AppTheme.borderGlow(context),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
