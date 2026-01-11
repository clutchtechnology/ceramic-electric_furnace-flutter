import 'package:flutter/material.dart';
import '../common/tech_line_widgets.dart';

/// 科技风格数据表格组件
class TechDataTable extends StatefulWidget {
  final List<String> columns;
  final List<List<String>> data;
  final Color accentColor;

  const TechDataTable({
    super.key,
    required this.columns,
    required this.data,
    this.accentColor = TechColors.glowCyan,
  });

  @override
  State<TechDataTable> createState() => _TechDataTableState();
}

class _TechDataTableState extends State<TechDataTable> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TechColors.bgDark.withOpacity(0.3),
        border: Border.all(
          color: widget.accentColor.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 表头
          Container(
            decoration: BoxDecoration(
              color: widget.accentColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
              border: Border(
                bottom: BorderSide(
                  color: widget.accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: widget.columns.map((column) {
                return Expanded(
                  child: Text(
                    column,
                    style: TextStyle(
                      color: widget.accentColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }).toList(),
            ),
          ),
          // 数据行
          Expanded(
            child: widget.data.isEmpty
                ? _buildEmptyState()
                : Scrollbar(
                    thumbVisibility: true,
                    controller: _scrollController,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.zero,
                      itemCount: widget.data.length,
                      itemBuilder: (context, index) {
                        return _buildDataRow(widget.data[index], index);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建数据行
  Widget _buildDataRow(List<String> rowData, int index) {
    return Container(
      decoration: BoxDecoration(
        color: index.isEven
            ? TechColors.bgDark.withOpacity(0.1)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: widget.accentColor.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: rowData.map((cellData) {
          return Expanded(
            child: Text(
              cellData,
              style: TextStyle(
                color: TechColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 空状态显示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: TechColors.textMuted.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            '暂无数据',
            style: TextStyle(
              color: TechColors.textMuted,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
