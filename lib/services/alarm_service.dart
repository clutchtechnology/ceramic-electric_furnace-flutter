import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// 报警服务
/// 负责播放报警声音
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _hasAlarm = false;
  Timer? _beepTimer;

  /// 开始播放报警声音
  Future<void> startAlarm() async {
    if (_isPlaying) return;

    _hasAlarm = true;
    _isPlaying = true;

    debugPrint('[AlarmService] ⚠️ 开始报警！');

    // 使用定时器模拟间歇性蜂鸣声（每秒播放一次）
    _beepTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_hasAlarm) {
        timer.cancel();
        return;
      }
      
      try {
        // 播放本地报警音频文件
        await _audioPlayer.setVolume(0.6);
        await _audioPlayer.play(
          AssetSource('sounds/aviation-alarm.mp3'),
          mode: PlayerMode.lowLatency,
        );
        debugPrint('[AlarmService] 🔔 播放报警提示音');
      } catch (e) {
        // 如果资源加载失败（文件不存在），输出明显的控制台警告
        debugPrint('[AlarmService] ⚠️⚠️⚠️ 报警中！请注意系统异常！ ⚠️⚠️⚠️');
        debugPrint('[AlarmService] 音频播放失败 - $e');
      }
    });
  }

  /// 停止播放报警声音
  Future<void> stopAlarm() async {
    _hasAlarm = false;
    _isPlaying = false;
    
    _beepTimer?.cancel();
    _beepTimer = null;
    
    try {
      await _audioPlayer.stop();
      debugPrint('[AlarmService] 报警声音已停止');
    } catch (e) {
      debugPrint('[AlarmService] 停止报警声音失败: $e');
    }
  }

  /// 检查是否正在播放
  bool get isPlaying => _isPlaying;

  /// 释放资源
  void dispose() {
    _beepTimer?.cancel();
    _audioPlayer.dispose();
  }
}
