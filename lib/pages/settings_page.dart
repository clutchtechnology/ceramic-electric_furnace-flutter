import 'package:flutter/material.dart';
import '../widgets/common/tech_line_widgets.dart';
import '../widgets/common/theme_switch.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../api/valve_api.dart';
import '../main.dart';

/// 系统配置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppState _appState;
  final ValveApi _valveApi = ValveApi();

  // 蝶阀配置加载状态
  bool _isLoadingValveConfig = false;
  String? _valveConfigError;

  @override
  void initState() {
    super.initState();
    _appState = AppState.instance;
    _appState.addListener(_onStateChanged);
    _loadThresholdsFromAppState();
  }

  /// 从 AppState 加载阈值到 Controller
  void _loadThresholdsFromAppState() {
    _furnaceCoverFlowMinController.text =
        _appState.furnaceCoverFlowMin.toString();
    _furnaceCoverFlowMaxController.text =
        _appState.furnaceCoverFlowMax.toString();
    _furnaceCoverPressureMinController.text =
        _appState.furnaceCoverPressureMin.toString();
    _furnaceCoverPressureMaxController.text =
        _appState.furnaceCoverPressureMax.toString();
    _furnaceShellFlowMinController.text =
        _appState.furnaceShellFlowMin.toString();
    _furnaceShellFlowMaxController.text =
        _appState.furnaceShellFlowMax.toString();
    _furnaceShellPressureMinController.text =
        _appState.furnaceShellPressureMin.toString();
    _furnaceShellPressureMaxController.text =
        _appState.furnaceShellPressureMax.toString();
  }

  /// 保存阈值到 AppState
  Future<void> _saveThresholdsToAppState() async {
    _appState.furnaceCoverFlowMin =
        double.tryParse(_furnaceCoverFlowMinController.text) ?? 0.0;
    _appState.furnaceCoverFlowMax =
        double.tryParse(_furnaceCoverFlowMaxController.text) ?? 10.0;
    _appState.furnaceCoverPressureMin =
        double.tryParse(_furnaceCoverPressureMinController.text) ?? 0.0;
    _appState.furnaceCoverPressureMax =
        double.tryParse(_furnaceCoverPressureMaxController.text) ?? 1000.0;
    _appState.furnaceShellFlowMin =
        double.tryParse(_furnaceShellFlowMinController.text) ?? 0.0;
    _appState.furnaceShellFlowMax =
        double.tryParse(_furnaceShellFlowMaxController.text) ?? 10.0;
    _appState.furnaceShellPressureMin =
        double.tryParse(_furnaceShellPressureMinController.text) ?? 0.0;
    _appState.furnaceShellPressureMax =
        double.tryParse(_furnaceShellPressureMaxController.text) ?? 1000.0;
    await _appState.saveAlarmThresholds();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // 系统配置数据
  final TextEditingController _serverIpController =
      TextEditingController(text: 'localhost');
  final TextEditingController _serverPortController =
      TextEditingController(text: '8082');
  final TextEditingController _plcIpController =
      TextEditingController(text: '192.168.1.10');
  final TextEditingController _plcPortController =
      TextEditingController(text: '102');
  String _plcProtocol = 'S7 Protocol';
  final TextEditingController _dbAddressController =
      TextEditingController(text: 'localhost');
  final TextEditingController _dbPortController =
      TextEditingController(text: '8089');
  final TextEditingController _dbUsernameController =
      TextEditingController(text: 'admin');
  final TextEditingController _dbPasswordController =
      TextEditingController(text: 'admin_password');
  bool _showPassword = false;

  // ============ 报警阈值数据 ============
  // 注意：电流/电压阈值已移除，这些值应从后端接口获取

  // 折叠控制
  bool _distance1Expanded = false;
  bool _distance2Expanded = false;
  bool _distance3Expanded = false;
  bool _filterPressureDiffExpanded = false;
  bool _furnaceCoverFlowExpanded = false;
  bool _furnaceCoverPressureExpanded = false;
  bool _furnaceShellFlowExpanded = false;
  bool _furnaceShellPressureExpanded = false;

  // 测距1/2/3 阈值 (单位: mm, 低点150mm=0.15m, 高点1960mm=1.96m)
  final TextEditingController _distance1MinController =
      TextEditingController(text: '150');
  final TextEditingController _distance1MaxController =
      TextEditingController(text: '1960');
  final TextEditingController _distance2MinController =
      TextEditingController(text: '150');
  final TextEditingController _distance2MaxController =
      TextEditingController(text: '1960');
  final TextEditingController _distance3MinController =
      TextEditingController(text: '150');
  final TextEditingController _distance3MaxController =
      TextEditingController(text: '1960');

  // 前置过滤器压差阈值 (kPa)
  final TextEditingController _filterPressureDiffMinController =
      TextEditingController(text: '0');
  final TextEditingController _filterPressureDiffMaxController =
      TextEditingController(text: '50');

  // 炉盖冷却水流速阈值 (m³/h)
  final TextEditingController _furnaceCoverFlowMinController =
      TextEditingController(text: '0');
  final TextEditingController _furnaceCoverFlowMaxController =
      TextEditingController(text: '10');

  // 炉盖冷却水水压阈值 (kPa)
  final TextEditingController _furnaceCoverPressureMinController =
      TextEditingController(text: '0');
  final TextEditingController _furnaceCoverPressureMaxController =
      TextEditingController(text: '1000');

  // 炉皮冷却水流速阈值 (m³/h)
  final TextEditingController _furnaceShellFlowMinController =
      TextEditingController(text: '0');
  final TextEditingController _furnaceShellFlowMaxController =
      TextEditingController(text: '10');

  // 炉皮冷却水水压阈值 (kPa)
  final TextEditingController _furnaceShellPressureMinController =
      TextEditingController(text: '0');
  final TextEditingController _furnaceShellPressureMaxController =
      TextEditingController(text: '1000');

  // ============ 蝶阀配置数据 ============
  bool _valve1Expanded = false;
  bool _valve2Expanded = false;
  bool _valve3Expanded = false;
  bool _valve4Expanded = false;

  // 蝶阀1-4 全开/全关时间 (秒)
  final TextEditingController _valve1OpenTimeController =
      TextEditingController(text: '30');
  final TextEditingController _valve1CloseTimeController =
      TextEditingController(text: '30');
  final TextEditingController _valve2OpenTimeController =
      TextEditingController(text: '30');
  final TextEditingController _valve2CloseTimeController =
      TextEditingController(text: '30');
  final TextEditingController _valve3OpenTimeController =
      TextEditingController(text: '30');
  final TextEditingController _valve3CloseTimeController =
      TextEditingController(text: '30');
  final TextEditingController _valve4OpenTimeController =
      TextEditingController(text: '30');
  final TextEditingController _valve4CloseTimeController =
      TextEditingController(text: '30');

  @override
  void dispose() {
    _appState.removeListener(_onStateChanged);
    _serverIpController.dispose();
    _serverPortController.dispose();
    _plcIpController.dispose();
    _plcPortController.dispose();
    _dbAddressController.dispose();
    _dbPortController.dispose();
    _dbUsernameController.dispose();
    _dbPasswordController.dispose();
    // 测距阈值
    _distance1MinController.dispose();
    _distance1MaxController.dispose();
    _distance2MinController.dispose();
    _distance2MaxController.dispose();
    _distance3MinController.dispose();
    _distance3MaxController.dispose();
    // 前置过滤器压差阈值
    _filterPressureDiffMinController.dispose();
    _filterPressureDiffMaxController.dispose();
    // 炉盖冷却水阈值
    _furnaceCoverFlowMinController.dispose();
    _furnaceCoverFlowMaxController.dispose();
    _furnaceCoverPressureMinController.dispose();
    _furnaceCoverPressureMaxController.dispose();
    // 炉皮冷却水阈值
    _furnaceShellFlowMinController.dispose();
    _furnaceShellFlowMaxController.dispose();
    _furnaceShellPressureMinController.dispose();
    _furnaceShellPressureMaxController.dispose();
    // 蝶阀配置
    _valve1OpenTimeController.dispose();
    _valve1CloseTimeController.dispose();
    _valve2OpenTimeController.dispose();
    _valve2CloseTimeController.dispose();
    _valve3OpenTimeController.dispose();
    _valve3CloseTimeController.dispose();
    _valve4OpenTimeController.dispose();
    _valve4CloseTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgDeep(context),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧导航栏
          _buildLeftNav(),
          const SizedBox(width: 20),
          // 右侧内容区
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  /// 左侧导航栏
  Widget _buildLeftNav() {
    final navItems = [
      {'title': '系统配置', 'icon': Icons.settings},
      {'title': '报警阈值', 'icon': Icons.warning_amber},
      {'title': '蝶阀配置', 'icon': Icons.control_camera},
    ];

    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgDark(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderDark(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '配置中心',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(navItems.length, (index) {
            final item = navItems[index];
            final isSelected = _appState.systemConfigTabIndex == index;
            return GestureDetector(
              onTap: () async {
                _appState.systemConfigTabIndex = index;
                await _appState.saveSystemConfigState();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.borderGlow(context).withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.borderGlow(context).withOpacity(0.5)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isSelected
                          ? AppTheme.borderGlow(context)
                          : AppTheme.textSecondary(context),
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.borderGlow(context)
                            : AppTheme.textSecondary(context),
                        fontSize: 19,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 内容区域
  Widget _buildContent() {
    // 根据当前选中的Tab返回标题
    String _getTitle() {
      switch (_appState.systemConfigTabIndex) {
        case 0:
          return '系统配置';
        case 1:
          return '报警阈值';
        case 2:
          return '蝶阀配置';
        default:
          return '系统配置';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 页面标题和保存按钮
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.borderGlow(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _getTitle(),
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // 蝶阀配置页显示刷新按钮
            if (_appState.systemConfigTabIndex == 2)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton.icon(
                  onPressed: _isLoadingValveConfig ? null : _loadValveConfig,
                  icon: _isLoadingValveConfig
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.borderGlow(context),
                          ),
                        )
                      : Icon(Icons.refresh, size: 22),
                  label: Text(
                    _isLoadingValveConfig ? '加载中...' : '刷新配置',
                    style: TextStyle(fontSize: 17),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppTheme.glowGreen(context).withOpacity(0.2),
                    foregroundColor: AppTheme.glowGreen(context),
                    side: BorderSide(
                        color: AppTheme.glowGreen(context).withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: Icon(Icons.save, size: 26),
              label: const Text('保存配置', style: TextStyle(fontSize: 19)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.borderGlow(context).withOpacity(0.2),
                foregroundColor: AppTheme.borderGlow(context),
                side: BorderSide(
                    color: AppTheme.borderGlow(context).withOpacity(0.5)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // 内容
        Expanded(
          child: SingleChildScrollView(
            child: _appState.systemConfigTabIndex == 0
                ? _buildSystemConfigContent()
                : _appState.systemConfigTabIndex == 1
                    ? _buildAlarmThresholdContent()
                    : _buildValveConfigContent(),
          ),
        ),
      ],
    );
  }

  /// 系统配置页面内容
  Widget _buildSystemConfigContent() {
    return Column(
      children: [
        // 主题切换
        _buildConfigSection(
          title: '主题设置',
          icon: Icons.palette,
          children: [
            ThemeSwitch(
              isDarkMode: ThemeManager.isDarkMode(),
              onThemeChanged: (isDark) async {
                final mode = isDark ? ThemeMode.dark : ThemeMode.light;
                await ThemeManager.setThemeMode(mode);
                setState(() {});
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 服务器地址配置
        _buildConfigSection(
          title: '服务器地址配置',
          icon: Icons.dns,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildInputField('IP地址', _serverIpController),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField('端口号', _serverPortController),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // PLC地址配置
        _buildConfigSection(
          title: 'PLC地址配置',
          icon: Icons.memory,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildInputField('IP地址', _plcIpController),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField('端口号', _plcPortController),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDropdownField(
              '通信协议',
              _plcProtocol,
              [
                'S7 Protocol',
                'Modbus TCP',
                'Modbus RTU',
                'Ethernet/IP',
                'Profinet'
              ],
              (value) => setState(() => _plcProtocol = value ?? 'S7 Protocol'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 数据库地址配置
        _buildConfigSection(
          title: '数据库地址配置',
          icon: Icons.storage,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildInputField('连接地址', _dbAddressController),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField('端口号', _dbPortController),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInputField('用户名', _dbUsernameController),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPasswordField(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 报警阈值页面内容 (折叠样式)
  /// 注意：电流/电压阈值已移除，这些值应从后端接口获取
  Widget _buildAlarmThresholdContent() {
    return Column(
      children: [
        // ============ 测距阈值 ============
        _buildCollapsibleSection(
          title: '测距1 阈值',
          icon: Icons.straighten,
          accentColor: AppTheme.borderGlow(context),
          isExpanded: _distance1Expanded,
          onToggle: () =>
              setState(() => _distance1Expanded = !_distance1Expanded),
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '距离低位告警 (mm)', _distance1MinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '距离高位告警 (mm)', _distance1MaxController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCollapsibleSection(
          title: '测距2 阈值',
          icon: Icons.straighten,
          accentColor: AppTheme.borderGlow(context),
          isExpanded: _distance2Expanded,
          onToggle: () =>
              setState(() => _distance2Expanded = !_distance2Expanded),
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '距离低位告警 (mm)', _distance2MinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '距离高位告警 (mm)', _distance2MaxController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCollapsibleSection(
          title: '测距3 阈值',
          icon: Icons.straighten,
          accentColor: AppTheme.borderGlow(context),
          isExpanded: _distance3Expanded,
          onToggle: () =>
              setState(() => _distance3Expanded = !_distance3Expanded),
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '距离低位告警 (mm)', _distance3MinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '距离高位告警 (mm)', _distance3MaxController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ============ 前置过滤器压差阈值 ============
        _buildCollapsibleSection(
          title: '前置过滤器压差阈值',
          icon: Icons.filter_alt,
          accentColor: const Color(0xFFffcc00),
          isExpanded: _filterPressureDiffExpanded,
          onToggle: () => setState(
              () => _filterPressureDiffExpanded = !_filterPressureDiffExpanded),
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '压差低位告警 (kPa)', _filterPressureDiffMinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '压差高位告警 (kPa)', _filterPressureDiffMaxController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ============ 炉盖冷却水流速阈值 ============
        _buildCollapsibleSection(
          title: '炉盖冷却水流速阈值',
          icon: Icons.water,
          accentColor: AppTheme.glowOrange(context),
          isExpanded: _furnaceCoverFlowExpanded,
          onToggle: () => setState(
              () => _furnaceCoverFlowExpanded = !_furnaceCoverFlowExpanded),
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '流速低位告警 (m³/h)', _furnaceCoverFlowMinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '流速高位告警 (m³/h)', _furnaceCoverFlowMaxController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ============ 炉盖冷却水水压阈值 ============
        _buildCollapsibleSection(
          title: '炉盖冷却水水压阈值',
          icon: Icons.opacity,
          accentColor: AppTheme.glowBlue(context),
          isExpanded: _furnaceCoverPressureExpanded,
          onToggle: () => setState(() =>
              _furnaceCoverPressureExpanded = !_furnaceCoverPressureExpanded),
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '水压低位告警 (kPa)', _furnaceCoverPressureMinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '水压高位告警 (kPa)', _furnaceCoverPressureMaxController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ============ 炉皮冷却水流速阈值 ============
        _buildCollapsibleSection(
          title: '炉皮冷却水流速阈值',
          icon: Icons.water,
          accentColor: AppTheme.glowOrange(context),
          isExpanded: _furnaceShellFlowExpanded,
          onToggle: () => setState(
              () => _furnaceShellFlowExpanded = !_furnaceShellFlowExpanded),
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '流速低位告警 (m³/h)', _furnaceShellFlowMinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '流速高位告警 (m³/h)', _furnaceShellFlowMaxController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ============ 炉皮冷却水水压阈值 ============
        _buildCollapsibleSection(
          title: '炉皮冷却水水压阈值',
          icon: Icons.opacity,
          accentColor: AppTheme.glowBlue(context),
          isExpanded: _furnaceShellPressureExpanded,
          onToggle: () => setState(() =>
              _furnaceShellPressureExpanded = !_furnaceShellPressureExpanded),
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '水压低位告警 (kPa)', _furnaceShellPressureMinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '水压高位告警 (kPa)', _furnaceShellPressureMaxController)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// 折叠配置区域容器
  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isExpanded,
    required VoidCallback onToggle,
    Color? accentColor,
  }) {
    final accent = accentColor ?? AppTheme.borderGlow(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgDark(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderDark(context)),
      ),
      child: Column(
        children: [
          // 标题栏（可点击展开/折叠）
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, color: accentColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textSecondary(context),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          // 展开内容
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  /// 配置区域容器 (非折叠)
  Widget _buildConfigSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? accentColor,
  }) {
    final accent = accentColor ?? AppTheme.borderGlow(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgDark(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderDark(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 28),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  /// 输入框（系统配置只读）
  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true, // 系统配置改为只读
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontSize: 19,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.bgMedium(context).withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: AppTheme.borderDark(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: AppTheme.borderDark(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                  color: AppTheme.borderGlow(context).withOpacity(0.5)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  /// 密码输入框（只读）
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '密码',
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _dbPasswordController,
          readOnly: true, // 密码框改为只读
          obscureText: !_showPassword,
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontSize: 19,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.bgMedium(context).withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: AppTheme.borderDark(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: AppTheme.borderDark(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                  color: AppTheme.borderGlow(context).withOpacity(0.5)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility : Icons.visibility_off,
                color: AppTheme.textSecondary(context),
                size: 26,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
        ),
      ],
    );
  }

  /// 下拉选择框（只读）
  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.bgMedium(context).withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.borderDark(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item,
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontSize: 19,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: null, // 下拉框禁用
              dropdownColor: AppTheme.bgDark(context),
              icon: Icon(
                Icons.arrow_drop_down,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 保存设置
  void _saveSettings() async {
    // 如果是蝶阀配置页面，调用专门的保存方法
    if (_appState.systemConfigTabIndex == 2) {
      _saveValveConfig();
      return;
    }

    // 如果是报警阈值页面，保存阈值到 AppState
    if (_appState.systemConfigTabIndex == 1) {
      await _saveThresholdsToAppState();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle,
                color: AppTheme.glowGreen(context), size: 26),
            const SizedBox(width: 8),
            const Text('配置保存成功', style: TextStyle(fontSize: 19)),
          ],
        ),
        backgroundColor: AppTheme.bgDark(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppTheme.glowGreen(context).withOpacity(0.5)),
        ),
      ),
    );
  }

  // ============================================================
  // 蝶阀配置相关方法
  // ============================================================

  /// 蝶阀配置页面内容
  Widget _buildValveConfigContent() {
    return Column(
      children: [
        // 错误提示
        if (_valveConfigError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.statusAlarm(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppTheme.statusAlarm(context).withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline,
                    color: AppTheme.statusAlarm(context), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _valveConfigError!,
                    style: TextStyle(
                      color: AppTheme.statusAlarm(context),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 说明文字
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.glowCyan(context).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: AppTheme.glowCyan(context).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  color: AppTheme.glowCyan(context), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '配置每个蝶阀从全关到全开所需的时间（秒），用于计算蝶阀开度百分比。默认值为30秒。',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 蝶阀1配置
        _buildCollapsibleSection(
          title: '蝶阀1 全开/全关时间',
          icon: Icons.control_camera,
          accentColor: AppTheme.glowGreen(context),
          isExpanded: _valve1Expanded,
          onToggle: () => setState(() => _valve1Expanded = !_valve1Expanded),
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildEditableInputField(
                        '全开时间 (秒)', _valve1OpenTimeController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildEditableInputField(
                        '全关时间 (秒)', _valve1CloseTimeController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 蝶阀2配置
        _buildCollapsibleSection(
          title: '蝶阀2 全开/全关时间',
          icon: Icons.control_camera,
          accentColor: AppTheme.glowGreen(context),
          isExpanded: _valve2Expanded,
          onToggle: () => setState(() => _valve2Expanded = !_valve2Expanded),
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildEditableInputField(
                        '全开时间 (秒)', _valve2OpenTimeController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildEditableInputField(
                        '全关时间 (秒)', _valve2CloseTimeController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 蝶阀3配置
        _buildCollapsibleSection(
          title: '蝶阀3 全开/全关时间',
          icon: Icons.control_camera,
          accentColor: AppTheme.glowGreen(context),
          isExpanded: _valve3Expanded,
          onToggle: () => setState(() => _valve3Expanded = !_valve3Expanded),
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildEditableInputField(
                        '全开时间 (秒)', _valve3OpenTimeController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildEditableInputField(
                        '全关时间 (秒)', _valve3CloseTimeController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 蝶阀4配置
        _buildCollapsibleSection(
          title: '蝶阀4 全开/全关时间',
          icon: Icons.control_camera,
          accentColor: AppTheme.glowGreen(context),
          isExpanded: _valve4Expanded,
          onToggle: () => setState(() => _valve4Expanded = !_valve4Expanded),
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildEditableInputField(
                        '全开时间 (秒)', _valve4OpenTimeController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildEditableInputField(
                        '全关时间 (秒)', _valve4CloseTimeController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 重置按钮
        Container(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _resetValveConfigToDefault,
            icon: Icon(Icons.restore, size: 22),
            label: const Text('重置为默认值', style: TextStyle(fontSize: 17)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.glowOrange(context).withOpacity(0.2),
              foregroundColor: AppTheme.glowOrange(context),
              side: BorderSide(
                  color: AppTheme.glowOrange(context).withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  /// 可编辑输入框
  Widget _buildEditableInputField(
      String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontSize: 19,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.bgMedium(context).withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: AppTheme.borderDark(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: AppTheme.borderDark(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                  color: AppTheme.glowCyan(context).withOpacity(0.5)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  /// 从后端加载蝶阀配置
  Future<void> _loadValveConfig() async {
    setState(() {
      _isLoadingValveConfig = true;
      _valveConfigError = null;
    });

    try {
      final configs = await _valveApi.getValveConfig();

      // 更新控制器的值
      if (configs.containsKey('1')) {
        _valve1OpenTimeController.text = configs['1']!.fullOpenTime.toString();
        _valve1CloseTimeController.text =
            configs['1']!.fullCloseTime.toString();
      }
      if (configs.containsKey('2')) {
        _valve2OpenTimeController.text = configs['2']!.fullOpenTime.toString();
        _valve2CloseTimeController.text =
            configs['2']!.fullCloseTime.toString();
      }
      if (configs.containsKey('3')) {
        _valve3OpenTimeController.text = configs['3']!.fullOpenTime.toString();
        _valve3CloseTimeController.text =
            configs['3']!.fullCloseTime.toString();
      }
      if (configs.containsKey('4')) {
        _valve4OpenTimeController.text = configs['4']!.fullOpenTime.toString();
        _valve4CloseTimeController.text =
            configs['4']!.fullCloseTime.toString();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle,
                    color: AppTheme.glowGreen(context), size: 22),
                const SizedBox(width: 8),
                const Text('蝶阀配置加载成功', style: TextStyle(fontSize: 17)),
              ],
            ),
            backgroundColor: AppTheme.bgDark(context),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _valveConfigError = '加载蝶阀配置失败: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingValveConfig = false;
        });
      }
    }
  }

  /// 保存蝶阀配置到后端
  Future<void> _saveValveConfig() async {
    try {
      // 解析输入值
      final configs = <int, ValveConfig>{};

      configs[1] = ValveConfig(
        valveId: 1,
        fullOpenTime: double.tryParse(_valve1OpenTimeController.text) ?? 30.0,
        fullCloseTime: double.tryParse(_valve1CloseTimeController.text) ?? 30.0,
      );
      configs[2] = ValveConfig(
        valveId: 2,
        fullOpenTime: double.tryParse(_valve2OpenTimeController.text) ?? 30.0,
        fullCloseTime: double.tryParse(_valve2CloseTimeController.text) ?? 30.0,
      );
      configs[3] = ValveConfig(
        valveId: 3,
        fullOpenTime: double.tryParse(_valve3OpenTimeController.text) ?? 30.0,
        fullCloseTime: double.tryParse(_valve3CloseTimeController.text) ?? 30.0,
      );
      configs[4] = ValveConfig(
        valveId: 4,
        fullOpenTime: double.tryParse(_valve4OpenTimeController.text) ?? 30.0,
        fullCloseTime: double.tryParse(_valve4CloseTimeController.text) ?? 30.0,
      );

      await _valveApi.updateAllValveConfig(configs);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle,
                    color: AppTheme.glowGreen(context), size: 26),
                const SizedBox(width: 8),
                const Text('蝶阀配置保存成功', style: TextStyle(fontSize: 19)),
              ],
            ),
            backgroundColor: AppTheme.bgDark(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                  color: AppTheme.glowGreen(context).withOpacity(0.5)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline,
                    color: AppTheme.statusAlarm(context), size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '保存蝶阀配置失败: $e',
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.bgDark(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                  color: AppTheme.statusAlarm(context).withOpacity(0.5)),
            ),
          ),
        );
      }
    }
  }

  /// 重置蝶阀配置为默认值
  void _resetValveConfigToDefault() {
    setState(() {
      _valve1OpenTimeController.text = '30';
      _valve1CloseTimeController.text = '30';
      _valve2OpenTimeController.text = '30';
      _valve2CloseTimeController.text = '30';
      _valve3OpenTimeController.text = '30';
      _valve3CloseTimeController.text = '30';
      _valve4OpenTimeController.text = '30';
      _valve4CloseTimeController.text = '30';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.restore, color: AppTheme.glowOrange(context), size: 22),
            SizedBox(width: 8),
            Text('已重置为默认值 (30秒)', style: TextStyle(fontSize: 17)),
          ],
        ),
        backgroundColor: AppTheme.bgDark(context),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
