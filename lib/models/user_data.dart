/// 用户数据模型
class UserData {
  final List<DateTime> checkIns; // 打卡日期列表
  final int currentStreak; // 当前连续天数
  final int longestStreak; // 历史最高
  final int missedDays; // 累计漏打（影响结石等级）
  final int consecutiveMissedDays; // 连续漏打天数
  final String currentSkin; // 当前皮肤ID
  final bool isPremium; // 是否会员
  final DateTime? premiumExpiry; // 会员到期日
  final int emergencyCards; // 剩余急救卡数量
  final DateTime? lastEmergencyCardUsed; // 上次使用急救卡时间
  final List<String> unlockedAchievements; // 已解锁成就ID列表
  final List<String> purchasedSkins; // 已购买皮肤列表
  final bool disclaimerAccepted; // 是否接受免责声明
  final DateTime? lastCheckInDate; // 最后打卡日期

  const UserData({
    this.checkIns = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.missedDays = 0,
    this.consecutiveMissedDays = 0,
    this.currentSkin = 'default',
    this.isPremium = false,
    this.premiumExpiry,
    this.emergencyCards = 1, // 每周1张急救卡
    this.lastEmergencyCardUsed,
    this.unlockedAchievements = const [],
    this.purchasedSkins = const ['default'],
    this.disclaimerAccepted = false,
    this.lastCheckInDate,
  });

  /// 计算结石等级 (0-4)
  /// Level 0: 无结石（连续打卡≥7天或连续漏打为0）
  /// Level 1: 砂砾状（漏1天）
  /// Level 2: 小结石（漏2-3天）
  /// Level 3: 大结石（漏4-6天）
  /// Level 4: 胆囊充满（漏≥7天）
  int get stoneLevel {
    if (currentStreak >= 7) return 0;
    if (consecutiveMissedDays == 0) return 0;
    if (consecutiveMissedDays == 1) return 1;
    if (consecutiveMissedDays <= 3) return 2;
    if (consecutiveMissedDays <= 6) return 3;
    return 4;
  }

  /// 本周是否已使用过急救卡
  bool get usedEmergencyCardThisWeek {
    if (lastEmergencyCardUsed == null) return false;
    final now = DateTime.now();
    final daysSinceLastUse = now.difference(lastEmergencyCardUsed!).inDays;
    return daysSinceLastUse < 7;
  }

  /// 本周剩余的急救卡数量
  int get weeklyEmergencyCards {
    if (isPremium) return 999; // 会员无限补卡
    if (usedEmergencyCardThisWeek) return 0;
    return emergencyCards;
  }

  /// 会员是否有效
  bool get isPremiumValid {
    if (!isPremium) return false;
    if (premiumExpiry == null) return false;
    return DateTime.now().isBefore(premiumExpiry!);
  }

  Map<String, dynamic> toMap() {
    return {
      'checkIns': checkIns.map((e) => e.toIso8601String()).toList(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'missedDays': missedDays,
      'consecutiveMissedDays': consecutiveMissedDays,
      'currentSkin': currentSkin,
      'isPremium': isPremium,
      'premiumExpiry': premiumExpiry?.toIso8601String(),
      'emergencyCards': emergencyCards,
      'lastEmergencyCardUsed': lastEmergencyCardUsed?.toIso8601String(),
      'unlockedAchievements': unlockedAchievements,
      'purchasedSkins': purchasedSkins,
      'disclaimerAccepted': disclaimerAccepted,
      'lastCheckInDate': lastCheckInDate?.toIso8601String(),
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      checkIns: (map['checkIns'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          [],
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      missedDays: map['missedDays'] as int? ?? 0,
      consecutiveMissedDays: map['consecutiveMissedDays'] as int? ?? 0,
      currentSkin: map['currentSkin'] as String? ?? 'default',
      isPremium: map['isPremium'] as bool? ?? false,
      premiumExpiry: map['premiumExpiry'] != null
          ? DateTime.parse(map['premiumExpiry'] as String)
          : null,
      emergencyCards: map['emergencyCards'] as int? ?? 1,
      lastEmergencyCardUsed: map['lastEmergencyCardUsed'] != null
          ? DateTime.parse(map['lastEmergencyCardUsed'] as String)
          : null,
      unlockedAchievements: (map['unlockedAchievements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      purchasedSkins: (map['purchasedSkins'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          ['default'],
      disclaimerAccepted: map['disclaimerAccepted'] as bool? ?? false,
      lastCheckInDate: map['lastCheckInDate'] != null
          ? DateTime.parse(map['lastCheckInDate'] as String)
          : null,
    );
  }

  UserData copyWith({
    List<DateTime>? checkIns,
    int? currentStreak,
    int? longestStreak,
    int? missedDays,
    int? consecutiveMissedDays,
    String? currentSkin,
    bool? isPremium,
    DateTime? premiumExpiry,
    int? emergencyCards,
    DateTime? lastEmergencyCardUsed,
    List<String>? unlockedAchievements,
    List<String>? purchasedSkins,
    bool? disclaimerAccepted,
    DateTime? lastCheckInDate,
  }) {
    return UserData(
      checkIns: checkIns ?? this.checkIns,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      missedDays: missedDays ?? this.missedDays,
      consecutiveMissedDays: consecutiveMissedDays ?? this.consecutiveMissedDays,
      currentSkin: currentSkin ?? this.currentSkin,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      emergencyCards: emergencyCards ?? this.emergencyCards,
      lastEmergencyCardUsed: lastEmergencyCardUsed ?? this.lastEmergencyCardUsed,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      purchasedSkins: purchasedSkins ?? this.purchasedSkins,
      disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
      lastCheckInDate: lastCheckInDate ?? this.lastCheckInDate,
    );
  }
}
