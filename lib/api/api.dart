// 后端API地址统一管理

class Api {
  static const String baseUrl = 'http://localhost:8082';

  // 健康检查
  static const String health = '/api/health';
  static const String healthPlc = '/api/health/plc';
  static const String healthDb = '/api/health/database';

  // 冶炼批次管理
  static const String smeltingStart = '/api/furnace/smelting/start';
  static const String smeltingStop = '/api/furnace/smelting/stop';
  static const String smeltingBatch = '/api/furnace/smelting/batch';

  // 实时数据
  static const String realtimeBatch = '/api/furnace/realtime/batch';

  // 历史数据
  static const String history = '/api/furnace/history';

  // 历史数据 - 新接口
  static const String historyBatches = '/api/history/batches'; // 批次号列表
  static const String historyHopper = '/api/history/hopper'; // 料仓历史
  static const String historyCooling = '/api/history/cooling'; // 冷却水历史
  static const String historyCurrent = '/api/history/current'; // 电极电流历史
  static const String historyPower = '/api/history/power'; // 功率能耗历史
  static const String historyQuery = '/api/history/query'; // 通用查询

  // 设备状态
  static const String statusDb30 = '/api/status/db30'; // DB30 通信状态
  static const String statusDb30Devices =
      '/api/status/db30/devices'; // DB30 设备列表
  static const String statusDb41 = '/api/status/db41'; // DB41 数据状态
  static const String statusDb41Devices =
      '/api/status/db41/devices'; // DB41 设备列表
  static const String statusAll = '/api/status/all'; // 全部状态
}

// 控制 API 配置类 (为 control_api.dart 使用)
class ApiConfig {
  static const String baseUrl = 'http://localhost:8082/api';
}
