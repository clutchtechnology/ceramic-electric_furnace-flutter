import 'package:flutter/material.dart';
import '../common/tech_line_widgets.dart';
import '../../theme/app_theme.dart';

/// 快速时间选择器组件
/// 提供预设的时间范围快速选择
class QuickTimeSelector extends StatefulWidget {
  final Function(Duration duration)? onQuickTimeSelected;
  final Color accentColor;

  const QuickTimeSelector({
    super.key,
    this.onQuickTimeSelected,
    this.accentColor = TechColors.glowCyan,
  });

  @override
  State<QuickTimeSelector> createState() => _QuickTimeSelectorState();
}

class _QuickTimeSelectorState extends State<QuickTimeSelector> {
  String _selectedLabel = '24小时';

  // 快速选择选项
  static const List<Map<String, dynamic>> _quickOptions = [
    {'label': '12小时', 'hours': 12},
    {'label': '24小时', 'hours': 24},
    {'label': '3天', 'hours': 72},
    {'label': '7天', 'hours': 168},
    {'label': '15天', 'hours': 360},
    {'label': '30天', 'hours': 720},
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Map<String, dynamic>>(
      tooltip: '快速选择时间范围',
      color: AppTheme.bgMedium(context),
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: widget.accentColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      onSelected: (option) {
        setState(() {
          _selectedLabel = option['label'];
        });
        widget.onQuickTimeSelected?.call(Duration(hours: option['hours']));
      },
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.bgLight(context).withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: widget.accentColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedLabel,
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 11,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: widget.accentColor, size: 16),
          ],
        ),
      ),
      itemBuilder: (context) {
        return _quickOptions.map((option) {
          final isSelected = option['label'] == _selectedLabel;
          return PopupMenuItem<Map<String, dynamic>>(
            value: option,
            height: 32,
            child: Text(
              option['label'],
              style: TextStyle(
                color: isSelected
                    ? widget.accentColor
                    : AppTheme.textSecondary(context),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList();
      },
    );
  }
}
