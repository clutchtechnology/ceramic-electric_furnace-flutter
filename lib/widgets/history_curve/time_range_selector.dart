import 'package:flutter/material.dart';
import '../common/tech_line_widgets.dart';

/// 时间范围选择器组件
/// 包含起止时间选择功能
class TimeRangeSelector extends StatefulWidget {
  final Function(DateTime startTime, DateTime endTime)? onTimeRangeChanged;
  final Color accentColor;

  const TimeRangeSelector({
    super.key,
    this.onTimeRangeChanged,
    this.accentColor = TechColors.glowCyan,
  });

  @override
  State<TimeRangeSelector> createState() => _TimeRangeSelectorState();
}

class _TimeRangeSelectorState extends State<TimeRangeSelector> {
  DateTime _startTime = DateTime.now().subtract(const Duration(hours: 24));
  DateTime _endTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTimeButton(
          label: '起',
          time: _startTime,
          onTap: () => _selectTime(context, true),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '至',
            style: TextStyle(
              color: TechColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        _buildTimeButton(
          label: '止',
          time: _endTime,
          onTap: () => _selectTime(context, false),
        ),
      ],
    );
  }

  Widget _buildTimeButton({
    required String label,
    required DateTime time,
    required VoidCallback onTap,
  }) {
    final timeStr =
        '${time.month}月${time.day}日 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.accentColor.withOpacity(0.1),
          border: Border.all(
            color: widget.accentColor.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: widget.accentColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.access_time,
              size: 13,
              color: widget.accentColor.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              timeStr,
              style: TextStyle(
                color: TechColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final DateTime initialDate = isStartTime ? _startTime : _endTime;

    // 选择日期
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: widget.accentColor,
              onPrimary: Colors.white,
              surface: TechColors.bgDark,
              onSurface: TechColors.textPrimary,
            ),
            dialogBackgroundColor: TechColors.bgMedium,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    if (!context.mounted) return;

    // 选择时间
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: widget.accentColor,
              onPrimary: Colors.white,
              surface: TechColors.bgDark,
              onSurface: TechColors.textPrimary,
            ),
            dialogBackgroundColor: TechColors.bgMedium,
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    // 合并日期和时间
    final selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStartTime) {
        _startTime = selectedDateTime;
        // 确保起始时间不晚于结束时间
        if (_startTime.isAfter(_endTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      } else {
        _endTime = selectedDateTime;
        // 确保结束时间不早于起始时间
        if (_endTime.isBefore(_startTime)) {
          _startTime = _endTime.subtract(const Duration(hours: 1));
        }
      }
    });

    // 触发回调
    widget.onTimeRangeChanged?.call(_startTime, _endTime);
  }
}
