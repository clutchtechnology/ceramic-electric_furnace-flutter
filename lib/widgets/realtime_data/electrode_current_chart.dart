import 'package:flutter/material.dart';
import '../common/tech_line_widgets.dart';

/// 电极电流柱状图组件
/// 显示三个电极的设定值和实际值对比
class ElectrodeCurrentChart extends StatelessWidget {
  final List<ElectrodeData> electrodes;

  const ElectrodeCurrentChart({
    super.key,
    required this.electrodes,
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
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      '电流 (A)',
                      style: TextStyle(
                        color: TechColors.textSecondary,
                        fontSize: 14,
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
                        _buildYAxis(maxValue),
                        const SizedBox(width: 4),
                        // 柱状图
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: electrodes
                                .map((electrode) =>
                                    _buildElectrodeGroup(electrode, maxValue))
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
                child: _buildLegend(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建Y轴刻度
  Widget _buildYAxis(double maxValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildYAxisLabel(maxValue.toStringAsFixed(0)),
              _buildYAxisLabel((maxValue * 0.75).toStringAsFixed(0)),
              _buildYAxisLabel((maxValue * 0.5).toStringAsFixed(0)),
              _buildYAxisLabel((maxValue * 0.25).toStringAsFixed(0)),
              _buildYAxisLabel('0'),
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

  Widget _buildYAxisLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: TechColors.textSecondary,
        fontSize: 12,
      ),
    );
  }

  /// 构建单个电极组（设定值+实际值）
  Widget _buildElectrodeGroup(ElectrodeData electrode, double maxValue) {
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
                      value: electrode.setValue,
                      maxValue: maxValue,
                      color: TechColors.glowCyan,
                      label: electrode.setValue.toStringAsFixed(0), // 整数显示 (5978 A)
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 实际值柱
                  SizedBox(
                    width: 25,
                    child: _buildBar(
                      value: electrode.actualValue,
                      maxValue: maxValue,
                      color: TechColors.glowOrange,
                      label: electrode.actualValue.toStringAsFixed(0), // 整数显示 (A)
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // X轴标签
            Text(
              electrode.name,
              style: const TextStyle(
                color: TechColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单个柱子
  Widget _buildBar({
    required double value,
    required double maxValue,
    required Color color,
    required String label,
  }) {
    final heightRatio = value / maxValue;

    return LayoutBuilder(
      builder: (context, constraints) {
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
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // 柱子
            Container(
              width: double.infinity,
              height: constraints.maxHeight * heightRatio,
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
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TechColors.bgDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: TechColors.borderDark,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem('设定值', TechColors.glowCyan),
          const SizedBox(width: 12),
          _buildLegendItem('实际值', TechColors.glowOrange),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
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
            fontSize: 14,
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
