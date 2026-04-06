import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 免责声明弹窗
class DisclaimerDialog extends StatelessWidget {
  final VoidCallback onAccepted;

  const DisclaimerDialog({
    super.key,
    required this.onAccepted,
  });

  /// 显示免责声明
  static Future<void> show(BuildContext context, VoidCallback onAccepted) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DisclaimerDialog(onAccepted: onAccepted),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.health_and_safety,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              '重要声明',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withAlpha(77),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '本App为习惯养成游戏，不构成医疗建议',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '使用须知：',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('本应用旨在通过游戏化方式帮助您养成吃早餐的习惯'),
              _buildBulletPoint('应用中的"胆结石"仅为虚拟概念，用于视觉反馈'),
              _buildBulletPoint('如有真实健康问题，请咨询专业医生'),
              _buildBulletPoint('所有数据默认仅存储在本地设备'),
              const SizedBox(height: 16),
              const Text(
                '隐私说明：',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('打卡数据仅存储在您的设备上'),
              _buildBulletPoint('我们不会上传您的个人健康数据'),
              _buildBulletPoint('您可以随时导出或删除您的数据'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 退出应用
              Navigator.of(context).pop();
            },
            child: const Text(
              '不同意',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onAccepted();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('我已阅读并同意'),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
