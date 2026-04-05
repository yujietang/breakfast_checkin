import '../theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 胆结石等级
enum GallstoneLevel {
  healthy, // 健康
  tiny, // 微小
  small, // 小
  medium, // 中等
  large, // 大
  huge, // 巨大
}

extension GallstoneLevelExtension on GallstoneLevel {
  /// 根据漏打卡天数获取等级
  static GallstoneLevel fromMissedDays(int days) {
    if (days == 0) return GallstoneLevel.healthy;
    if (days == 1) return GallstoneLevel.tiny;
    if (days == 2) return GallstoneLevel.small;
    if (days == 3) return GallstoneLevel.medium;
    if (days == 4) return GallstoneLevel.large;
    return GallstoneLevel.huge;
  }

  /// 等级名称
  String get displayName {
    switch (this) {
      case GallstoneLevel.healthy:
        return '健康';
      case GallstoneLevel.tiny:
        return '微小结石';
      case GallstoneLevel.small:
        return '小结石';
      case GallstoneLevel.medium:
        return '中等结石';
      case GallstoneLevel.large:
        return '大结石';
      case GallstoneLevel.huge:
        return '巨大结石';
    }
  }

  /// 结石大小百分比 (用于占位显示)
  double get sizePercent {
    switch (this) {
      case GallstoneLevel.healthy:
        return 0;
      case GallstoneLevel.tiny:
        return 10;
      case GallstoneLevel.small:
        return 25;
      case GallstoneLevel.medium:
        return 45;
      case GallstoneLevel.large:
        return 65;
      case GallstoneLevel.huge:
        return 85;
    }
  }

  /// 等级颜色
  Color get color {
    switch (this) {
      case GallstoneLevel.healthy:
        return AppColors.healthy;
      case GallstoneLevel.tiny:
        return AppColors.stoneTiny;
      case GallstoneLevel.small:
        return AppColors.stoneSmall;
      case GallstoneLevel.medium:
        return AppColors.stoneMedium;
      case GallstoneLevel.large:
        return AppColors.stoneLarge;
      case GallstoneLevel.huge:
        return AppColors.stoneHuge;
    }
  }

  /// 提示文案
  String get tip {
    switch (this) {
      case GallstoneLevel.healthy:
        return '继续保持！每天吃早餐是健康的开始 🌟';
      case GallstoneLevel.tiny:
        return '小心！胆结石开始形成了，明天记得吃早餐哦 ⚠️';
      case GallstoneLevel.small:
        return '胆结石在变大！不吃早餐真的会有结石风险 😰';
      case GallstoneLevel.medium:
        return '警告！你的"胆结石"已经很明显了，快打卡消灭它！😱';
      case GallstoneLevel.large:
        return '危险！巨大结石形成中！立即打卡拯救你的胆囊！🚨';
      case GallstoneLevel.huge:
        return '紧急！你的胆囊快被结石填满了！马上吃早餐！💥';
    }
  }

  /// 图片资源名称（美术资源到位后使用）
  String get imageAsset {
    return 'assets/images/gallstone/${name}.png';
  }
}

/// 用户健康状态
class HealthStatus {
  final int missedDays; // 连续漏打卡天数
  final DateTime? lastCheckIn; // 最后打卡时间
  final int totalCheckIns; // 总打卡次数

  const HealthStatus({
    this.missedDays = 0,
    this.lastCheckIn,
    this.totalCheckIns = 0,
  });

  /// 当前结石等级
  GallstoneLevel get level => GallstoneLevelExtension.fromMissedDays(missedDays);

  /// 是否健康
  bool get isHealthy => missedDays == 0;

  /// 结石大小百分比
  double get stoneSizePercent => level.sizePercent;

  Map<String, dynamic> toMap() {
    return {
      'missedDays': missedDays,
      'lastCheckIn': lastCheckIn?.toIso8601String(),
      'totalCheckIns': totalCheckIns,
    };
  }

  factory HealthStatus.fromMap(Map<String, dynamic> map) {
    return HealthStatus(
      missedDays: map['missedDays'] as int? ?? 0,
      lastCheckIn: map['lastCheckIn'] != null
          ? DateTime.parse(map['lastCheckIn'] as String)
          : null,
      totalCheckIns: map['totalCheckIns'] as int? ?? 0,
    );
  }

  HealthStatus copyWith({
    int? missedDays,
    DateTime? lastCheckIn,
    int? totalCheckIns,
  }) {
    return HealthStatus(
      missedDays: missedDays ?? this.missedDays,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      totalCheckIns: totalCheckIns ?? this.totalCheckIns,
    );
  }
}
