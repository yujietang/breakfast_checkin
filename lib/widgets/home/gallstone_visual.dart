import 'package:flutter/material.dart';
import '../../models/health_status.dart';
import '../../theme/app_colors.dart';

/// 胆结石视觉组件
/// 
/// 美术资源到位后，将 _PlaceholderVisual 替换为真实图片
class GallstoneVisual extends StatelessWidget {
  final int missedDays;
  final double size;
  final bool showPercentage;
  final bool animated;

  const GallstoneVisual({
    super.key,
    required this.missedDays,
    this.size = 200,
    this.showPercentage = true,
    this.animated = true,
  });

  GallstoneLevel get level => GallstoneLevelExtension.fromMissedDays(missedDays);

  @override
  Widget build(BuildContext context) {
    // TODO: 美术资源到位后，使用真实图片
    // return Image.asset(
    //   level.imageAsset,
    //   width: size,
    //   height: size,
    //   errorBuilder: (context, error, stackTrace) => 
    //     _PlaceholderVisual(level: level, size: size),
    // );

    return _PlaceholderVisual(
      level: level,
      size: size,
      showPercentage: showPercentage,
      animated: animated,
    );
  }
}

/// 占位实现 - 使用渐变色圆形模拟结石
/// 美术资源到位后删除此组件
class _PlaceholderVisual extends StatelessWidget {
  final GallstoneLevel level;
  final double size;
  final bool showPercentage;
  final bool animated;

  const _PlaceholderVisual({
    required this.level,
    required this.size,
    this.showPercentage = true,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final stoneSize = size * (0.3 + (level.sizePercent / 100) * 0.6);
    final content = Stack(
      alignment: Alignment.center,
      children: [
        // 外圈光晕（健康状态显示绿光，结石状态显示警告色）
        Container(
          width: size * 0.9,
          height: size * 0.9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: level.color.withOpacity(0.15),
          ),
        ),
        // 内圈
        Container(
          width: size * 0.75,
          height: size * 0.75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: level.color.withOpacity(0.1),
            border: Border.all(
              color: level.color.withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
        // 结石主体
        Container(
          width: stoneSize,
          height: stoneSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.3),
              radius: 0.8,
              colors: [
                level.color.withOpacity(0.9),
                level.color,
                level.color.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: level.color.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: showPercentage
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${level.sizePercent.toInt()}%',
                        style: TextStyle(
                          fontSize: stoneSize * 0.35,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      if (level != GallstoneLevel.healthy)
                        Text(
                          '🪨',
                          style: TextStyle(fontSize: stoneSize * 0.25),
                        ),
                    ],
                  )
                : Text(
                    level == GallstoneLevel.healthy ? '✓' : '🪨',
                    style: TextStyle(fontSize: stoneSize * 0.5),
                  ),
          ),
        ),
      ],
    );

    if (animated && level != GallstoneLevel.healthy) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.5 + (value * 0.5),
            child: child,
          );
        },
        child: content,
      );
    }

    return content;
  }
}

/// 小型结石状态指示器（用于列表/卡片）
class GallstoneIndicator extends StatelessWidget {
  final int missedDays;
  final double size;

  const GallstoneIndicator({
    super.key,
    required this.missedDays,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final level = GallstoneLevelExtension.fromMissedDays(missedDays);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: level.color,
        boxShadow: [
          BoxShadow(
            color: level.color.withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: level == GallstoneLevel.healthy
          ? Icon(
              Icons.check,
              size: size * 0.7,
              color: Colors.white,
            )
          : null,
    );
  }
}

/// 健康状态卡片
class HealthStatusCard extends StatelessWidget {
  final HealthStatus status;
  final VoidCallback? onTap;

  const HealthStatusCard({
    super.key,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                GallstoneIndicator(missedDays: status.missedDays, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.level.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: status.level.color,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (status.missedDays > 0)
                        Text(
                          '漏打卡 ${status.missedDays} 天',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              status.level.tip,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
