import 'package:flutter/material.dart';
import 'tech_line_widgets.dart';

/// 蝶阀控制组件
/// 显示蝶阀状态并支持远程开/关控制
class ValveControl extends StatelessWidget {
  final String name;
  final bool isOpen;
  final ValueChanged<bool>? onChanged;
  final Color openColor;
  final Color closeColor;

  const ValveControl({
    super.key,
    required this.name,
    required this.isOpen,
    this.onChanged,
    this.openColor = TechColors.glowGreen,
    this.closeColor = TechColors.glowRed,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isOpen ? openColor : closeColor;
    final statusText = isOpen ? '开启' : '关闭';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          // 状态指示灯
          Container(
            width: 12,
            height: 12,
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
          const SizedBox(width: 12),
          // 名称
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: TechColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '状态: $statusText',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // 控制按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildControlButton(
                label: '开',
                isActive: isOpen,
                activeColor: openColor,
                onTap: () => onChanged?.call(true),
              ),
              const SizedBox(width: 8),
              _buildControlButton(
                label: '关',
                isActive: !isOpen,
                activeColor: closeColor,
                onTap: () => onChanged?.call(false),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
    return Column(
      children: [
        for (int i = 0; i < valves.length; i++) ...[
          ValveControl(
            name: valves[i].name,
            isOpen: valves[i].isOpen,
            onChanged: (value) {
              onValveChanged?.call(valves[i].copyWith(isOpen: value));
            },
          ),
          if (i < valves.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// 蝶阀数据模型
class ValveItem {
  final String id;
  final String name;
  final bool isOpen;

  const ValveItem({
    required this.id,
    required this.name,
    required this.isOpen,
  });

  ValveItem copyWith({
    String? id,
    String? name,
    bool? isOpen,
  }) {
    return ValveItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}
