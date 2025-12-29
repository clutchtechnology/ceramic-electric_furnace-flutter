import 'package:flutter/material.dart';
import 'tech_line_widgets.dart';

/// 数据项模型
class DataItem {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color? iconColor;
  final double? threshold; // 阈值
  final bool isAboveThreshold; // 是否超过阈值报警

  const DataItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.iconColor,
    this.threshold,
    this.isAboveThreshold = false,
  });

  /// 检查当前值是否超过阈值
  bool get isAlarm {
    if (threshold == null) return false;
    final numValue = double.tryParse(value);
    if (numValue == null) return false;
    return isAboveThreshold ? numValue > threshold! : numValue < threshold!;
  }
}

/// 数据展示卡片组件
/// 用于在一个卡片中展示多行数据
class DataCard extends StatelessWidget {
  final List<DataItem> items;
  final EdgeInsets padding;

  const DataCard({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: TechColors.borderDark,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _buildRows(),
      ),
    );
  }

  List<Widget> _buildRows() {
    final List<Widget> widgets = [];
    for (int i = 0; i < items.length; i++) {
      widgets.add(_buildDataRow(items[i]));
      if (i < items.length - 1) {
        widgets.add(const Divider(height: 32, color: TechColors.borderDark));
      }
    }
    return widgets;
  }

  Widget _buildDataRow(DataItem item) {
    final color = item.iconColor ?? TechColors.glowCyan;
    final isAlarm = item.isAlarm;
    final valueColor = isAlarm ? TechColors.glowRed : TechColors.glowCyan;
    
    return Row(
      children: [
        // 报警图标闪烁效果
        if (isAlarm)
          _AlarmIcon(icon: item.icon, color: TechColors.glowRed)
        else
          Icon(
            item.icon,
            size: 18,
            color: color,
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  color: TechColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              // 显示阈值信息
              if (item.threshold != null)
                Text(
                  '阈值: ${item.threshold}${item.unit}',
                  style: TextStyle(
                    color: isAlarm ? TechColors.glowRed.withOpacity(0.8) : TechColors.textSecondary.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
        // 报警标签
        if (isAlarm)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: TechColors.glowRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: TechColors.glowRed),
            ),
            child: const Text(
              '报警',
              style: TextStyle(
                color: TechColors.glowRed,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Text(
          item.value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto Mono',
            shadows: [
              Shadow(
                color: valueColor.withOpacity(0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          item.unit,
          style: TextStyle(
            color: isAlarm ? TechColors.glowRed : TechColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

/// 报警图标动画组件
class _AlarmIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _AlarmIcon({required this.icon, required this.color});

  @override
  State<_AlarmIcon> createState() => _AlarmIconState();
}

class _AlarmIconState extends State<_AlarmIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Icon(
          widget.icon,
          size: 18,
          color: widget.color.withOpacity(_animation.value),
        );
      },
    );
  }
}
