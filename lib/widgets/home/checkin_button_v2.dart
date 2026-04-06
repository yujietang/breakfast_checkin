import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/time_utils.dart';

/// 升级版打卡按钮
class CheckInButtonV2 extends StatelessWidget {
  final bool isCheckedIn;
  final bool isInWindow;
  final VoidCallback onPressed;
  final VoidCallback? onMakeUpPressed;
  final double size;
  final bool canMakeUp;
  final int emergencyCards;

  const CheckInButtonV2({
    super.key,
    required this.isCheckedIn,
    required this.isInWindow,
    required this.onPressed,
    this.onMakeUpPressed,
    this.size = 160,
    this.canMakeUp = false,
    this.emergencyCards = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (isCheckedIn) {
      return _buildCheckedInButton();
    }

    if (isInWindow) {
      return _buildCheckInButton();
    }

    // 不在打卡时间窗口
    if (canMakeUp && emergencyCards > 0) {
      return _buildMakeUpButton();
    }

    return _buildDisabledButton();
  }

  /// 已打卡状态
  Widget _buildCheckedInButton() {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withAlpha(30),
            border: Border.all(
              color: AppColors.success,
              width: 3,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 48,
                ),
                SizedBox(height: 8),
                Text(
                  '已打卡',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 打卡按钮
  Widget _buildCheckInButton() {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(100),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant,
                color: Colors.white,
                size: 40,
              ),
              SizedBox(height: 8),
              Text(
                '吃早餐',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '点击打卡',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 补卡按钮
  Widget _buildMakeUpButton() {
    return Column(
      children: [
        GestureDetector(
          onTap: onMakeUpPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.warning,
                  Colors.orange,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.warning.withAlpha(100),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.healing,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '补打卡',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '使用急救卡',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.warning.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emergency,
                size: 16,
                color: AppColors.warning,
              ),
              const SizedBox(width: 4),
              Text(
                '剩余急救卡: $emergencyCards',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 禁用状态（时间未到或已过）
  Widget _buildDisabledButton() {
    final now = DateTime.now();
    final isBeforeWindow = now.hour < TimeUtils.checkInStartHour;

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
            border: Border.all(
              color: Colors.grey[400]!,
              width: 2,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isBeforeWindow ? Icons.bedtime : Icons.access_time,
                  color: Colors.grey[500],
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  isBeforeWindow ? '太早啦' : '已截止',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isBeforeWindow
                      ? '打卡时间 05:00 开始'
                      : '明日 ${TimeUtils.formatTime(TimeUtils.checkInStartHour, 0)} 再来',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isBeforeWindow && emergencyCards == 0)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '本周急救卡已用完',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
