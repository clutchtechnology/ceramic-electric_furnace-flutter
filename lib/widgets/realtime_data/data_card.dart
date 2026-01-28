import 'package:flutter/material.dart';
import '../common/tech_line_widgets.dart';
import '../common/blinking_text.dart';
import '../../theme/app_theme.dart';

/// 数据项模型
class DataItem {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color? iconColor;
  final double? threshold; // 阈值
  final bool isAboveThreshold; // 是否超过阈值报警
  final bool isMasked; // 是否添加遮罩层

  const DataItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.iconColor,
    this.threshold,
    this.isAboveThreshold = false,
    this.isMasked = false,
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
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.bgMedium(context).withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.borderDark(context),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _buildRows(context),
      ),
    );
  }

  List<Widget> _buildRows(BuildContext context) {
    final List<Widget> widgets = [];
    for (int i = 0; i < items.length; i++) {
      widgets.add(_buildDataRow(context, items[i]));
      if (i < items.length - 1) {
        widgets.add(Divider(height: 12, color: AppTheme.borderDark(context)));
      }
    }
    return widgets;
  }

  Widget _buildDataRow(BuildContext context, DataItem item) {
    final color = item.iconColor ?? AppTheme.borderGlow(context);
    final isAlarm = item.isAlarm;
    final valueColor =
        isAlarm ? AppTheme.glowRed(context) : AppTheme.borderGlow(context);

    // 1. 构建正常显示的内容
    Widget content = Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 3), // Reduced vertical padding
      child: Row(
        children: [
          // 报警图标闪烁效果
          if (isAlarm)
            _AlarmIcon(icon: item.icon, color: AppTheme.glowRed(context))
          else
            Icon(
              item.icon,
              size: 26,
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
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 18,
                  ),
                ),
                // 移除阈值文字显示，只保留报警颜色，以减小高度
              ],
            ),
          ),
          // 报警标签
          if (isAlarm)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppTheme.glowRed(context).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.glowRed(context)),
              ),
              child: Text(
                '报警',
                style: TextStyle(
                  color: AppTheme.glowRed(context),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          // 数值文本 - 报警时闪烁
          BlinkingText(
            text: item.value,
            isBlinking: isAlarm,
            style: TextStyle(
              color: valueColor,
              fontSize: 22,
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
          // 单位文本 - 报警时也闪烁
          BlinkingText(
            text: item.unit,
            isBlinking: isAlarm,
            style: TextStyle(
              color: isAlarm
                  ? AppTheme.glowRed(context)
                  : AppTheme.textSecondary(context),
              fontSize: 20,
            ),
          ),
        ],
      ),
    );

    // 2. 如果开启遮罩，叠加半透明层 (没有文字)
    if (item.isMasked) {
      return Stack(
        children: [
          content,
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6), // 60% 透明遮罩
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      );
    }

    return content;
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

class _AlarmIconState extends State<_AlarmIcon>
    with SingleTickerProviderStateMixin {
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

/// 电炉专用数据卡片组件（紧凑型）
/// 用于在电炉面板中展示带阈值的数据，行高更小
class FurnaceDataCard extends StatelessWidget {
  final List<DataItem> items;
  final EdgeInsets padding;

  const FurnaceDataCard({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.bgMedium(context).withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.borderDark(context),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _buildRows(context),
      ),
    );
  }

  List<Widget> _buildRows(BuildContext context) {
    final List<Widget> widgets = [];
    for (int i = 0; i < items.length; i++) {
      widgets.add(_buildDataRow(context, items[i]));
      if (i < items.length - 1) {
        widgets.add(Divider(height: 14, color: AppTheme.borderDark(context)));
      }
    }
    return widgets;
  }

  Widget _buildDataRow(BuildContext context, DataItem item) {
    final color = item.iconColor ?? AppTheme.borderGlow(context);
    final isAlarm = item.isAlarm;
    final valueColor =
        isAlarm ? AppTheme.glowRed(context) : AppTheme.borderGlow(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // 报警图标闪烁效果
          if (isAlarm)
            _AlarmIcon(icon: item.icon, color: AppTheme.glowRed(context))
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
                      color: isAlarm
                          ? TechColors.glowRed.withOpacity(0.8)
                          : TechColors.textSecondary.withOpacity(0.6),
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
      ),
    );
  }
}
