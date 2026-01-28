import 'package:flutter/material.dart';
import 'dart:async';
import '../common/tech_line_widgets.dart';
import '../../theme/app_theme.dart';

/// 冶炼控制按钮组件
class SmeltingControlButton extends StatefulWidget {
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
  State<SmeltingControlButton> createState() => _SmeltingControlButtonState();
}

class _SmeltingControlButtonState extends State<SmeltingControlButton> {
  Timer? _longPressTimer;
  double _pressProgress = 0.0;
  bool _isLongPressing = false;

  void _onStopPressStart() {
    setState(() {
      _isLongPressing = true;
      _pressProgress = 0.0;
    });

    _longPressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _pressProgress += 50 / 3000; // 3秒 = 3000ms
        if (_pressProgress >= 1.0) {
          _pressProgress = 1.0;
          _longPressTimer?.cancel();
          _longPressTimer = null;
          _isLongPressing = false;
          widget.onStop();
        }
      });
    });
  }

  void _onStopPressEnd() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    setState(() {
      _isLongPressing = false;
      _pressProgress = 0.0;
    });
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgMedium(context).withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isSmelting
              ? AppTheme.statusNormal(context)
              : AppTheme.glowOrange(context),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.isSmelting
                    ? AppTheme.statusNormal(context)
                    : AppTheme.glowOrange(context))
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
              color: (widget.isSmelting
                      ? AppTheme.statusNormal(context)
                      : AppTheme.glowOrange(context))
                  .withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isSmelting ? Icons.science : Icons.play_circle_filled,
              color: widget.isSmelting
                  ? AppTheme.statusNormal(context)
                  : AppTheme.glowOrange(context),
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          if (widget.isSmelting && widget.smeltingCode.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '冶炼运行中',
                  style: TextStyle(
                    color: AppTheme.statusNormal(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '轮次编码：${widget.smeltingCode}',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
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
                onTapDown: (_) => _onStopPressStart(),
                onTapUp: (_) => _onStopPressEnd(),
                onTapCancel: _onStopPressEnd,
                child: Container(
                  width: 150,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.statusAlarm(context),
                        AppTheme.statusAlarm(context).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.statusAlarm(context).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // 进度条背景
                      if (_isLongPressing)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _pressProgress,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                      // 按钮内容
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stop_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isLongPressing
                                  ? '长按停止 ${(3 - _pressProgress * 3).toStringAsFixed(1)}s'
                                  : '停止冶炼',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
                  widget.isSystemReady ? '系统就绪' : '系统未就绪',
                  style: TextStyle(
                    color: widget.isSystemReady
                        ? AppTheme.statusNormal(context)
                        : AppTheme.statusWarning(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isSystemReady ? '等待开始冶炼...' : '等待后端连接...',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            MouseRegion(
              cursor: widget.isSystemReady
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.forbidden,
              child: GestureDetector(
                onTap: widget.isSystemReady ? widget.onStart : null,
                child: Opacity(
                  opacity: widget.isSystemReady ? 1.0 : 0.5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.isSystemReady
                              ? AppTheme.statusNormal(context)
                              : AppTheme.statusOffline(context),
                          (widget.isSystemReady
                                  ? AppTheme.statusNormal(context)
                                  : AppTheme.statusOffline(context))
                              .withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: widget.isSystemReady
                          ? [
                              BoxShadow(
                                color: AppTheme.statusNormal(context)
                                    .withOpacity(0.3),
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
