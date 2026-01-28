import 'package:flutter/material.dart';
import '../common/tech_line_widgets.dart';
import '../../models/app_state.dart' show ValveStatus;
import '../../theme/app_theme.dart';

// 1: 蝶阀控制组件 - 显示蝶阀状态并支持远程开/停/关控制

/// 蝶阀控制组件
/// 显示蝶阀状态并支持远程开/停/关控制
class ValveControl extends StatelessWidget {
  final String name;
  final ValveStatus status;
  final double openingDegree;
  final ValueChanged<ValveStatus>? onChanged;
  final Color? openColor;
  final Color? closeColor;
  final Color? stopColor;

  const ValveControl({
    super.key,
    required this.name,
    required this.status,
    this.openingDegree = 0,
    this.onChanged,
    this.openColor,
    this.closeColor,
    this.stopColor,
  });

  @override
  Widget build(BuildContext context) {
    // 2: 为可选颜色参数提供默认值（使用 AppTheme）
    final effectiveOpenColor = openColor ?? AppTheme.glowGreen(context);
    final effectiveCloseColor = closeColor ?? AppTheme.glowRed(context);
    final effectiveStopColor = stopColor ?? AppTheme.statusWarning(context);

    // 3: 逻辑判定
    final bool isStopped = status == ValveStatus.stopped;
    final bool isFullyClosed = openingDegree == 0;

    // 4: 确定显示的颜色
    late final Color displayColor;

    if (!isStopped) {
      // 停没亮 -> 运行/调节中 -> 黄色
      displayColor = effectiveStopColor;
    } else {
      // 停亮了 -> 停止状态
      if (isFullyClosed) {
        // 开度为0 -> 关闭 -> 红色
        displayColor = effectiveCloseColor;
      } else {
        // 开度不为0 -> 开启 -> 绿色
        displayColor = effectiveOpenColor;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.bgMedium(context).withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: displayColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.max, // Modified to max to fill the expanded container
        mainAxisAlignment: MainAxisAlignment.center, // Center vertically
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：状态点 + 名称 + 开度 + 按钮组
          Row(
            children: [
              // 状态指示灯
              Container(
                width: 8, // Slightly smaller dot
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: displayColor,
                  boxShadow: [
                    BoxShadow(
                      color: displayColor.withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 名称
              Text(
                name,
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              // 开度百分比
              Expanded(
                child: Text(
                  '${openingDegree.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: displayColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ),
              // 5: 按钮组：开 | 关 | (空) | 停
              _buildControlButton(
                context,
                label: '开',
                isActive: status == ValveStatus.open,
                activeColor: effectiveOpenColor,
                onTap: () => onChanged?.call(ValveStatus.open),
              ),
              const SizedBox(width: 4),
              _buildControlButton(
                context,
                label: '关',
                isActive: status == ValveStatus.closed,
                activeColor: effectiveCloseColor,
                onTap: () => onChanged?.call(ValveStatus.closed),
              ),
              const SizedBox(width: 12), // 空格
              _buildControlButton(
                context,
                label: '停',
                isActive: status == ValveStatus.stopped,
                activeColor: effectiveStopColor,
                onTap: () => onChanged?.call(ValveStatus.stopped),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 第二行：进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4), // Slightly smaller radius
            child: LinearProgressIndicator(
              value: openingDegree / 100.0,
              backgroundColor: AppTheme.bgDark(context),
              color: displayColor,
              minHeight: 8, // Reduced height (was 10/12)
            ),
          ),
        ],
      ),
    );
  }

  // 6: 构建控制按钮
  Widget _buildControlButton(
    BuildContext context, {
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withOpacity(0.2)
              : AppTheme.bgDark(context),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? activeColor : AppTheme.borderDark(context),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : AppTheme.textSecondary(context),
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// 7: 蝶阀控制面板 - 显示多个蝶阀的状态和控制
class ValveControlPanel extends StatelessWidget {
  final List<ValveItem> valves;
  final ValueChanged<ValveItem>? onValveChanged;

  const ValveControlPanel({
    super.key,
    required this.valves,
    this.onValveChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 修改为单列布局 (一列多行)，这是为了让4个模块平分高度
    return Column(
      children: valves.asMap().entries.map((entry) {
        final index = entry.key;
        final valve = entry.value;
        return Expanded(
          child: Padding(
            padding:
                EdgeInsets.only(bottom: index < valves.length - 1 ? 8.0 : 0),
            child: ValveControl(
              name: valve.name,
              status: valve.status,
              openingDegree: valve.openingDegree,
              onChanged: (status) {
                onValveChanged?.call(valve.copyWith(
                  status: status,
                  openingDegree:
                      status == ValveStatus.open ? valve.openingDegree : 0,
                ));
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}

// 8: 蝶阀数据模型
class ValveItem {
  final String id;
  final String name;
  final ValveStatus status;
  final double openingDegree; // 开度百分比 (0-100)

  const ValveItem({
    required this.id,
    required this.name,
    required this.status,
    this.openingDegree = 0,
  });

  ValveItem copyWith({
    String? id,
    String? name,
    ValveStatus? status,
    double? openingDegree,
  }) {
    return ValveItem(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      openingDegree: openingDegree ?? this.openingDegree,
    );
  }
}
