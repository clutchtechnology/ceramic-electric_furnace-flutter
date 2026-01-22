import 'package:audioplayers/audioplayers.dart';

/// 报警服务
/// 负责播放报警声音
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _hasAlarm = false;

  /// 开始播放报警声音
  Future<void> startAlarm() async {
    if (_isPlaying) return;

    _hasAlarm = true;
    _isPlaying = true;

    try {
      // 设置循环播放
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(0.5);
      
      // 使用在线的警报音效
      // 这是一个短促的蜂鸣声URL（公共资源）
      const alarmUrl = 'https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3';
      
      await _audioPlayer.play(UrlSource(alarmUrl));
      
      print('[AlarmService] 报警声音开始播放');
    } catch (e) {
      print('[AlarmService] 播放报警声音失败: $e');
      _isPlaying = false;
    }
  }

  /// 停止播放报警声音
  Future<void> stopAlarm() async {
    _hasAlarm = false;
    _isPlaying = false;
    
    try {
      await _audioPlayer.stop();
      print('[AlarmService] 报警声音已停止');
    } catch (e) {
      print('[AlarmService] 停止报警声音失败: $e');
    }
  }

  /// 检查是否正在播放
  bool get isPlaying => _isPlaying;

  /// 释放资源
  void dispose() {
    _audioPlayer.dispose();
  }
}
