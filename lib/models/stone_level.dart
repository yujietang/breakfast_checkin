import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 胆结石等级定义 (5级)
/// Level 0: 无结石（连续打卡≥7天）
/// Level 1: 砂砾状（漏1天）
/// Level 2: 小结石（漏2-3天）
/// Level 3: 大结石（漏4-6天）
/// Level 4: 胆囊充满（漏≥7天）
class StoneLevel {
  final int level; // 0-4
  final String name; // 等级名称
  final String assetPath; // 对应资源路径
  final String description; // 描述文案
  final String humorText; // 幽默文案
  final Color color; // 等级颜色
  final double sizePercent; // 结石大小百分比
  final bool isFree; // 免费版是否可见

  const StoneLevel({
    required this.level,
    required this.name,
    required this.assetPath,
    required this.description,
    required this.humorText,
    required this.color,
    required this.sizePercent,
    this.isFree = true,
  });

  /// 所有等级定义
  static const List<StoneLevel> allLevels = [
    StoneLevel(
      level: 0,
      name: '无结石',
      assetPath: 'assets/images/gallstone/level0.png',
      description: '胆囊健康，状态良好',
      humorText: '你的胆囊正在为你鼓掌！继续保持~ 👏',
      color: AppColors.healthy,
      sizePercent: 0,
      isFree: true,
    ),
    StoneLevel(
      level: 1,
      name: '砂砾状',
      assetPath: 'assets/images/gallstone/level1.png',
      description: '微小结晶开始形成',
      humorText: '你的胆囊开始抱怨了："喂，早餐呢？" ⚠️',
      color: AppColors.stoneTiny,
      sizePercent: 15,
      isFree: true,
    ),
    StoneLevel(
      level: 2,
      name: '小结石',
      assetPath: 'assets/images/gallstone/level2.png',
      description: '小结石已经形成',
      humorText: '结石在长大！不吃早餐真的会有"结石"哦！😰',
      color: AppColors.stoneSmall,
      sizePercent: 35,
      isFree: true,
    ),
    StoneLevel(
      level: 3,
      name: '大结石',
      assetPath: 'assets/images/gallstone/level3.png',
      description: '结石已经很明显了',
      humorText: '警告！你的"胆结石"快成精了，快打卡消灭它！😱',
      color: AppColors.stoneLarge,
      sizePercent: 60,
      isFree: false, // 付费版才能看到
    ),
    StoneLevel(
      level: 4,
      name: '胆囊充满',
      assetPath: 'assets/images/gallstone/level4.png',
      description: '胆囊快被结石填满了',
      humorText: '紧急！你的胆囊正在开"结石派对"！马上吃早餐！💥',
      color: AppColors.stoneHuge,
      sizePercent: 90,
      isFree: false, // 付费版才能看到
    ),
  ];

  /// 根据等级获取定义
  static StoneLevel fromLevel(int level) {
    if (level < 0 || level >= allLevels.length) {
      return allLevels[0];
    }
    return allLevels[level];
  }

  /// 根据连续漏打天数获取等级
  static StoneLevel fromMissedDays(int consecutiveMissedDays) {
    if (consecutiveMissedDays == 0) return allLevels[0];
    if (consecutiveMissedDays == 1) return allLevels[1];
    if (consecutiveMissedDays <= 3) return allLevels[2];
    if (consecutiveMissedDays <= 6) return allLevels[3];
    return allLevels[4];
  }

  /// 获取下一个等级（用于升级动画）
  StoneLevel? get nextLevel {
    if (level >= allLevels.length - 1) return null;
    return allLevels[level + 1];
  }

  /// 获取上一个等级（用于降级动画）
  StoneLevel? get previousLevel {
    if (level <= 0) return null;
    return allLevels[level - 1];
  }

  @override
  String toString() => 'StoneLevel(level: $level, name: $name)';
}

/// 皮肤主题定义
class StoneSkin {
  final String id;
  final String name;
  final String description;
  final double price;
  final String previewAsset;
  final Map<int, String> levelAssets; // 各等级对应的资源

  const StoneSkin({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.previewAsset,
    required this.levelAssets,
  });

  /// 所有可用皮肤
  static final List<StoneSkin> allSkins = [
    const StoneSkin(
      id: 'default',
      name: '经典胆囊',
      description: '默认风格，清新自然',
      price: 0,
      previewAsset: 'assets/images/skins/default_preview.png',
      levelAssets: {
        0: 'assets/images/gallstone/level0.png',
        1: 'assets/images/gallstone/level1.png',
        2: 'assets/images/gallstone/level2.png',
        3: 'assets/images/gallstone/level3.png',
        4: 'assets/images/gallstone/level4.png',
      },
    ),
    const StoneSkin(
      id: 'gold',
      name: '黄金胆囊',
      description: '奢华金色主题，尊贵体验',
      price: 12,
      previewAsset: 'assets/images/skins/gold_preview.png',
      levelAssets: {
        0: 'assets/images/skins/gold/level0.png',
        1: 'assets/images/skins/gold/level1.png',
        2: 'assets/images/skins/gold/level2.png',
        3: 'assets/images/skins/gold/level3.png',
        4: 'assets/images/skins/gold/level4.png',
      },
    ),
    const StoneSkin(
      id: 'crystal',
      name: '水晶结石',
      description: '晶莹剔透，美轮美奂',
      price: 12,
      previewAsset: 'assets/images/skins/crystal_preview.png',
      levelAssets: {
        0: 'assets/images/skins/crystal/level0.png',
        1: 'assets/images/skins/crystal/level1.png',
        2: 'assets/images/skins/crystal/level2.png',
        3: 'assets/images/skins/crystal/level3.png',
        4: 'assets/images/skins/crystal/level4.png',
      },
    ),
    const StoneSkin(
      id: 'blackhole',
      name: '黑洞吞噬',
      description: '神秘宇宙风格',
      price: 12,
      previewAsset: 'assets/images/skins/blackhole_preview.png',
      levelAssets: {
        0: 'assets/images/skins/blackhole/level0.png',
        1: 'assets/images/skins/blackhole/level1.png',
        2: 'assets/images/skins/blackhole/level2.png',
        3: 'assets/images/skins/blackhole/level3.png',
        4: 'assets/images/skins/blackhole/level4.png',
      },
    ),
  ];

  static StoneSkin? getById(String id) {
    try {
      return allSkins.firstWhere((s) => s.id == id);
    } catch (_) {
      return allSkins.first;
    }
  }
}
