import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';
import '../models/achievement.dart';
import '../utils/time_utils.dart';

/// 用户数据服务
class UserDataService extends ChangeNotifier {
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  static const String _userDataKey = 'user_data_v2';
  
  UserData _userData = const UserData();
  bool _isLoaded = false;

  UserData get userData => _userData;
  bool get isLoaded => _isLoaded;

  /// 初始化加载用户数据
  Future<void> loadUserData() async {
    if (_isLoaded) return;
    
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_userDataKey);
    
    if (jsonStr != null) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _userData = UserData.fromMap(map);
      } catch (e) {
        debugPrint('加载用户数据失败: $e');
        _userData = const UserData();
      }
    }

    // 重置每周急救卡
    _resetWeeklyEmergencyCardIfNeeded();
    
    _isLoaded = true;
    notifyListeners();
  }

  /// 保存用户数据
  Future<void> saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(_userData.toMap()));
    notifyListeners();
  }

  /// 重置每周急救卡
  void _resetWeeklyEmergencyCardIfNeeded() {
    if (_userData.lastEmergencyCardUsed == null) return;
    
    final daysSinceLastUse = DateTime.now()
        .difference(_userData.lastEmergencyCardUsed!)
        .inDays;
    
    if (daysSinceLastUse >= 7 && _userData.emergencyCards == 0) {
      _userData = _userData.copyWith(emergencyCards: 1);
    }
  }

  /// 添加打卡记录
  Future<List<String>> addCheckIn(DateTime dateTime) async {
    final checkIns = List<DateTime>.from(_userData.checkIns)..add(dateTime);
    
    // 计算新的连续天数
    final newStreak = TimeUtils.calculateStreak(checkIns);
    final newLongestStreak = newStreak > _userData.longestStreak 
        ? newStreak 
        : _userData.longestStreak;
    
    // 计算连续漏打天数（打卡后归零）
    final consecutiveMissedDays = 0;
    
    // 检查是否是恢复（从Level 4到健康）
    final wasLevel4 = _userData.stoneLevel == 4;
    final recovered = wasLevel4 && newStreak >= 1;

    _userData = _userData.copyWith(
      checkIns: checkIns,
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      consecutiveMissedDays: consecutiveMissedDays,
      lastCheckInDate: dateTime,
    );

    await saveUserData();

    // 检查解锁的成就
    return _checkAchievements(recovered: recovered, earlyHour: dateTime.hour);
  }

  /// 使用急救卡补卡（补昨天）
  Future<bool> useEmergencyCard() async {
    // 检查是否有急救卡
    if (_userData.weeklyEmergencyCards <= 0) {
      return false;
    }

    // 计算昨天的日期
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStart = TimeUtils.startOfDay(yesterday);

    // 检查昨天是否已经打卡
    final alreadyCheckedIn = _userData.checkIns.any(
      (d) => TimeUtils.isSameDay(d, yesterday),
    );
    if (alreadyCheckedIn) {
      return false; // 昨天已经打过卡
    }

    // 创建昨天的补卡记录（标记为补卡，时间设为11:59）
    final makeUpTime = DateTime(yesterday.year, yesterday.month, yesterday.day, 11, 59);
    final checkIns = List<DateTime>.from(_userData.checkIns)..add(makeUpTime);

    // 计算新的连续天数
    final newStreak = TimeUtils.calculateStreak(checkIns);

    _userData = _userData.copyWith(
      checkIns: checkIns,
      currentStreak: newStreak,
      consecutiveMissedDays: 0,
      emergencyCards: _userData.emergencyCards - 1,
      lastEmergencyCardUsed: DateTime.now(),
    );

    await saveUserData();
    return true;
  }

  /// 检查漏打（每日调用）
  Future<void> checkMissedDays() async {
    if (_userData.lastCheckInDate == null) return;

    final today = TimeUtils.startOfDay(DateTime.now());
    final lastCheckIn = TimeUtils.startOfDay(_userData.lastCheckInDate!);

    // 如果今天还没过打卡时间，不算漏打
    if (TimeUtils.isSameDay(lastCheckIn, today)) return;

    final daysDiff = today.difference(lastCheckIn).inDays;
    
    if (daysDiff > 1) {
      // 漏打了
      final missedDays = _userData.missedDays + daysDiff - 1;
      final consecutiveMissedDays = daysDiff - 1;

      _userData = _userData.copyWith(
        missedDays: missedDays,
        consecutiveMissedDays: consecutiveMissedDays,
        currentStreak: 0, // 连续打卡中断
      );

      await saveUserData();
    }
  }

  /// 检查成就解锁
  List<String> _checkAchievements({bool recovered = false, int? earlyHour}) {
    final unlocked = <String>[];
    final totalCheckIns = _userData.checkIns.length;

    for (final achievement in Achievement.allAchievements) {
      if (_userData.unlockedAchievements.contains(achievement.id)) continue;

      bool shouldUnlock = false;

      switch (achievement.type) {
        case AchievementType.streak:
          shouldUnlock = _userData.currentStreak >= achievement.requirement;
          break;
        case AchievementType.totalCheckIns:
          shouldUnlock = totalCheckIns >= achievement.requirement;
          break;
        case AchievementType.recovery:
          shouldUnlock = recovered;
          break;
        case AchievementType.emergencyCard:
          // 需要额外统计使用次数
          break;
        case AchievementType.earlyBird:
          shouldUnlock = earlyHour != null && 
                        earlyHour < 7 && 
                        _userData.currentStreak >= achievement.requirement;
          break;
        case AchievementType.perfectMonth:
          // 需要检查整月
          shouldUnlock = _checkPerfectMonth();
          break;
        case AchievementType.special:
          // 特殊成就单独处理
          break;
      }

      if (shouldUnlock) {
        unlocked.add(achievement.id);
      }
    }

    if (unlocked.isNotEmpty) {
      final newAchievements = List<String>.from(_userData.unlockedAchievements)
        ..addAll(unlocked);
      _userData = _userData.copyWith(unlockedAchievements: newAchievements);
      saveUserData();
    }

    return unlocked;
  }

  /// 检查是否完美月
  bool _checkPerfectMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final daysInMonth = TimeUtils.getDaysInMonth(now.year, now.month);

    for (int day = 1; day <= now.day && day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      final hasCheckIn = _userData.checkIns.any(
        (d) => TimeUtils.isSameDay(d, date),
      );
      if (!hasCheckIn) return false;
    }

    return now.day == daysInMonth; // 必须是月底
  }

  /// 解锁特殊成就
  Future<void> unlockSpecialAchievement(String achievementId) async {
    if (_userData.unlockedAchievements.contains(achievementId)) return;

    final newAchievements = List<String>.from(_userData.unlockedAchievements)
      ..add(achievementId);
    _userData = _userData.copyWith(unlockedAchievements: newAchievements);
    await saveUserData();
  }

  /// 购买皮肤
  Future<bool> purchaseSkin(String skinId) async {
    // 这里应该调用支付接口，简化处理
    if (_userData.purchasedSkins.contains(skinId)) return true;

    final newSkins = List<String>.from(_userData.purchasedSkins)..add(skinId);
    _userData = _userData.copyWith(purchasedSkins: newSkins);
    await saveUserData();
    return true;
  }

  /// 切换皮肤
  Future<void> switchSkin(String skinId) async {
    if (!_userData.purchasedSkins.contains(skinId)) return;
    _userData = _userData.copyWith(currentSkin: skinId);
    await saveUserData();
  }

  /// 升级会员
  Future<void> upgradePremium(DateTime expiryDate) async {
    _userData = _userData.copyWith(
      isPremium: true,
      premiumExpiry: expiryDate,
    );
    await saveUserData();
  }

  /// 接受免责声明
  Future<void> acceptDisclaimer() async {
    _userData = _userData.copyWith(disclaimerAccepted: true);
    await saveUserData();
  }

  /// 获取某天的打卡记录
  List<DateTime> getCheckInsForDay(DateTime date) {
    return _userData.checkIns.where(
      (d) => TimeUtils.isSameDay(d, date),
    ).toList();
  }

  /// 检查某天是否已打卡
  bool hasCheckInOnDay(DateTime date) {
    return _userData.checkIns.any((d) => TimeUtils.isSameDay(d, date));
  }

  /// 获取本月打卡天数
  int getMonthlyCheckInCount(int year, int month) {
    return _userData.checkIns.where((d) => 
      d.year == year && d.month == month,
    ).toSet().length; // 去重，每天只算一次
  }

  /// 导出数据为CSV格式
  String exportToCSV() {
    final buffer = StringBuffer();
    buffer.writeln('日期,时间,状态');

    // 获取所有打卡日期（去重）
    final checkInDays = _userData.checkIns
        .map((d) => TimeUtils.startOfDay(d))
        .toSet()
        .toList()
      ..sort();

    for (final date in checkInDays) {
      final checkIns = getCheckInsForDay(date);
      for (final checkIn in checkIns) {
        buffer.writeln(
          '${TimeUtils.formatDate(checkIn)},'
          '${TimeUtils.formatTime(checkIn.hour, checkIn.minute)},'
          '已打卡',
        );
      }
    }

    return buffer.toString();
  }

  /// 清除所有数据（重置）
  Future<void> clearAllData() async {
    _userData = const UserData();
    await saveUserData();
  }
}
