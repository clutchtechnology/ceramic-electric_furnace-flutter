# Flutter 主题系统实现计划

## 目标

为陶瓷电炉 Flutter 应用实现深色/浅色主题切换功能，遵循奥卡姆剃刀原则。

## 配色方案

### 深色主题（当前科技风格）

| 颜色名称      | 颜色值            | 十六进制 |
| ------------- | ----------------- | -------- |
| bgDeep        | Color(0xFF0d1117) | #0d1117  |
| bgDark        | Color(0xFF161b22) | #161b22  |
| bgMedium      | Color(0xFF21262d) | #21262d  |
| bgLight       | Color(0xFF30363d) | #30363d  |
| borderGlow    | Color(0xFF00d4ff) | #00d4ff  |
| glowGreen     | Color(0xFF00ff88) | #00ff88  |
| glowOrange    | Color(0xFFff9500) | #ff9500  |
| glowRed       | Color(0xFFff3b30) | #ff3b30  |
| textPrimary   | Color(0xFFe6edf3) | #e6edf3  |
| textSecondary | Color(0xFF8b949e) | #8b949e  |

### 浅色主题（绿色系）

| 颜色名称      | 颜色值            | 十六进制 |
| ------------- | ----------------- | -------- |
| bgDeep        | Color(0xFFe9eea8) | #e9eea8  |
| bgDark        | Color(0xFFf2fedc) | #f2fedc  |
| bgMedium      | Color(0xFFfafbe7) | #fafbe7  |
| bgLight       | Color(0xFFffffff) | #ffffff  |
| borderGlow    | Color(0xFF007663) | #007663  |
| glowGreen     | Color(0xFF008b67) | #008b67  |
| glowOrange    | Color(0xFFd5a339) | #d5a339  |
| glowRed       | Color(0xFFb95d3b) | #b95d3b  |
| textPrimary   | Color(0xFF1b3d2f) | #1b3d2f  |
| textSecondary | Color(0xFF474838) | #474838  |

## 实现步骤

### 步骤 1: 创建主题配置文件 已完成

**文件**: `lib/theme/app_theme.dart`

- 定义深色/浅色主题的 ThemeData
- 提供静态颜色访问器方法
- 保持与 TechColors 兼容的 API

### 步骤 2: 修改 main.dart 已完成

**文件**: `lib/main.dart`

- 导入 AppTheme
- 配置 MaterialApp 的 theme/darkTheme/themeMode
- 添加主题状态管理（使用简单的 StatefulWidget）

### 步骤 3: 创建主题切换组件 已完成

**文件**: `lib/widgets/common/theme_switch.dart`

- 创建主题切换按钮组件
- 使用 InheritedWidget 或回调方式传递主题状态

### 步骤 4: 修改设置页面 已完成

**文件**: `lib/pages/settings_page.dart`

- 添加主题切换选项
- 保存主题偏好到本地存储

### 步骤 5: 逐步替换 TechColors 已完成

**文件**: 所有使用 TechColors 的 widget 文件

- 将 `TechColors.bgDark` 替换为 `AppTheme.bgDark(context)`
- 将 `TechColors.glowCyan` 替换为 `AppTheme.borderGlow(context)`
- 依此类推替换所有颜色引用

## 需要修改的文件列表

### 新建文件 (2个)

1. `lib/theme/app_theme.dart` - 主题配置 ✅ 已完成
2. `lib/widgets/common/theme_switch.dart` - 主题切换组件 ✅ 已完成

### 修改文件 (27个)

#### Pages (9个)

3. `lib/pages/alarm_record_page.dart` - 警报记录页面
4. `lib/pages/db30_status_page.dart` - DB30 状态页面
5. `lib/pages/db41_status_page.dart` - DB41 状态页面
6. `lib/pages/history_curve_page.dart` - 历史曲线页面
7. `lib/pages/home.dart` - 主页面
8. `lib/pages/pump_room_status_page.dart` - 泵房状态页面
9. `lib/pages/realtime_data_page.dart` - 实时数据页面 ✅ 已完成
10. `lib/pages/settings_page.dart` - 设置页面 ✅ 已完成
11. `lib/pages/status_page.dart` - 状态页面

#### Widgets/Common (4个)

12. `lib/widgets/common/export_button.dart` - 导出按钮
13. `lib/widgets/common/health_status.dart` - 健康状态
14. `lib/widgets/common/refresh_button.dart` - 刷新按钮
15. `lib/widgets/common/tech_line_widgets.dart` - 科技风组件库（保留 TechColors 作为兼容层）

#### Widgets/HistoryCurve (5个)

16. `lib/widgets/history_curve/batch_selector.dart` - 批次选择器
17. `lib/widgets/history_curve/quick_time_selector.dart` - 快速时间选择器
18. `lib/widgets/history_curve/tech_bar_chart.dart` - 科技风柱状图
19. `lib/widgets/history_curve/tech_chart.dart` - 科技风图表
20. `lib/widgets/history_curve/time_range_selector.dart` - 时间范围选择器

#### Widgets/RealtimeData (6个)

21. `lib/widgets/realtime_data/data_card.dart` - 数据卡片 ✅ 已完成
22. `lib/widgets/realtime_data/electrode_current_chart.dart` - 电极电流图表 ✅ 已完成
23. `lib/widgets/realtime_data/info_card.dart` - 信息卡片 ✅ 已完成
24. `lib/widgets/realtime_data/smelting_control_button.dart` - 熔炼控制按钮 ✅ 已完成
25. `lib/widgets/realtime_data/valve_control.dart` - 阀门控制 ✅ 已完成
26. `lib/widgets/realtime_data/valve_status_indicator.dart` - 阀门状态指示器 ✅ 已完成

#### Widgets/Shared (3个)

27. `lib/widgets/shared/custom_card_widget.dart` - 自定义卡片组件 ✅ 已完成
28. `lib/widgets/shared/data_table.dart` - 数据表格 ✅ 已完成
29. `lib/widgets/shared/tech_dropdown.dart` - 科技风下拉框 ✅ 已完成

## 奥卡姆剃刀原则检查

- ✅ 使用 Flutter 原生 ThemeData，零额外依赖
- ✅ 单文件集中管理配色（AppTheme）
- ✅ 保留 TechColors 作为兼容层，渐进式迁移
- ✅ 使用简单的 StatefulWidget 管理主题状态，避免引入 Provider/Bloc

## 注意事项

1. 主题切换需要持久化存储（使用 shared_preferences）
2. 所有颜色替换后需要测试深色/浅色主题的显示效果
3. 图表组件（fl_chart）需要单独配置主题颜色
4. 图片资源可能需要适配浅色主题
5. 我希望我的修改不会出现我的代码文件会有中文乱码的情况发生,任何会到这种情况发生的都要避免.
6. 对于上面完成的修改,就再后面对应添加 已完成来标注,如果没有完成就不要添加已完成
7. 当发现有更好的实现办法或者发现有一些不合理,需要及时更新本提示词文档.
