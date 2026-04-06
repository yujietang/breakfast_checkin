import 'package:flutter/material.dart';
import '../../models/stone_level.dart';
import '../../models/user_data.dart';
import '../../theme/app_colors.dart';

/// 升级版的胆结石视觉组件
class GallstoneVisualV2 extends StatelessWidget {
  final UserData userData;
  final double size;
  final bool showPercentage;
  final bool animate;

  const GallstoneVisualV2({
    super.key,
    required this.userData,
    this.size = 220,
    this.showPercentage = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final stoneLevel = StoneLevel.fromLevel(userData.stoneLevel);
    final skin = StoneSkin.getById(userData.currentSkin);
    
    // 检查是否有权限显示高级别结石
    final canViewFullLevel = userData.isPremiumValid || stoneLevel.isFree;
    final displayLevel = canViewFullLevel 
        ? stoneLevel 
        : StoneLevel.allLevels[2]; // 免费用户最高看到Level 2

    return Column(
      children: [
        // 胆囊可视化
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                displayLevel.color.withAlpha(50),
                displayLevel.color.withAlpha(20),
                Colors.transparent,
              ],
              stops: const [0.3, 0.6, 1.0],
            ),
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 外圈
                Container(
                  width: size * 0.85,
                  height: size * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: displayLevel.color.withAlpha(100),
                      width: 3,
                    ),
                    color: displayLevel.color.withAlpha(20),
                  ),
                ),
                // 胆囊主体（简化图形表示）
                _buildGallbladderShape(displayLevel, skin),
                // 结石（如果存在）
                if (displayLevel.level > 0)
                  _buildStones(displayLevel),
                // 等级指示器
                if (showPercentage)
                  Positioned(
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: displayLevel.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        displayLevel.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 幽默文案
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            displayLevel.humorText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: displayLevel.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // 付费提示（如果受限）
        if (!canViewFullLevel && userData.stoneLevel > 2)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: AppColors.warning,
                ),
                SizedBox(width: 4),
                Text(
                  '升级会员查看完整状态',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGallbladderShape(StoneLevel level, StoneSkin? skin) {
    // 简化版胆囊图形
    return Container(
      width: size * 0.6,
      height: size * 0.75,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFB8E6B8), // 胆囊绿
            const Color(0xFF7CB342).withAlpha(200),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(60),
          topRight: Radius.circular(40),
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: level.color.withAlpha(100),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 内部阴影/纹理效果
          Positioned(
            top: size * 0.1,
            left: size * 0.15,
            child: Container(
              width: size * 0.25,
              height: size * 0.35,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withAlpha(100),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStones(StoneLevel level) {
    final stoneCount = level.level == 1 ? 3 : level.level * 4;
    final stoneSize = size * 0.08 * (level.sizePercent / 100 + 0.5);

    return Stack(
      children: List.generate(
        stoneCount,
        (index) {
          // 计算结石位置（随机分布在胆囊内）
          final angle = (index / stoneCount) * 2 * 3.14159;
          final radius = size * 0.15 * (0.5 + (index % 3) * 0.25);
          final x = radius * cos(angle);
          final y = radius * sin(angle) + size * 0.05;

          return Positioned(
            left: size * 0.5 + x - stoneSize / 2,
            top: size * 0.5 + y - stoneSize / 2,
            child: Container(
              width: stoneSize,
              height: stoneSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    level.color.withAlpha(200),
                    level.color,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: level.color.withAlpha(150),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 简化计算
double cos(double angle) => _cosValues[(angle * 2).toInt() % 8];
double sin(double angle) => _sinValues[(angle * 2).toInt() % 8];

const _cosValues = [1.0, 0.7, 0.0, -0.7, -1.0, -0.7, 0.0, 0.7];
const _sinValues = [0.0, 0.7, 1.0, 0.7, 0.0, -0.7, -1.0, -0.7];
