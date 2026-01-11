import 'package:flutter/material.dart';
import '../widgets/common/tech_line_widgets.dart';

/// 实时监控页面 - 九宫格监控画面
class RealtimeMonitorPage extends StatefulWidget {
  const RealtimeMonitorPage({super.key});

  @override
  State<RealtimeMonitorPage> createState() => _RealtimeMonitorPageState();
}

class _RealtimeMonitorPageState extends State<RealtimeMonitorPage> {
  // 监控画面配置
  final List<_MonitorCamera> _cameras = [
    _MonitorCamera(title: '炉皮热成像 - 前视角', type: MonitorType.thermal),
    _MonitorCamera(title: '炉皮热成像 - 左视角', type: MonitorType.thermal),
    _MonitorCamera(title: '炉皮热成像 - 右视角', type: MonitorType.thermal),
    _MonitorCamera(title: '炉皮热成像 - 顶视角', type: MonitorType.thermal),
    _MonitorCamera(title: '彩色监控 1', type: MonitorType.color),
    _MonitorCamera(title: '彩色监控 2', type: MonitorType.color),
    _MonitorCamera(title: '彩色监控 3', type: MonitorType.color),
    _MonitorCamera(title: '彩色监控 4', type: MonitorType.color),
    _MonitorCamera(title: '炉后监控', type: MonitorType.color),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TechColors.bgDeep,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 九宫格监控画面
          Expanded(
            child: _buildMonitorGrid(),
          ),
        ],
      ),
    );
  }

  /// 九宫格监控画面
  Widget _buildMonitorGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3列
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 4 / 3, // 4:3 宽高比
      ),
      itemCount: _cameras.length,
      itemBuilder: (context, index) {
        return _buildMonitorItem(_cameras[index], index);
      },
    );
  }

  /// 单个监控画面项
  Widget _buildMonitorItem(_MonitorCamera camera, int index) {
    return Container(
      decoration: BoxDecoration(
        color: TechColors.bgDark,
        border: Border.all(
          color: TechColors.borderDark,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: camera.type == MonitorType.thermal
                ? TechColors.glowOrange.withOpacity(0.1)
                : TechColors.glowCyan.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // 监控画面背景
            _buildMonitorContent(camera),
            // 顶部信息条
            _buildMonitorTopBar(camera, index),
            // 底部状态条
            _buildMonitorBottomBar(camera),
          ],
        ),
      ),
    );
  }

  /// 监控画面内容（模拟画面）
  Widget _buildMonitorContent(_MonitorCamera camera) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // 模拟监控画面网格
          CustomPaint(
            size: Size.infinite,
            painter: _MonitorGridPainter(
              gridColor: camera.type == MonitorType.thermal
                  ? TechColors.glowOrange.withOpacity(0.1)
                  : TechColors.glowCyan.withOpacity(0.1),
            ),
          ),
          // 中心提示文字
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  camera.type == MonitorType.thermal
                      ? Icons.thermostat
                      : Icons.videocam,
                  size: 48,
                  color: camera.type == MonitorType.thermal
                      ? TechColors.glowOrange.withOpacity(0.3)
                      : TechColors.glowCyan.withOpacity(0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  camera.type == MonitorType.thermal ? '热成像监控' : '实时监控',
                  style: TextStyle(
                    color: TechColors.textSecondary.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // 模拟扫描线效果
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: _ScanLineAnimation(
              color: camera.type == MonitorType.thermal
                  ? TechColors.glowOrange
                  : TechColors.glowCyan,
            ),
          ),
        ],
      ),
    );
  }

  /// 监控画面顶部信息条
  Widget _buildMonitorTopBar(_MonitorCamera camera, int index) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // 摄像头编号
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: camera.type == MonitorType.thermal
                    ? TechColors.glowOrange.withOpacity(0.2)
                    : TechColors.glowCyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: camera.type == MonitorType.thermal
                      ? TechColors.glowOrange.withOpacity(0.5)
                      : TechColors.glowCyan.withOpacity(0.5),
                ),
              ),
              child: Text(
                'CAM ${index + 1}',
                style: TextStyle(
                  color: camera.type == MonitorType.thermal
                      ? TechColors.glowOrange
                      : TechColors.glowCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 摄像头标题
            Expanded(
              child: Text(
                camera.title,
                style: TextStyle(
                  color: TechColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 在线状态指示
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: TechColors.statusNormal,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: TechColors.statusNormal,
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 监控画面底部状态条
  Widget _buildMonitorBottomBar(_MonitorCamera camera) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // 时间戳
            Icon(
              Icons.access_time,
              size: 10,
              color: TechColors.textSecondary.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              timeStr,
              style: TextStyle(
                color: TechColors.textSecondary.withOpacity(0.7),
                fontSize: 9,
              ),
            ),
            const Spacer(),
            // 录制状态
            Icon(
              Icons.fiber_manual_record,
              size: 8,
              color: Colors.red.withOpacity(0.8),
            ),
            const SizedBox(width: 4),
            Text(
              'REC',
              style: TextStyle(
                color: Colors.red.withOpacity(0.8),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 监控摄像头数据模型
class _MonitorCamera {
  final String title;
  final MonitorType type;

  _MonitorCamera({
    required this.title,
    required this.type,
  });
}

/// 监控类型枚举
enum MonitorType {
  thermal, // 热成像
  color, // 彩色
}

/// 监控画面网格绘制器
class _MonitorGridPainter extends CustomPainter {
  final Color gridColor;

  _MonitorGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // 绘制网格
    const gridSize = 30.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // 绘制十字准星
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final crosshairPaint = Paint()
      ..color = gridColor.withOpacity(0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(centerX - 20, centerY),
      Offset(centerX + 20, centerY),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - 20),
      Offset(centerX, centerY + 20),
      crosshairPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 扫描线动画组件
class _ScanLineAnimation extends StatefulWidget {
  final Color color;

  const _ScanLineAnimation({required this.color});

  @override
  State<_ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<_ScanLineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScanLinePainter(
            progress: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

/// 扫描线绘制器
class _ScanLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(0.3),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 2, size.width, 4));

    canvas.drawRect(
      Rect.fromLTWH(0, y - 2, size.width, 4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
