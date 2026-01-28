import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// ============================================================================
/// 主题切换组件 (Theme Switch Widget)
/// ============================================================================
///
/// 功能：
///   - 切换深色/浅色主题
///   - 显示当前主题状态
///   - 使用回调方式传递主题状态
/// ============================================================================

class ThemeSwitch extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const ThemeSwitch({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.borderGlow(context);
    final textColor = AppTheme.textPrimary(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgMedium(context),
        border: Border.all(color: accentColor, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 深色主题按钮
          _ThemeButton(
            icon: Icons.dark_mode,
            label: '深色',
            isSelected: isDarkMode,
            accentColor: accentColor,
            textColor: textColor,
            onTap: () => onThemeChanged(true),
          ),
          // 浅色主题按钮
          _ThemeButton(
            icon: Icons.light_mode,
            label: '浅色',
            isSelected: !isDarkMode,
            accentColor: accentColor,
            textColor: textColor,
            onTap: () => onThemeChanged(false),
          ),
        ],
      ),
    );
  }
}

/// 主题按钮子组件
class _ThemeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color accentColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ThemeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.2) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? accentColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? accentColor : textColor.withOpacity(0.6),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? accentColor : textColor.withOpacity(0.6),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
