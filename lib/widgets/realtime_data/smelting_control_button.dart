import 'package:flutter/material.dart';
import '../common/tech_line_widgets.dart';

/// 冶炼控制按钮组件
class SmeltingControlButton extends StatelessWidget {
  final bool isSmelting;
  final String smeltingCode;
  final VoidCallback onStart;
  final VoidCallback onStop;

  /// 系统是否就绪 (后端+PLC都正常)
  final bool isSystemReady;

  const SmeltingControlButton({
    super.key,
    required this.isSmelting,
    required this.smeltingCode,
    required this.onStart,
    required this.onStop,
    this.isSystemReady = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSmelting ? TechColors.statusNormal : TechColors.glowOrange,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (isSmelting ? TechColors.statusNormal : TechColors.glowOrange)
                    .withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  (isSmelting ? TechColors.statusNormal : TechColors.glowOrange)
                      .withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSmelting ? Icons.science : Icons.play_circle_filled,
              color:
                  isSmelting ? TechColors.statusNormal : TechColors.glowOrange,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          if (isSmelting && smeltingCode.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '冶炼运行中',
                  style: TextStyle(
                    color: TechColors.statusNormal,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '轮次编码：$smeltingCode',
                  style: TextStyle(
                    color: TechColors.textSecondary,
                    fontSize: 15,
                    fontFamily: 'Roboto Mono',
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onStop,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        TechColors.statusAlarm,
                        TechColors.statusAlarm.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: TechColors.statusAlarm.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stop_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '停止冶炼',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSystemReady ? '系统就绪' : '系统未就绪',
                  style: TextStyle(
                    color: isSystemReady
                        ? TechColors.statusNormal
                        : TechColors.statusWarning,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSystemReady ? '等待开始冶炼...' : '等待后端连接...',
                  style: TextStyle(
                    color: TechColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            MouseRegion(
              cursor: isSystemReady
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.forbidden,
              child: GestureDetector(
                onTap: isSystemReady ? onStart : null,
                child: Opacity(
                  opacity: isSystemReady ? 1.0 : 0.5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isSystemReady
                              ? TechColors.statusNormal
                              : TechColors.statusOffline,
                          (isSystemReady
                                  ? TechColors.statusNormal
                                  : TechColors.statusOffline)
                              .withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSystemReady
                          ? [
                              BoxShadow(
                                color: TechColors.statusNormal.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '开始冶炼',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
