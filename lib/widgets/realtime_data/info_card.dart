import 'package:flutter/material.dart';
import '../common/tech_line_widgets.dart';
import '../../theme/app_theme.dart';

/// 信息卡片组件
/// 用于显示单个或多个数据项的卡片
class InfoCard extends StatelessWidget {
  final List<InfoCardItem> items;
  final Color accentColor;

  const InfoCard({
    super.key,
    required this.items,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgMedium(context).withOpacity(0.95),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accentColor.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: items.length == 1 && items[0].layout == InfoCardLayout.vertical
          ? _buildVerticalLayout(context, items[0])
          : _buildHorizontalLayout(context, items),
    );
  }

  /// 垂直布局（用于单个数据项，如温度、PM10）
  Widget _buildVerticalLayout(BuildContext context, InfoCardItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          item.icon,
          color: item.iconColor ?? accentColor,
          size: 28,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.label,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  item.value,
                  style: TextStyle(
                    color: item.valueColor ?? accentColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto Mono',
                    shadows: [
                      Shadow(
                        color:
                            (item.valueColor ?? accentColor).withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  item.unit,
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (item.showWarning) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.warning,
            color: AppTheme.statusAlarm(context),
            size: 24,
          ),
        ],
      ],
    );
  }

  /// 水平布局（用于多行数据项，如功率+能耗）
  Widget _buildHorizontalLayout(
      BuildContext context, List<InfoCardItem> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                items[i].icon,
                color: items[i].iconColor ?? accentColor,
                size: 28,
              ),
              const SizedBox(width: 6),
              Text(
                items[i].label,
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                items[i].value,
                style: TextStyle(
                  color: items[i].valueColor ?? accentColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto Mono',
                  shadows: [
                    Shadow(
                      color:
                          (items[i].valueColor ?? accentColor).withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                items[i].unit,
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 15,
                ),
              ),
            ],
          ),
          if (i < items.length - 1) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: AppTheme.borderDark(context)),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

/// 信息卡片数据项
class InfoCardItem {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color? iconColor;
  final Color? valueColor;
  final bool showWarning;
  final InfoCardLayout layout;

  const InfoCardItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.iconColor,
    this.valueColor,
    this.showWarning = false,
    this.layout = InfoCardLayout.vertical,
  });
}

/// 信息卡片布局类型
enum InfoCardLayout {
  vertical, // 垂直布局（图标在左，标签+数值在右）
  horizontal, // 水平布局（图标+标签+数值在一行）
}
