import 'package:flutter/material.dart';

/// 应用配色方案 - 温暖的早餐主题
class AppColors {
  // 主色调 - 温暖的早餐色系
  static const Color primary = Color(0xFFFFA726); // 橙色 - 活力
  static const Color secondary = Color(0xFFFFCC80); // 浅橙 - 柔和
  static const Color accent = Color(0xFFFF7043); // 深橙 - 强调

  // 背景色
  static const Color background = Color(0xFFFDF6E3); // 米白
  static const Color scaffoldBackground = Color(0xFFF5EDE0); // 稍深的米白
  static const Color cardBackground = Color(0xFFFFFFFF); // 纯白卡片

  // 功能色
  static const Color success = Color(0xFF66BB6A); // 打卡成功绿
  static const Color warning = Color(0xFFFFCA28); // 警告黄
  static const Color danger = Color(0xFFEF5350); // 漏打卡红
  static const Color error = Color(0xFFEF5350); // 错误红（同danger）
  
  // 渐变用色
  static const Color primaryDark = Color(0xFFF57C00); // 深橙色

  // 文字色
  static const Color textPrimary = Color(0xFF3E2723); // 深棕
  static const Color textSecondary = Color(0xFF8D6E63); // 浅棕
  static const Color textHint = Color(0xFFBDBDBD); // 提示灰

  // 胆结石等级颜色
  static const Color healthy = Color(0xFF66BB6A); // 健康绿
  static const Color stoneTiny = Color(0xFFFFF176); // 微小黄
  static const Color stoneSmall = Color(0xFFFFB74D); // 小橙
  static const Color stoneMedium = Color(0xFFFF8A65); // 中橙红
  static const Color stoneLarge = Color(0xFFE57373); // 大红
  static const Color stoneHuge = Color(0xFF8D6E63); // 巨大棕

  // 阴影色
  static const Color shadowLight = Color(0x1F000000);
  static const Color shadowMedium = Color(0x3D000000);
}
