import 'package:flutter/material.dart';
import '../widgets/tech_line_widgets.dart';

/// 数据查询页面
class DataQueryScreen extends StatefulWidget {
  const DataQueryScreen({super.key});

  @override
  State<DataQueryScreen> createState() => _DataQueryScreenState();
}

class _DataQueryScreenState extends State<DataQueryScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: TechColors.bgDeep,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // 左侧面板组
                Expanded(
                  child: Column(
                    children: [
                      // 炉皮冷却水
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          child: TechPanel(
                            title: '炉皮冷却水',
                            accentColor: TechColors.glowCyan,
                            child: _buildTablePlaceholder('炉皮冷却水数据表格'),
                          ),
                        ),
                      ),
                      // 蝶阀
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: TechPanel(
                            title: '蝶阀',
                            accentColor: TechColors.glowGreen,
                            child: _buildTablePlaceholder('蝶阀数据表格'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 右侧面板组
                Expanded(
                  child: Column(
                    children: [
                      // 除尘器排风口 PM10
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                          child: TechPanel(
                            title: '除尘器排风口 PM10',
                            accentColor: TechColors.glowOrange,
                            child: _buildTablePlaceholder('PM10数据表格'),
                          ),
                        ),
                      ),
                      // 除尘器风机能耗
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 0, 12, 12),
                          child: TechPanel(
                            title: '除尘器风机能耗',
                            accentColor: TechColors.glowBlue,
                            child: _buildTablePlaceholder('风机能耗数据表格'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 表格占位符
  Widget _buildTablePlaceholder(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart,
            size: 48,
            color: TechColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: TechColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '待添加具体内容',
            style: TextStyle(
              color: TechColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
