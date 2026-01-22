import 'package:flutter/material.dart';
import '../widgets/common/tech_line_widgets.dart';
import '../models/app_state.dart';

/// 系统配置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState.instance;
    _appState.addListener(_onStateChanged);
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

  // 折叠控制
  bool _arc1Expanded = false;
  bool _arc2Expanded = false;
  bool _arc3Expanded = false;
  bool _distance1Expanded = false;
  bool _distance2Expanded = false;
  bool _distance3Expanded = false;
  bool _pressureExpanded = false;
  bool _flowExpanded = false;
  bool _waterPressureExpanded = false;
  bool _filterPressureDiffExpanded = false;

  // 电弧1 电流阈值 (设定值: 5978 A, 低位: 5978*0.85=5081.3, 高位: 5978*1.15=6874.7)
  final TextEditingController _arc1CurrentMinController =
      TextEditingController(text: '5081');
  final TextEditingController _arc1CurrentMaxController =
      TextEditingController(text: '6875');

  // 电弧2 电流阈值
  final TextEditingController _arc2CurrentMinController =
      TextEditingController(text: '5081');
  final TextEditingController _arc2CurrentMaxController =
      TextEditingController(text: '6875');

  // 电弧3 电流阈值
  final TextEditingController _arc3CurrentMinController =
      TextEditingController(text: '5081');
  final TextEditingController _arc3CurrentMaxController =
      TextEditingController(text: '6875');

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

  // 压力阈值
  final TextEditingController _pressureMinController =
      TextEditingController(text: '0');
  final TextEditingController _pressureMaxController =
      TextEditingController(text: '10');

  // 流量阈值
  final TextEditingController _flowMinController =
      TextEditingController(text: '0');
  final TextEditingController _flowMaxController =
      TextEditingController(text: '100');

  // 炉皮冷却水水压阈值
  final TextEditingController _waterPressure1MinController =
      TextEditingController(text: '0');
  final TextEditingController _waterPressure1MaxController =
      TextEditingController(text: '1.0');
  final TextEditingController _waterPressure2MinController =
      TextEditingController(text: '0');
  final TextEditingController _waterPressure2MaxController =
      TextEditingController(text: '1.0');

  // 前置过滤器压差阈值 (水压1 - 水压2)
  final TextEditingController _filterPressureDiffMinController =
      TextEditingController(text: '0');
  final TextEditingController _filterPressureDiffMaxController =
      TextEditingController(text: '0.5');

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
    // 电弧阈值
    _arc1CurrentMinController.dispose();
    _arc1CurrentMaxController.dispose();
    _arc2CurrentMinController.dispose();
    _arc2CurrentMaxController.dispose();
    _arc3CurrentMinController.dispose();
    _arc3CurrentMaxController.dispose();
    // 测距阈值
    _distance1MinController.dispose();
    _distance1MaxController.dispose();
    _distance2MinController.dispose();
    _distance2MaxController.dispose();
    _distance3MinController.dispose();
    _distance3MaxController.dispose();
    // 压力/流量阈值
    _pressureMinController.dispose();
    _pressureMaxController.dispose();
    _flowMinController.dispose();
    _flowMaxController.dispose();
    // 冷却水水压阈值
    _waterPressure1MinController.dispose();
    _waterPressure1MaxController.dispose();
    _waterPressure2MinController.dispose();
    _waterPressure2MaxController.dispose();
    // 前置过滤器压差阈值
    _filterPressureDiffMinController.dispose();
    _filterPressureDiffMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TechColors.bgDeep,
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
    ];

    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TechColors.bgDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TechColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '配置中心',
            style: TextStyle(
              color: TechColors.textPrimary,
              fontSize: 16,
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
                      ? TechColors.glowCyan.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? TechColors.glowCyan.withOpacity(0.5)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isSelected
                          ? TechColors.glowCyan
                          : TechColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? TechColors.glowCyan
                            : TechColors.textSecondary,
                        fontSize: 13,
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
                color: TechColors.glowCyan,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _appState.systemConfigTabIndex == 0 ? '系统配置' : '报警阈值',
              style: const TextStyle(
                color: TechColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('保存配置'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TechColors.glowCyan.withOpacity(0.2),
                foregroundColor: TechColors.glowCyan,
                side: BorderSide(color: TechColors.glowCyan.withOpacity(0.5)),
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
                : _buildAlarmThresholdContent(),
          ),
        ),
      ],
    );
  }

  /// 系统配置页面内容
  Widget _buildSystemConfigContent() {
    return Column(
      children: [
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
              ['S7 Protocol', 'Modbus TCP', 'Modbus RTU', 'Ethernet/IP', 'Profinet'],
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
  Widget _buildAlarmThresholdContent() {
    return Column(
      children: [
        // ============ 电弧电流阈值 (设定值: 5978 A, ±15% 告警) ============
        _buildCollapsibleSection(
          title: '电弧1 电流阈值',
          icon: Icons.flash_on,
          accentColor: TechColors.glowOrange,
          isExpanded: _arc1Expanded,
          onToggle: () => setState(() => _arc1Expanded = !_arc1Expanded),
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '电流低位告警 (A)', _arc1CurrentMinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '电流高位告警 (A)', _arc1CurrentMaxController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCollapsibleSection(
          title: '电弧2 电流阈值',
          icon: Icons.flash_on,
          accentColor: TechColors.glowOrange,
          isExpanded: _arc2Expanded,
          onToggle: () => setState(() => _arc2Expanded = !_arc2Expanded),
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '电流低位告警 (A)', _arc2CurrentMinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '电流高位告警 (A)', _arc2CurrentMaxController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCollapsibleSection(
          title: '电弧3 电流阈值',
          icon: Icons.flash_on,
          accentColor: TechColors.glowOrange,
          isExpanded: _arc3Expanded,
          onToggle: () => setState(() => _arc3Expanded = !_arc3Expanded),
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '电流低位告警 (A)', _arc3CurrentMinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '电流高位告警 (A)', _arc3CurrentMaxController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ============ 测距阈值 ============
        _buildCollapsibleSection(
          title: '测距1 阈值',
          icon: Icons.straighten,
          accentColor: TechColors.glowCyan,
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
          accentColor: TechColors.glowCyan,
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
          accentColor: TechColors.glowCyan,
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

        // ============ 压力阈值 ============
        _buildCollapsibleSection(
          title: '压力阈值',
          icon: Icons.speed,
          accentColor: TechColors.glowGreen,
          isExpanded: _pressureExpanded,
          onToggle: () =>
              setState(() => _pressureExpanded = !_pressureExpanded),
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '压力低位告警 (MPa)', _pressureMinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '压力高位告警 (MPa)', _pressureMaxController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ============ 流量阈值 ============
        _buildCollapsibleSection(
          title: '流量阈值',
          icon: Icons.water_drop,
          accentColor: TechColors.glowBlue,
          isExpanded: _flowExpanded,
          onToggle: () => setState(() => _flowExpanded = !_flowExpanded),
          children: [
            Row(
              children: [
                Expanded(
                    child:
                        _buildInputField('流量低位告警 (m³/h)', _flowMinController)),
                const SizedBox(width: 12),
                Expanded(
                    child:
                        _buildInputField('流量高位告警 (m³/h)', _flowMaxController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ============ 炉皮冷却水水压阈值 ============
        _buildCollapsibleSection(
          title: '炉皮冷却水水压阈值',
          icon: Icons.water,
          accentColor: TechColors.glowBlue,
          isExpanded: _waterPressureExpanded,
          onToggle: () =>
              setState(() => _waterPressureExpanded = !_waterPressureExpanded),
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '水压1低位告警 (MPa)', _waterPressure1MinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '水压1高位告警 (MPa)', _waterPressure1MaxController)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '水压2低位告警 (MPa)', _waterPressure2MinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '水压2高位告警 (MPa)', _waterPressure2MaxController)),
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
                        '压差低位告警 (MPa)', _filterPressureDiffMinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '压差高位告警 (MPa)', _filterPressureDiffMaxController)),
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
    Color accentColor = TechColors.glowCyan,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: TechColors.bgDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TechColors.borderDark),
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
                  Icon(icon, color: accentColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: TechColors.textSecondary,
                    size: 20,
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
    Color accentColor = TechColors.glowCyan,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TechColors.bgDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TechColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 15,
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
          style: const TextStyle(
            color: TechColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true, // 系统配置改为只读
          style: const TextStyle(
            color: TechColors.textPrimary,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: TechColors.bgMedium.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: TechColors.borderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: TechColors.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide:
                  BorderSide(color: TechColors.glowCyan.withOpacity(0.5)),
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
        const Text(
          '密码',
          style: TextStyle(
            color: TechColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _dbPasswordController,
          readOnly: true, // 密码框改为只读
          obscureText: !_showPassword,
          style: const TextStyle(
            color: TechColors.textPrimary,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: TechColors.bgMedium.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: TechColors.borderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: TechColors.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide:
                  BorderSide(color: TechColors.glowCyan.withOpacity(0.5)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility : Icons.visibility_off,
                color: TechColors.textSecondary,
                size: 18,
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
          style: const TextStyle(
            color: TechColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: TechColors.bgMedium.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: TechColors.borderDark),
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
                          style: const TextStyle(
                            color: TechColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: null, // 下拉框禁用
              dropdownColor: TechColors.bgDark,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: TechColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 保存设置
  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: TechColors.glowGreen),
            SizedBox(width: 8),
            Text('配置保存成功'),
          ],
        ),
        backgroundColor: TechColors.bgDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: TechColors.glowGreen.withOpacity(0.5)),
        ),
      ),
    );
  }
}
