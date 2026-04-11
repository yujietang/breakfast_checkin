import '../models/user_data.dart';
import '../utils/time_utils.dart';

/// 漏打卡检测器 - 专门处理漏打卡逻辑
class MissedCheckInDetector {
  /// 检测漏打卡状态
  /// 
  /// 返回：
  /// - hasMissed: 是否漏打卡
  /// - consecutiveMissedDays: 连续漏打天数
  /// - missedDays: 累计漏打天数
  static MissedCheckInResult detect(UserData userData) {
    final lastCheckIn = userData.lastCheckInDate;
    
    // 从未打卡过
    if (lastCheckIn == null) {
      return MissedCheckInResult(
        hasMissed: false,
        consecutiveMissedDays: 0,
        totalMissedDays: userData.missedDays,
        reason: '从未打卡',
      );
    }

    final today = TimeUtils.startOfDay(DateTime.now());
    final lastCheckInDay = TimeUtils.startOfDay(lastCheckIn);

    // 今天已打卡
    if (TimeUtils.isSameDay(lastCheckInDay, today)) {
      return MissedCheckInResult(
        hasMissed: false,
        consecutiveMissedDays: 0,
        totalMissedDays: userData.missedDays,
        reason: '今天已打卡',
      );
    }

    // 计算距离上次打卡的天数
    final daysSinceLastCheckIn = today.difference(lastCheckInDay).inDays;

    // 昨天打卡了，今天还没打（不算漏打，可能还在打卡窗口内）
    if (daysSinceLastCheckIn == 1) {
      // 检查是否已过打卡窗口（11:00之后算漏打）
      final now = DateTime.now();
      if (now.hour >= TimeUtils.checkInEndHour) {
        // 已过打卡时间，算漏打1天
        return MissedCheckInResult(
          hasMissed: true,
          consecutiveMissedDays: 1,
          totalMissedDays: userData.missedDays + 1,
          reason: '昨天打卡，今天已过打卡时间（11:00后）',
        );
      } else {
        // 还在打卡窗口内，不算漏打
        return MissedCheckInResult(
          hasMissed: false,
          consecutiveMissedDays: 0,
          totalMissedDays: userData.missedDays,
          reason: '昨天打卡，今天还在打卡窗口内（11:00前）',
        );
      }
    }

    // 漏打多天
    if (daysSinceLastCheckIn > 1) {
      // daysSinceLastCheckIn = 2 表示：昨天和前天都没打
      // 连续漏打天数 = daysSinceLastCheckIn - 1
      final consecutiveMissed = daysSinceLastCheckIn - 1;
      
      return MissedCheckInResult(
        hasMissed: true,
        consecutiveMissedDays: consecutiveMissed,
        totalMissedDays: userData.missedDays + consecutiveMissed,
        reason: '连续漏打 $consecutiveMissed 天（上次打卡：${TimeUtils.formatDate(lastCheckInDay)}）',
      );
    }

    // 异常情况（ shouldn't happen ）
    return MissedCheckInResult(
      hasMissed: false,
      consecutiveMissedDays: userData.consecutiveMissedDays,
      totalMissedDays: userData.missedDays,
      reason: '未知状态（daysSinceLastCheckIn: $daysSinceLastCheckIn）',
    );
  }

  /// 获取调试信息
  static String getDebugInfo(UserData userData) {
    final result = detect(userData);
    final now = DateTime.now();
    
    return '''
【漏打卡检测调试信息】
当前时间：${TimeUtils.formatDate(now)} ${TimeUtils.formatTime(now.hour, now.minute)}
上次打卡：${userData.lastCheckInDate != null ? TimeUtils.formatDate(userData.lastCheckInDate!) : '无'}

检测结果：
- 是否漏打：${result.hasMissed ? '是 ⚠️' : '否 ✅'}
- 连续漏打天数：${result.consecutiveMissedDays}
- 累计漏打天数：${result.totalMissedDays}
- 检测原因：${result.reason}

当前数据：
- stoneLevel: ${userData.stoneLevel}
- currentStreak: ${userData.currentStreak}
- consecutiveMissedDays: ${userData.consecutiveMissedDays}
- missedDays: ${userData.missedDays}
''';
  }
}

/// 漏打卡检测结果
class MissedCheckInResult {
  final bool hasMissed;
  final int consecutiveMissedDays;
  final int totalMissedDays;
  final String reason;

  const MissedCheckInResult({
    required this.hasMissed,
    required this.consecutiveMissedDays,
    required this.totalMissedDays,
    required this.reason,
  });
}
