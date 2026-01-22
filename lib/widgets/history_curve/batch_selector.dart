import 'package:flutter/material.dart';
import '../common/tech_line_widgets.dart';

/// 批次号选择器组件
/// 用于选择历史数据的批次号筛选
class BatchSelector extends StatefulWidget {
  final List<String> batchCodes;
  final String? selectedBatch;
  final Function(String?)? onBatchSelected;
  final Color accentColor;
  final bool isLoading;

  const BatchSelector({
    super.key,
    required this.batchCodes,
    this.selectedBatch,
    this.onBatchSelected,
    this.accentColor = TechColors.glowCyan,
    this.isLoading = false,
  });

  @override
  State<BatchSelector> createState() => _BatchSelectorState();
}

class _BatchSelectorState extends State<BatchSelector> {
  @override
  Widget build(BuildContext context) {
    final displayText = widget.selectedBatch ?? '全部批次';

    return PopupMenuButton<String?>(
      tooltip: '选择批次号',
      color: TechColors.bgMedium,
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: widget.accentColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      onSelected: (batch) {
        widget.onBatchSelected?.call(batch);
      },
      enabled: !widget.isLoading,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: TechColors.bgLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: widget.accentColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isLoading)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: widget.accentColor,
                ),
              )
            else
              const SizedBox.shrink(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 70),
              child: Text(
                displayText,
                style: const TextStyle(
                  color: TechColors.textPrimary,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: widget.accentColor, size: 16),
          ],
        ),
      ),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String?>>[];

        // 添加"全部批次"选项
        items.add(PopupMenuItem<String?>(
          value: null,
          height: 32,
          child: Row(
            children: [
              Icon(
                widget.selectedBatch == null
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 16,
                color: widget.selectedBatch == null
                    ? widget.accentColor
                    : TechColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '全部批次',
                style: TextStyle(
                  color: widget.selectedBatch == null
                      ? widget.accentColor
                      : TechColors.textSecondary,
                  fontSize: 12,
                  fontWeight: widget.selectedBatch == null
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ));

        // 添加分隔线
        if (widget.batchCodes.isNotEmpty) {
          items.add(const PopupMenuDivider(height: 1));
        }

        // 添加批次号选项
        for (final batch in widget.batchCodes) {
          final isSelected = batch == widget.selectedBatch;
          items.add(PopupMenuItem<String?>(
            value: batch,
            height: 32,
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 16,
                  color: isSelected
                      ? widget.accentColor
                      : TechColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    batch,
                    style: TextStyle(
                      color: isSelected
                          ? widget.accentColor
                          : TechColors.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ));
        }

        // 如果没有批次号，显示提示
        if (widget.batchCodes.isEmpty) {
          items.add(const PopupMenuItem<String?>(
            enabled: false,
            height: 32,
            child: Text(
              '暂无批次数据',
              style: TextStyle(
                color: TechColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ));
        }

        return items;
      },
    );
  }
}
