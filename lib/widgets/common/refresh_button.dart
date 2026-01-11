import 'package:flutter/material.dart';
import 'tech_line_widgets.dart';

/// 刷新按钮组件
/// 科技风格的刷新按钮，用于刷新表格或数据到当前状态
class RefreshButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Color accentColor;
  final String tooltip;
  final double size;

  const RefreshButton({
    super.key,
    this.onPressed,
    this.accentColor = TechColors.glowCyan,
    this.tooltip = '刷新数据',
    this.size = 28,
  });

  @override
  State<RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<RefreshButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  /// 处理刷新操作
  Future<void> _handleRefresh() async {
    // 触发旋转动画
    _rotationController.forward(from: 0.0);
    
    // 执行刷新回调
    if (widget.onPressed != null) {
      widget.onPressed!();
    }

    // 模拟刷新延迟
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      preferBelow: false,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: _handleRefresh,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _isPressed
                  ? widget.accentColor.withOpacity(0.3)
                  : _isHovered
                      ? widget.accentColor.withOpacity(0.15)
                      : widget.accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _isHovered
                    ? widget.accentColor
                    : widget.accentColor.withOpacity(0.4),
                width: _isHovered ? 1.5 : 1,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.accentColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: RotationTransition(
                turns: _rotationController,
                child: Icon(
                  Icons.refresh,
                  size: widget.size * 0.6,
                  color: _isHovered
                      ? widget.accentColor
                      : widget.accentColor.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
