import 'package:flutter/material.dart';
import '../common/tech_line_widgets.dart';
import '../../theme/app_theme.dart';

/// 电极电流柱状图组件
/// 显示三个电极的设定值和实际值对比
class ElectrodeCurrentChart extends StatelessWidget {
  final List<ElectrodeData> electrodes;
  final double deadzonePercent; // 死区百分比

  const ElectrodeCurrentChart({
    super.key,
    required this.electrodes,
    this.deadzonePercent = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // 找出最大值用于缩放
    double maxValue = 0;
    for (var electrode in electrodes) {
      if (electrode.setValue > maxValue) maxValue = electrode.setValue;
      if (electrode.actualValue > maxValue) maxValue = electrode.actualValue;
    }
    maxValue = maxValue * 1.2; // 留出20%的顶部空间

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(4),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Y轴标签
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '弧流 (A)',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 图表主体
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Y轴刻度
                        _buildYAxis(context, maxValue),
                        const SizedBox(width: 4),
                        // 柱状图
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: electrodes
                                .map((electrode) => _buildElectrodeGroup(
                                    context, electrode, maxValue))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
              // 图例 - 右上角
              Positioned(
                top: 0,
                right: 0,
                child: _buildLegend(context),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建Y轴刻度
  Widget _buildYAxis(BuildContext context, double maxValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildYAxisLabel(context, maxValue.toStringAsFixed(0)),
              _buildYAxisLabel(context, (maxValue * 0.75).toStringAsFixed(0)),
              _buildYAxisLabel(context, (maxValue * 0.5).toStringAsFixed(0)),
              _buildYAxisLabel(context, (maxValue * 0.25).toStringAsFixed(0)),
              _buildYAxisLabel(context, '0'),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // 占位符，与X轴标签高度对齐
        const SizedBox(
          height: 17, // 12 (fontSize) + 5 (额外空间)
          width: 40,
        ),
      ],
    );
  }

  Widget _buildYAxisLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        color: AppTheme.textSecondary(context),
        fontSize: 16,
      ),
    );
  }

  /// 构建单个电极组（设定值+实际值）
  Widget _buildElectrodeGroup(
      BuildContext context, ElectrodeData electrode, double maxValue) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 柱状图
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 设定值柱
                  SizedBox(
                    width: 25,
                    child: _buildBar(
                      context,
                      value: electrode.setValue,
                      maxValue: maxValue,
                      color: AppTheme.borderGlow(context),
                      label: electrode.setValue
                          .toStringAsFixed(0), // 整数显示 (5978 A)
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 实际值柱
                  SizedBox(
                    width: 25,
                    child: _buildBar(
                      context,
                      value: electrode.actualValue,
                      maxValue: maxValue,
                      color: AppTheme.glowOrange(context),
                      label:
                          electrode.actualValue.toStringAsFixed(0), // 整数显示 (A)
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // X轴标签
            Text(
              electrode.name,
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单个柱子
  Widget _buildBar(
    BuildContext context, {
    required double value,
    required double maxValue,
    required Color color,
    required String label,
  }) {
    // 保护: 避免 maxValue 为 0 或 NaN
    final safeMaxValue = (maxValue <= 0 || maxValue.isNaN) ? 1.0 : maxValue;
    // 保护: 限制 heightRatio 在 0.0 到 1.0 之间
    final heightRatio = (value / safeMaxValue).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 保护: 确保 maxHeight 有效
        final maxHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 200.0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 数值标签
            if (heightRatio > 0.1)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // 柱子
            Container(
              width: double.infinity,
              height:
                  (maxHeight * heightRatio).clamp(0.0, maxHeight), // 再次确保高度有效
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    color,
                    color.withOpacity(0.6),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
                border: Border.all(
                  color: color,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建图例
  Widget _buildLegend(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgDark(context).withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.borderDark(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 死区显示
          Text(
            '死区 ${deadzonePercent.toStringAsFixed(0)}%',
            style: TextStyle(
              color: AppTheme.glowGreen(context),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          _buildLegendItem(context, '设定值', AppTheme.borderGlow(context)),
          const SizedBox(width: 12),
          _buildLegendItem(context, '实际值', AppTheme.glowOrange(context)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 17,
          ),
        ),
      ],
    );
  }
}

/// 电极数据模型
class ElectrodeData {
  final String name;
  final double setValue; // 设定值
  final double actualValue; // 实际值

  const ElectrodeData({
    required this.name,
    required this.setValue,
    required this.actualValue,
  });
}
