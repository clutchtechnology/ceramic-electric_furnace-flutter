import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'tech_line_widgets.dart';

/// 导出按钮组件
/// 科技风格的导出按钮，用于数据导出功能
class ExportButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Color accentColor;
  final String tooltip;
  final bool isLoading;
  final double size;
  
  // 新增参数：用于导出功能
  final String? exportTitle; // 导出文件的标题
  final List<String>? columns; // 表头列
  final List<List<String>>? data; // 表格数据

  const ExportButton({
    super.key,
    this.onPressed,
    this.accentColor = TechColors.glowCyan,
    this.tooltip = '导出数据',
    this.isLoading = false,
    this.size = 28,
    this.exportTitle,
    this.columns,
    this.data,
  });

  @override
  State<ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<ExportButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isLoading) {
      _loadingController.repeat();
    }
  }

  @override
  void didUpdateWidget(ExportButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _loadingController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _loadingController.stop();
      _loadingController.reset();
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  /// 处理导出操作
  Future<void> _handleExport(BuildContext context) async {
    // 如果有自定义回调，优先使用自定义回调
    if (widget.onPressed != null) {
      widget.onPressed!();
      return;
    }

    // 检查是否有数据可导出
    if (widget.columns == null || widget.data == null || widget.data!.isEmpty) {
      if (context.mounted) {
        _showSnackBar(context, '没有可导出的数据', isError: true);
      }
      return;
    }

    try {
      // 直接导出CSV格式
      String? savePath = await FilePicker.platform.saveFile(
        dialogTitle: '保存CSV文件',
        fileName: '${widget.exportTitle ?? '数据导出'}_${_getTimestamp()}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (savePath == null) return;

      await _exportToCsv(savePath);

      if (context.mounted) {
        _showSnackBar(context, '导出成功：$savePath');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, '导出失败：$e', isError: true);
      }
    }
  }

  /// 导出为CSV
  Future<void> _exportToCsv(String savePath) async {
    // 准备数据：表头 + 数据行
    List<List<String>> rows = [widget.columns!, ...widget.data!];
    
    // 使用正确的CSV转换设置
    String csv = const ListToCsvConverter(
      fieldDelimiter: ',',
      textDelimiter: '"',
      textEndDelimiter: '"',
      eol: '\r\n',
    ).convert(rows);
    
    // 添加UTF-8 BOM以确保Excel正确识别中文
    final bomUtf8 = [0xEF, 0xBB, 0xBF];
    // 使用utf8.encode正确编码中文字符
    final csvBytes = bomUtf8 + utf8.encode(csv);
    
    File(savePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(csvBytes);
  }

  /// 获取时间戳
  String _getTimestamp() {
    return DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  }

  /// 显示提示信息
  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
          ? Colors.red.withOpacity(0.8) 
          : widget.accentColor.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.isLoading ? null : () => _handleExport(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _isHovered
                  ? widget.accentColor.withOpacity(0.2)
                  : widget.accentColor.withOpacity(0.1),
              border: Border.all(
                color: _isHovered
                    ? widget.accentColor.withOpacity(0.6)
                    : widget.accentColor.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
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
              child: widget.isLoading
                  ? RotationTransition(
                      turns: _loadingController,
                      child: Icon(
                        Icons.sync,
                        size: widget.size * 0.55,
                        color: widget.accentColor,
                      ),
                    )
                  : Icon(
                      Icons.file_download_outlined,
                      size: widget.size * 0.55,
                      color: _isHovered
                          ? widget.accentColor
                          : widget.accentColor.withOpacity(0.8),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 带文字的导出按钮
class ExportButtonWithLabel extends StatefulWidget {
  final VoidCallback? onPressed;
  final Color accentColor;
  final String label;
  final bool isLoading;
  
  // 新增参数：用于导出功能
  final String? exportTitle; // 导出文件的标题
  final List<String>? columns; // 表头列
  final List<List<String>>? data; // 表格数据

  const ExportButtonWithLabel({
    super.key,
    this.onPressed,
    this.accentColor = TechColors.glowCyan,
    this.label = '导出',
    this.isLoading = false,
    this.exportTitle,
    this.columns,
    this.data,
  });

  @override
  State<ExportButtonWithLabel> createState() => _ExportButtonWithLabelState();
}

class _ExportButtonWithLabelState extends State<ExportButtonWithLabel>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isLoading) {
      _loadingController.repeat();
    }
  }

  @override
  void didUpdateWidget(ExportButtonWithLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _loadingController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _loadingController.stop();
      _loadingController.reset();
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  /// 处理导出操作（复用ExportButton的逻辑）
  Future<void> _handleExport(BuildContext context) async {
    // 如果有自定义回调，优先使用自定义回调
    if (widget.onPressed != null) {
      widget.onPressed!();
      return;
    }

    // 检查是否有数据可导出
    if (widget.columns == null || widget.data == null || widget.data!.isEmpty) {
      if (context.mounted) {
        _showSnackBar(context, '没有可导出的数据', isError: true);
      }
      return;
    }

    try {
      // 直接导出CSV格式
      String? savePath = await FilePicker.platform.saveFile(
        dialogTitle: '保存CSV文件',
        fileName: '${widget.exportTitle ?? '数据导出'}_${_getTimestamp()}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (savePath == null) return;

      await _exportToCsv(savePath);

      if (context.mounted) {
        _showSnackBar(context, '导出成功：$savePath');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, '导出失败：$e', isError: true);
      }
    }
  }

  Future<void> _exportToCsv(String savePath) async {
    // 准备数据：表头 + 数据行
    List<List<String>> rows = [widget.columns!, ...widget.data!];
    
    // 使用正确的CSV转换设置
    String csv = const ListToCsvConverter(
      fieldDelimiter: ',',
      textDelimiter: '"',
      textEndDelimiter: '"',
      eol: '\r\n',
    ).convert(rows);
    
    // 添加UTF-8 BOM以确保Excel正确识别中文
    final bomUtf8 = [0xEF, 0xBB, 0xBF];
    // 使用utf8.encode正确编码中文字符
    final csvBytes = bomUtf8 + utf8.encode(csv);
    
    File(savePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(csvBytes);
  }

  String _getTimestamp() {
    return DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
          ? Colors.red.withOpacity(0.8) 
          : widget.accentColor.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isLoading ? null : () => _handleExport(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.accentColor.withOpacity(0.2)
                : widget.accentColor.withOpacity(0.1),
            border: Border.all(
              color: _isHovered
                  ? widget.accentColor.withOpacity(0.6)
                  : widget.accentColor.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.isLoading
                  ? RotationTransition(
                      turns: _loadingController,
                      child: Icon(
                        Icons.sync,
                        size: 14,
                        color: widget.accentColor,
                      ),
                    )
                  : Icon(
                      Icons.file_download_outlined,
                      size: 14,
                      color: _isHovered
                          ? widget.accentColor
                          : widget.accentColor.withOpacity(0.8),
                    ),
              const SizedBox(width: 4),
              Text(
                widget.isLoading ? '导出中...' : widget.label,
                style: TextStyle(
                  color: _isHovered
                      ? widget.accentColor
                      : widget.accentColor.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
