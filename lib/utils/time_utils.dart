/// 时间工具类
class TimeUtils {
  TimeUtils._();

  /// 早餐打卡时间窗口
  static const int checkInStartHour = 5; // 05:00
  static const int checkInEndHour = 11; // 11:00

  /// 默认提醒时间
  static const int defaultReminderHour = 8; // 08:00
  static const int defaultReminderMinute = 0;

  /// 检查当前是否在打卡时间窗口内 (05:00-11:00)
  static bool isInCheckInWindow([DateTime? dateTime]) {
    final dt = dateTime ?? DateTime.now();
    final hour = dt.hour;
    return hour >= checkInStartHour && hour < checkInEndHour;
  }

  /// 获取下次打卡窗口开始时间
  static DateTime getNextCheckInWindowStart() {
    final now = DateTime.now();
    if (now.hour < checkInStartHour) {
      // 今天还没开始
      return DateTime(now.year, now.month, now.day, checkInStartHour);
    }
    // 明天的窗口
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, checkInStartHour);
  }

  /// 获取打卡窗口结束时间（今天）
  static DateTime getTodayCheckInWindowEnd() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, checkInEndHour);
  }

  /// 检查是否可以补卡（次日00:00-23:59都可以补昨日）
  static bool canMakeUpCheckIn([DateTime? dateTime]) {
    final dt = dateTime ?? DateTime.now();
    // 补卡只能在次日进行
    return true; // 简化逻辑，任何时间都可以补昨天
  }

  /// 检查是否是昨天漏打
  static bool isYesterday(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// 检查是否是今天
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// 检查是否是同一天
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 获取日期的开始（00:00:00）
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 获取日期的结束（23:59:59）
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// 计算连续天数
  static int calculateStreak(List<DateTime> checkIns) {
    if (checkIns.isEmpty) return 0;

    // 按日期排序（降序）
    final sorted = checkIns.map((d) => startOfDay(d)).toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 1;
    DateTime current = sorted.first;

    // 检查今天是否打卡，如果没有，从昨天开始算
    final today = startOfDay(DateTime.now());
    if (current.isBefore(today)) {
      // 今天没打卡，检查是否是昨天
      final yesterday = today.subtract(const Duration(days: 1));
      if (!isSameDay(current, yesterday)) {
        return 0; // 不是昨天打卡的，连续断了
      }
    }

    for (int i = 1; i < sorted.length; i++) {
      final prev = sorted[i];
      final expectedPrev = current.subtract(const Duration(days: 1));
      
      if (isSameDay(prev, expectedPrev)) {
        streak++;
        current = prev;
      } else if (isSameDay(prev, current)) {
        // 同一天多次打卡，跳过
        continue;
      } else {
        break;
      }
    }

    return streak;
  }

  /// 计算连续漏打天数
  static int calculateConsecutiveMissedDays(
    List<DateTime> checkIns, {
    DateTime? lastCheckInDate,
  }) {
    if (checkIns.isEmpty && lastCheckInDate == null) return 0;

    final lastCheckIn = lastCheckInDate ?? 
        (checkIns.isNotEmpty 
            ? checkIns.map((d) => startOfDay(d)).reduce((a, b) => a.isAfter(b) ? a : b)
            : null);
    
    if (lastCheckIn == null) return 0;

    final today = startOfDay(DateTime.now());
    final daysSinceLastCheckIn = today.difference(lastCheckIn).inDays;

    // 如果今天已经打卡，不算漏打
    if (daysSinceLastCheckIn == 0) return 0;

    return daysSinceLastCheckIn - 1; // 减去今天
  }

  /// 获取本周的起始日期（周一）
  static DateTime getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1-7, 周一=1
    return startOfDay(date.subtract(Duration(days: weekday - 1)));
  }

  /// 获取本周的结束日期（周日）
  static DateTime getWeekEnd(DateTime date) {
    final weekday = date.weekday;
    return endOfDay(date.add(Duration(days: 7 - weekday)));
  }

  /// 获取月份的天数
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// 格式化时间为 HH:mm
  static String formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// 格式化日期为 yyyy-MM-dd
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 获取友好的日期描述
  static String getFriendlyDateDescription(DateTime date) {
    final now = DateTime.now();
    final today = startOfDay(now);
    final target = startOfDay(date);

    final diff = today.difference(target).inDays;

    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (diff == 2) return '前天';
    if (diff < 7) return '$diff天前';
    if (diff < 30) return '${diff ~/ 7}周前';
    
    return formatDate(date);
  }
}
