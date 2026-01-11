import 'package:flutter/material.dart';
import '../common/tech_line_widgets.dart';
import '../../models/app_state.dart' show ValveStatus;

/// 蝶阀控制组件
/// 显示蝶阀状态并支持远程开/停/关控制
class ValveControl extends StatelessWidget {
  final String name;
  final ValveStatus status;
  final double openingDegree;
  final ValueChanged<ValveStatus>? onChanged;
  final Color openColor;
  final Color closeColor;
  final Color stopColor;

  const ValveControl({
    super.key,
    required this.name,
    required this.status,
    this.openingDegree = 0,
    this.onChanged,
    this.openColor = TechColors.glowGreen,
    this.closeColor = TechColors.glowRed,
    this.stopColor = TechColors.statusWarning,
  });

  @override
  Widget build(BuildContext context) {
    // 逻辑判定
    final bool isStopped = status == ValveStatus.stopped;
    final bool isFullyClosed = openingDegree == 0;

    // 确定显示的颜色
    late final Color displayColor;

    if (!isStopped) {
      // 停没亮 -> 运行/调节中 -> 黄色
      displayColor = TechColors.statusWarning;
    } else {
      // 停亮了 -> 停止状态
      if (isFullyClosed) {
        // 开度为0 -> 关闭 -> 红色
        displayColor = closeColor;
      } else {
        // 开度不为0 -> 开启 -> 绿色
        displayColor = openColor;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 4), // Further reduced padding
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.3),
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
                style: const TextStyle(
                  color: TechColors.textPrimary,
                  fontSize: 15, // Slightly smaller text
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
                    fontSize: 15, // Slightly smaller text
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ),
              // 按钮组：开 | 关 | (空) | 停
              _buildControlButton(
                label: '开',
                isActive: status == ValveStatus.open,
                activeColor: openColor,
                onTap: () => onChanged?.call(ValveStatus.open),
              ),
              const SizedBox(width: 4),
              _buildControlButton(
                label: '关',
                isActive: status == ValveStatus.closed,
                activeColor: closeColor,
                onTap: () => onChanged?.call(ValveStatus.closed),
              ),
              const SizedBox(width: 12), // 空格
              _buildControlButton(
                label: '停',
                isActive: status == ValveStatus.stopped,
                activeColor: stopColor,
                onTap: () => onChanged?.call(ValveStatus.stopped),
              ),
            ],
          ),
          const SizedBox(height: 4), // Tighter gap
          // 第二行：进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4), // Slightly smaller radius
            child: LinearProgressIndicator(
              value: openingDegree / 100.0,
              backgroundColor: TechColors.bgDark,
              color: displayColor,
              minHeight: 8, // Reduced height (was 10/12)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.2) : TechColors.bgDark,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? activeColor : TechColors.borderDark,
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
            color: isActive ? activeColor : TechColors.textSecondary,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// 蝶阀控制面板
/// 显示多个蝶阀的状态和控制
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

/// 蝶阀数据模型
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
