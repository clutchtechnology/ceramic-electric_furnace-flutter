import 'package:flutter/material.dart';
import 'tech_line_widgets.dart';

/// 科技风格下拉选择器组件
class TechDropdown<T> extends StatefulWidget {
  final T value;
  final List<TechDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final Color accentColor;
  final String? hint;
  final double width;

  const TechDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.accentColor = TechColors.glowCyan,
    this.hint,
    this.width = 150,
  });

  @override
  State<TechDropdown<T>> createState() => _TechDropdownState<T>();
}

class _TechDropdownState<T> extends State<TechDropdown<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        width: widget.width,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: _isHovered
              ? widget.accentColor.withOpacity(0.15)
              : widget.accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _isHovered
                ? widget.accentColor.withOpacity(0.6)
                : widget.accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: widget.value,
            hint: widget.hint != null
                ? Text(
                    widget.hint!,
                    style: TextStyle(
                      color: TechColors.textSecondary,
                      fontSize: 12,
                    ),
                  )
                : null,
            icon: Icon(
              Icons.arrow_drop_down,
              color: widget.accentColor,
              size: 20,
            ),
            style: TextStyle(
              color: widget.accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: TechColors.bgMedium,
            isExpanded: true,
            items: widget.items.map((item) {
              return DropdownMenuItem<T>(
                value: item.value,
                child: Row(
                  children: [
                    if (item.icon != null) ...[
                      Icon(item.icon, size: 16, color: widget.accentColor),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: TechColors.textPrimary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}

/// 下拉选项数据类
class TechDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const TechDropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}
