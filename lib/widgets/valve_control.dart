import 'package:flutter/material.dart';
import 'tech_line_widgets.dart';
import '../models/app_state.dart' show ValveStatus;

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
    final statusColor = status == ValveStatus.open
        ? openColor
        : status == ValveStatus.closed
            ? closeColor
            : stopColor;
    final statusText = status == ValveStatus.open
        ? '开启 ${openingDegree.toStringAsFixed(0)}%'
        : status == ValveStatus.closed
            ? '关闭'
            : '停止';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 上部分：编号（名称）+ 开关按钮
          Row(
            children: [
              // 状态指示灯
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 名称
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: TechColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // 开关按钮
              _buildControlButton(
                label: '开',
                isActive: status == ValveStatus.open,
                activeColor: openColor,
                onTap: () => onChanged?.call(ValveStatus.open),
              ),
              const SizedBox(width: 6),
              _buildControlButton(
                label: '关',
                isActive: status == ValveStatus.closed,
                activeColor: closeColor,
                onTap: () => onChanged?.call(ValveStatus.closed),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 下部分：状态 + 停止按钮
          Row(
            children: [
              const SizedBox(width: 18), // 对齐状态指示灯位置
              Expanded(
                child: Text(
                  '状态: $statusText',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
              ),
              _buildControlButton(
                label: '停',
                isActive: status == ValveStatus.stopped,
                activeColor: stopColor,
                onTap: () => onChanged?.call(ValveStatus.stopped),
              ),
            ],
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
    // 将蝶阀分成两列显示
    final rows = <Widget>[];
    for (int i = 0; i < valves.length; i += 2) {
      final leftValve = valves[i];
      final rightValve = i + 1 < valves.length ? valves[i + 1] : null;
      
      rows.add(
        Row(
          children: [
            Expanded(
              child: ValveControl(
                name: leftValve.name,
                status: leftValve.status,
                openingDegree: leftValve.openingDegree,
                onChanged: (status) {
                  onValveChanged?.call(leftValve.copyWith(
                    status: status,
                    openingDegree: status == ValveStatus.open ? leftValve.openingDegree : 0,
                  ));
                },
              ),
            ),
            if (rightValve != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ValveControl(
                  name: rightValve.name,
                  status: rightValve.status,
                  openingDegree: rightValve.openingDegree,
                  onChanged: (status) {
                    onValveChanged?.call(rightValve.copyWith(
                      status: status,
                      openingDegree: status == ValveStatus.open ? rightValve.openingDegree : 0,
                    ));
                  },
                ),
              ),
            ],
          ],
        ),
      );
      
      if (i + 2 < valves.length) {
        rows.add(const SizedBox(height: 10));
      }
    }
    
    return Column(
      children: rows,
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
