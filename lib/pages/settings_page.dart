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
      TextEditingController(text: '192.168.1.100');
  final TextEditingController _serverPortController =
      TextEditingController(text: '8080');
  final TextEditingController _plcIpController =
      TextEditingController(text: '192.168.1.50');
  final TextEditingController _plcPortController =
      TextEditingController(text: '502');
  String _plcProtocol = 'Modbus TCP';
  final TextEditingController _dbAddressController =
      TextEditingController(text: '192.168.1.200');
  final TextEditingController _dbPortController =
      TextEditingController(text: '3306');
  final TextEditingController _dbUsernameController =
      TextEditingController(text: 'admin');
  final TextEditingController _dbPasswordController =
      TextEditingController(text: '******');
  bool _showPassword = false;

  // 报警阈值数据
  final TextEditingController _furnaceTemp1Controller =
      TextEditingController(text: '1200');
  final TextEditingController _furnaceTemp2Controller =
      TextEditingController(text: '1200');
  final TextEditingController _furnaceTemp3Controller =
      TextEditingController(text: '1200');
  final TextEditingController _furnaceTemp4Controller =
      TextEditingController(text: '1200');
  final TextEditingController _waterFlowMinController =
      TextEditingController(text: '10');
  final TextEditingController _waterFlowMaxController =
      TextEditingController(text: '50');
  final TextEditingController _waterPressureMinController =
      TextEditingController(text: '0.2');
  final TextEditingController _waterPressureMaxController =
      TextEditingController(text: '0.6');
  final TextEditingController _filterPressureMinController =
      TextEditingController(text: '0');
  final TextEditingController _filterPressureMaxController =
      TextEditingController(text: '100');
  final TextEditingController _pm10MaxController =
      TextEditingController(text: '75');
  final TextEditingController _fanVibrationMinController =
      TextEditingController(text: '0');
  final TextEditingController _fanVibrationMaxController =
      TextEditingController(text: '5');
  final TextEditingController _fanFrequencyMinController =
      TextEditingController(text: '45');
  final TextEditingController _fanFrequencyMaxController =
      TextEditingController(text: '55');

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
    _furnaceTemp1Controller.dispose();
    _furnaceTemp2Controller.dispose();
    _furnaceTemp3Controller.dispose();
    _furnaceTemp4Controller.dispose();
    _waterFlowMinController.dispose();
    _waterFlowMaxController.dispose();
    _waterPressureMinController.dispose();
    _waterPressureMaxController.dispose();
    _filterPressureMinController.dispose();
    _filterPressureMaxController.dispose();
    _pm10MaxController.dispose();
    _fanVibrationMinController.dispose();
    _fanVibrationMaxController.dispose();
    _fanFrequencyMinController.dispose();
    _fanFrequencyMaxController.dispose();
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
              fontSize: 20,
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
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? TechColors.glowCyan
                            : TechColors.textSecondary,
                        fontSize: 16,
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
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save, size: 22),
              label: const Text('保存配置', style: TextStyle(fontSize: 16)),
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
              ['Modbus TCP', 'Modbus RTU', 'Ethernet/IP', 'Profinet'],
              (value) => setState(() => _plcProtocol = value ?? 'Modbus TCP'),
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

  /// 报警阈值页面内容
  Widget _buildAlarmThresholdContent() {
    return Column(
      children: [
        // 炉皮温度阈值
        _buildConfigSection(
          title: '炉皮温度阈值',
          icon: Icons.thermostat,
          accentColor: TechColors.statusWarning,
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '点位1最高温度 (℃)', _furnaceTemp1Controller)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '点位2最高温度 (℃)', _furnaceTemp2Controller)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '点位3最高温度 (℃)', _furnaceTemp3Controller)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '点位4最高温度 (℃)', _furnaceTemp4Controller)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 炉皮冷却水阈值
        _buildConfigSection(
          title: '炉皮冷却水阈值',
          icon: Icons.water_drop,
          accentColor: TechColors.glowBlue,
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '流速最低值 (m³/h)', _waterFlowMinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '流速最高值 (m³/h)', _waterFlowMaxController)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '水压最低值 (MPa)', _waterPressureMinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '水压最高值 (MPa)', _waterPressureMaxController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 前置过滤器压差阈值
        _buildConfigSection(
          title: '前置过滤器压差阈值',
          icon: Icons.filter_alt,
          accentColor: TechColors.glowGreen,
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '压差最小值 (Pa)', _filterPressureMinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '压差最大值 (Pa)', _filterPressureMaxController)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 除尘排风口PM10阈值
        _buildConfigSection(
          title: '除尘排风口PM10阈值',
          icon: Icons.air,
          accentColor: TechColors.glowCyan,
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        'PM10最大值 (μg/m³)', _pm10MaxController)),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 除尘风机振动阈值
        _buildConfigSection(
          title: '除尘风机振动阈值',
          icon: Icons.vibration,
          accentColor: TechColors.statusWarning,
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '振动幅值最小值 (mm/s)', _fanVibrationMinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '振动幅值最大值 (mm/s)', _fanVibrationMaxController)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildInputField(
                        '振动频率最小值 (Hz)', _fanFrequencyMinController)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInputField(
                        '振动频率最大值 (Hz)', _fanFrequencyMaxController)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// 配置区域容器
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
              Icon(icon, color: accentColor, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 18,
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

  /// 输入框
  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TechColors.textSecondary,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(
            color: TechColors.textPrimary,
            fontSize: 16,
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

  /// 密码输入框
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '密码',
          style: TextStyle(
            color: TechColors.textSecondary,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _dbPasswordController,
          obscureText: !_showPassword,
          style: const TextStyle(
            color: TechColors.textPrimary,
            fontSize: 16,
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
                size: 22,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
        ),
      ],
    );
  }

  /// 下拉选择框
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
            fontSize: 15,
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
                            fontSize: 16,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
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
            Icon(Icons.check_circle, color: TechColors.glowGreen, size: 22),
            SizedBox(width: 8),
            Text('配置保存成功', style: TextStyle(fontSize: 16)),
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
