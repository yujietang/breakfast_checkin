import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user_data.dart';
import '../models/achievement.dart';
import '../utils/time_utils.dart';
import 'missed_checkin_detector.dart';
import 'secure_storage_service.dart';
import 'anti_cheat_service.dart';

/// 用户数据服务
class UserDataService extends ChangeNotifier {
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  final SecureStorageService _secureStorage = SecureStorageService();
  final AntiCheatService _antiCheat = AntiCheatService();
  
  UserData _userData = const UserData();
  bool _isLoaded = false;

  UserData get userData => _userData;
  bool get isLoaded => _isLoaded;

  /// 初始化加载用户数据
  Future<void> loadUserData() async {
    if (_isLoaded) return;
    
    // 尝试从安全存储加载
    final secureData = await _secureStorage.getSecureMap(
      SecureStorageKeys.userData,
    );
    
    if (secureData != null) {
      try {
        _userData = UserData.fromMap(secureData);
      } catch (e) {
        debugPrint('加载加密用户数据失败: $e');
        _userData = const UserData();
      }
    }

    // 重置每周急救卡
    _resetWeeklyEmergencyCardIfNeeded();
    
    _isLoaded = true;
    notifyListeners();
  }

  /// 保存用户数据（加密存储）
  Future<void> saveUserData() async {
    await _secureStorage.setSecureMap(
      SecureStorageKeys.userData,
      _userData.toMap(),
    );
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
  Future<CheckInResult> addCheckIn(DateTime dateTime) async {
    // 1. 防作弊检测
    final antiCheatResult = _antiCheat.checkCanCheckIn(
      _userData.lastCheckInDate ?? DateTime(1970),
    );
    
    if (!antiCheatResult.isAllowed) {
      return CheckInResult(
        success: false,
        message: antiCheatResult.reason,
        unlockedAchievements: [],
      );
    }

    // 2. 验证打卡时间合理性
    if (!_antiCheat.isCheckInTimeValid(dateTime, _userData.lastCheckInDate)) {
      return CheckInResult(
        success: false,
        message: '⚠️ 打卡时间异常，请检查设备时间',
        unlockedAchievements: [],
      );
    }

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
    final unlockedAchievements = _checkAchievements(
      recovered: recovered, 
      earlyHour: dateTime.hour,
    );

    // 检查皮肤解锁
    _checkSkinUnlocks(unlockedAchievements);

    return CheckInResult(
      success: true,
      message: '打卡成功！',
      unlockedAchievements: unlockedAchievements,
    );
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
    final result = MissedCheckInDetector.detect(_userData);
    
    if (result.hasMissed) {
      _userData = _userData.copyWith(
        missedDays: result.totalMissedDays,
        consecutiveMissedDays: result.consecutiveMissedDays,
        currentStreak: 0, // 连续打卡中断
      );
      await saveUserData();
      
      if (kDebugMode) {
        debugPrint('【漏打卡检测】检测到漏打！');
        debugPrint(MissedCheckInDetector.getDebugInfo(_userData));
      }
    }
  }
  
  /// 获取漏打卡调试信息
  String getDebugInfo() {
    return MissedCheckInDetector.getDebugInfo(_userData);
  }

  /// 检查皮肤解锁（成就达成时自动解锁）
  void _checkSkinUnlocks(List<String> unlockedAchievements) {
    final currentSkins = List<String>.from(_userData.purchasedSkins);
    var hasNewSkin = false;

    for (final achievementId in unlockedAchievements) {
      final skinId = _getSkinIdForAchievement(achievementId);
      if (skinId != null && !currentSkins.contains(skinId)) {
        currentSkins.add(skinId);
        hasNewSkin = true;
        
        if (kDebugMode) {
          debugPrint('【皮肤解锁】成就 $achievementId 解锁皮肤 $skinId');
        }
      }
    }

    // 检查连续打卡解锁
    final streakSkin = _getSkinIdForStreak(_userData.currentStreak);
    if (streakSkin != null && !currentSkins.contains(streakSkin)) {
      currentSkins.add(streakSkin);
      hasNewSkin = true;
    }

    // 检查累计打卡解锁
    final totalCheckIns = _userData.checkIns.toSet().length;
    final totalSkin = _getSkinIdForTotalCheckIns(totalCheckIns);
    if (totalSkin != null && !currentSkins.contains(totalSkin)) {
      currentSkins.add(totalSkin);
      hasNewSkin = true;
    }

    if (hasNewSkin) {
      _userData = _userData.copyWith(purchasedSkins: currentSkins);
      saveUserData();
    }
  }

  /// 成就对应皮肤映射
  String? _getSkinIdForAchievement(String achievementId) {
    final mapping = {
      'streak_7': 'gold',      // 7天完美 → 黄金胆囊
      'streak_30': 'crystal',  // 30天勇士 → 水晶结石
      'streak_100': 'rainbow', // 百日战神 → 彩虹胆囊
      'survivor': 'blackhole', // 结石幸存者 → 黑洞吞噬
    };
    return mapping[achievementId];
  }

  /// 连续打卡对应皮肤
  String? _getSkinIdForStreak(int streak) {
    if (streak >= 7) return 'gold';
    return null;
  }

  /// 累计打卡对应皮肤
  String? _getSkinIdForTotalCheckIns(int total) {
    if (total >= 30) return 'crystal';
    if (total >= 50) return 'rainbow';
    return null;
  }

  /// 分享奖励：获得急救卡
  Future<void> rewardForShare() async {
    // 分享奖励：获得1张急救卡
    final newCards = _userData.emergencyCards + 1;
    _userData = _userData.copyWith(emergencyCards: newCards);
    await saveUserData();
  }

  /// 邀请奖励：解锁限定皮肤
  Future<void> rewardForInvite() async {
    // 邀请奖励：解锁黑洞吞噬皮肤
    final currentSkins = List<String>.from(_userData.purchasedSkins);
    if (!currentSkins.contains('blackhole')) {
      currentSkins.add('blackhole');
      _userData = _userData.copyWith(purchasedSkins: currentSkins);
      await saveUserData();
    }
  }

  /// 获取防作弊调试信息
  String getAntiCheatDebugInfo() {
    return _antiCheat.getDebugInfo();
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

  /// 购买皮肤（免费版：直接解锁）
  Future<bool> purchaseSkin(String skinId) async {
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

  /// 升级会员（免费版：已废弃，保持兼容）
  Future<void> upgradePremium(DateTime expiryDate) async {
    // 免费版：所有功能已开放，此方法保留以保持兼容
    debugPrint('【注意】免费版无需升级会员');
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

/// 打卡结果
class CheckInResult {
  final bool success;
  final String message;
  final List<String> unlockedAchievements;

  const CheckInResult({
    required this.success,
    required this.message,
    required this.unlockedAchievements,
  });
}
