import 'package:flutter/material.dart';

/// 成就定义
class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconAsset;
  final Color color;
  final AchievementType type;
  final int requirement; // 要求数值
  final bool isSecret; // 是否隐藏成就

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconAsset,
    required this.color,
    required this.type,
    required this.requirement,
    this.isSecret = false,
  });

  /// 所有成就列表
  static final List<Achievement> allAchievements = [
    // 连续打卡成就
    const Achievement(
      id: 'streak_7',
      name: '7天完美',
      description: '连续7天坚持吃早餐',
      iconAsset: 'assets/icons/achievements/streak_7.png',
      color: Colors.green,
      type: AchievementType.streak,
      requirement: 7,
    ),
    const Achievement(
      id: 'streak_30',
      name: '30天勇士',
      description: '连续30天坚持吃早餐',
      iconAsset: 'assets/icons/achievements/streak_30.png',
      color: Colors.blue,
      type: AchievementType.streak,
      requirement: 30,
    ),
    const Achievement(
      id: 'streak_100',
      name: '百日战神',
      description: '连续100天坚持吃早餐',
      iconAsset: 'assets/icons/achievements/streak_100.png',
      color: Colors.purple,
      type: AchievementType.streak,
      requirement: 100,
    ),
    const Achievement(
      id: 'streak_365',
      name: '年度王者',
      description: '连续365天坚持吃早餐',
      iconAsset: 'assets/icons/achievements/streak_365.png',
      color: Colors.orange,
      type: AchievementType.streak,
      requirement: 365,
    ),
    
    // 总打卡成就
    const Achievement(
      id: 'total_50',
      name: '初出茅庐',
      description: '累计打卡50次',
      iconAsset: 'assets/icons/achievements/total_50.png',
      color: Colors.teal,
      type: AchievementType.totalCheckIns,
      requirement: 50,
    ),
    const Achievement(
      id: 'total_200',
      name: '习惯养成',
      description: '累计打卡200次',
      iconAsset: 'assets/icons/achievements/total_200.png',
      color: Colors.indigo,
      type: AchievementType.totalCheckIns,
      requirement: 200,
    ),
    const Achievement(
      id: 'total_500',
      name: ' breakfast大师',
      description: '累计打卡500次',
      iconAsset: 'assets/icons/achievements/total_500.png',
      color: Colors.amber,
      type: AchievementType.totalCheckIns,
      requirement: 500,
    ),
    
    // 结石相关成就
    const Achievement(
      id: 'survivor',
      name: '结石幸存者',
      description: '从Level 4结石状态恢复为健康',
      iconAsset: 'assets/icons/achievements/survivor.png',
      color: Colors.red,
      type: AchievementType.recovery,
      requirement: 1,
    ),
    const Achievement(
      id: 'perfect_month',
      name: '完美一月',
      description: '整个月无漏打',
      iconAsset: 'assets/icons/achievements/perfect_month.png',
      color: Colors.pink,
      type: AchievementType.perfectMonth,
      requirement: 1,
    ),
    
    // 补卡成就
    const Achievement(
      id: 'emergency_master',
      name: '急救专家',
      description: '累计使用10次急救卡',
      iconAsset: 'assets/icons/achievements/emergency.png',
      color: Colors.deepOrange,
      type: AchievementType.emergencyCard,
      requirement: 10,
    ),
    
    // 早起成就
    const Achievement(
      id: 'early_bird',
      name: '早起的鸟儿',
      description: '连续7天在7点前打卡',
      iconAsset: 'assets/icons/achievements/early.png',
      color: Colors.yellow,
      type: AchievementType.earlyBird,
      requirement: 7,
    ),
    
    // 隐藏成就
    const Achievement(
      id: 'night_owl',
      name: '夜猫子?',
      description: '在23:59打卡（真的假的？）',
      iconAsset: 'assets/icons/achievements/owl.png',
      color: Colors.deepPurple,
      type: AchievementType.special,
      requirement: 1,
      isSecret: true,
    ),
  ];

  /// 根据ID获取成就
  static Achievement? getById(String id) {
    try {
      return allAchievements.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 检查是否解锁
  bool isUnlocked(int value) => value >= requirement;
}

/// 成就类型枚举
enum AchievementType {
  streak, // 连续打卡
  totalCheckIns, // 总打卡次数
  recovery, // 从结石恢复
  perfectMonth, // 完美月
  emergencyCard, // 使用急救卡
  earlyBird, // 早起打卡
  special, // 特殊成就
}

/// 用户成就进度
class UserAchievement {
  final String achievementId;
  final DateTime unlockedAt;
  final bool isNew; // 是否新解锁（未查看）

  const UserAchievement({
    required this.achievementId,
    required this.unlockedAt,
    this.isNew = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'achievementId': achievementId,
      'unlockedAt': unlockedAt.toIso8601String(),
      'isNew': isNew,
    };
  }

  factory UserAchievement.fromMap(Map<String, dynamic> map) {
    return UserAchievement(
      achievementId: map['achievementId'] as String,
      unlockedAt: DateTime.parse(map['unlockedAt'] as String),
      isNew: map['isNew'] as bool? ?? false,
    );
  }

  UserAchievement copyWith({
    String? achievementId,
    DateTime? unlockedAt,
    bool? isNew,
  }) {
    return UserAchievement(
      achievementId: achievementId ?? this.achievementId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isNew: isNew ?? this.isNew,
    );
  }
}
