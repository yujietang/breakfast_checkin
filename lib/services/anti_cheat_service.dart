import 'dart:math';
import 'package:flutter/foundation.dart';
import '../utils/time_utils.dart';

/// 防作弊检测服务
/// 
/// 检测方式：
/// 1. 系统时间倒退检测
/// 2. 异常快速打卡检测
/// 3. 时间跳跃检测（跨度过大）
class AntiCheatService {
  static final AntiCheatService _instance = AntiCheatService._internal();
  factory AntiCheatService() => _instance;
  AntiCheatService._internal();

  // 存储上次打开时间
  static const String _lastOpenTimeKey = 'last_app_open_time';
  static const String _lastCheckInTimeKey = 'last_check_in_timestamp';
  static const String _cheatDetectedCountKey = 'cheat_detected_count';
  static const String _cheatFrozenUntilKey = 'cheat_frozen_until';

  // 作弊检测阈值
  static const int _maxRapidCheckInSeconds = 5; // 5秒内重复打卡视为异常
  static const int _maxTimeJumpHours = 48; // 超过48小时的时间跳跃需确认
  static const int _freezeHours = 24; // 检测到作弊后冻结24小时

  /// 检查是否可以打卡
  /// 
  /// 返回：
  /// - isAllowed: 是否允许打卡
  /// - reason: 如果不允许，原因说明
  /// - cheatType: 作弊类型（如果有）
  CheckResult checkCanCheckIn(DateTime lastCheckInTime) {
    final now = DateTime.now();

    // 1. 检查系统时间是否倒退
    final lastOpenTime = _getLastOpenTime();
    if (lastOpenTime != null && now.isBefore(lastOpenTime)) {
      _recordCheat('system_time_backwards');
      return CheckResult(
        isAllowed: false,
        reason: '⚠️ 检测到系统时间异常，请检查设备时间设置',
        cheatType: CheatType.systemTimeBackwards,
      );
    }

    // 2. 检查是否被冻结
    final frozenUntil = _getFrozenUntil();
    if (frozenUntil != null && now.isBefore(frozenUntil)) {
      final remaining = frozenUntil.difference(now);
      return CheckResult(
        isAllowed: false,
        reason: '⏰ 由于异常操作，打卡功能已暂停，剩余 ${_formatDuration(remaining)}',
        cheatType: CheatType.frozen,
      );
    }

    // 3. 检查异常快速打卡
    if (lastCheckInTime != DateTime(1970)) {
      final secondsSinceLastCheckIn = now.difference(lastCheckInTime).inSeconds;
      if (secondsSinceLastCheckIn < _maxRapidCheckInSeconds && secondsSinceLastCheckIn > 0) {
        _recordCheat('rapid_checkin');
        return CheckResult(
          isAllowed: false,
          reason: '⚡ 打卡太频繁了，请稍后再试',
          cheatType: CheatType.rapidCheckIn,
        );
      }
    }

    // 4. 检查时间跳跃（可选提示）
    if (lastOpenTime != null) {
      final hoursSinceLastOpen = now.difference(lastOpenTime).inHours;
      if (hoursSinceLastOpen > _maxTimeJumpHours) {
        // 只是记录，不阻止
        if (kDebugMode) {
          debugPrint('【防作弊】检测到长时间未打开：$hoursSinceLastOpen 小时');
        }
      }
    }

    // 更新最后打开时间
    _updateLastOpenTime(now);

    return CheckResult(
      isAllowed: true,
      reason: '✅ 检测通过',
    );
  }

  /// 验证打卡时间合理性
  /// 
  /// 用于检测是否试图在非法时间打卡
  bool isCheckInTimeValid(DateTime checkInTime, DateTime? lastCheckInTime) {
    final now = DateTime.now();

    // 1. 打卡时间不能是未来
    if (checkInTime.isAfter(now.add(const Duration(minutes: 1)))) {
      return false;
    }

    // 2. 打卡时间不能是太久以前（超过24小时）
    if (checkInTime.isBefore(now.subtract(const Duration(hours: 24)))) {
      return false;
    }

    // 3. 如果是补卡，检查是否在允许范围内
    if (lastCheckInTime != null) {
      final daysSinceLastCheckIn = TimeUtils.startOfDay(checkInTime)
          .difference(TimeUtils.startOfDay(lastCheckInTime))
          .inDays;
      
      // 只允许补昨天
      if (daysSinceLastCheckIn > 1) {
        return false;
      }
    }

    return true;
  }

  /// 记录作弊行为
  void _recordCheat(String cheatType) {
    if (kDebugMode) {
      debugPrint('【防作弊】检测到作弊：$cheatType');
    }

    // TODO: 实际项目中应该记录到本地存储，多次作弊后冻结账号
    // 简化为立即冻结24小时
    _freezeAccount();
  }

  /// 冻结账号
  void _freezeAccount() {
    final frozenUntil = DateTime.now().add(const Duration(hours: _freezeHours));
    // TODO: 使用加密存储保存冻结时间
    if (kDebugMode) {
      debugPrint('【防作弊】账号已冻结至：$frozenUntil');
    }
  }

  /// 获取最后打开时间
  DateTime? _getLastOpenTime() {
    // TODO: 从加密存储中读取
    return null;
  }

  /// 更新最后打开时间
  void _updateLastOpenTime(DateTime time) {
    // TODO: 保存到加密存储
  }

  /// 获取冻结截止时间
  DateTime? _getFrozenUntil() {
    // TODO: 从加密存储中读取
    return null;
  }

  /// 格式化时间显示
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}小时${duration.inMinutes % 60}分钟';
    }
    return '${duration.inMinutes}分钟';
  }

  /// 获取防作弊状态信息（调试用）
  String getDebugInfo() {
    final now = DateTime.now();
    final lastOpen = _getLastOpenTime();
    
    return '''
【防作弊检测状态】
当前时间：${TimeUtils.formatDate(now)} ${TimeUtils.formatTime(now.hour, now.minute)}
上次打开：${lastOpen != null ? TimeUtils.formatDate(lastOpen) : '首次打开'}

检测规则：
- 系统时间倒退：禁止打卡
- 5秒内重复打卡：禁止打卡
- 超过48小时未打开：记录日志
- 作弊惩罚：冻结24小时
'''
;
  }
}

/// 检测结果
class CheckResult {
  final bool isAllowed;
  final String reason;
  final CheatType? cheatType;

  const CheckResult({
    required this.isAllowed,
    required this.reason,
    this.cheatType,
  });
}

/// 作弊类型
enum CheatType {
  systemTimeBackwards, // 系统时间倒退
  rapidCheckIn, // 快速重复打卡
  timeJump, // 时间跳跃
  frozen, // 账号被冻结
}
