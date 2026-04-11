import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_data.dart';
import '../utils/time_utils.dart';

/// 分享服务
/// 
/// 提供打卡分享、邀请好友等功能
class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  /// 分享打卡成就卡片
  /// 
  /// 生成带二维码的打卡卡片图片，分享到社交媒体
  static Future<void> shareCheckInCard({
    required UserData userData,
    required int currentStreak,
    GlobalKey? repaintKey,
  }) async {
    String shareText = '''
🌟 我已完成早餐打卡！

📅 连续打卡：$currentStreak 天
🎯 当前状态：${_getStatusText(userData.stoneLevel)}

⏰ 早餐时间：05:00-11:00
💪 坚持吃早餐，养成健康习惯！

#早餐打卡 #健康习惯 #胆结石预警
''';

    // 如果有截图key，尝试截图分享
    if (repaintKey != null) {
      try {
        final image = await _captureWidget(repaintKey);
        if (image != null) {
          await Share.shareXFiles(
            [XFile.fromData(image, mimeType: 'image/png')],
            text: shareText,
          );
          return;
        }
      } catch (e) {
        debugPrint('截图分享失败: $e');
      }
    }

    // 纯文本分享
    await Share.share(shareText);
  }

  /// 分享邀请好友
  /// 
  /// 生成邀请链接和文案
  static Future<void> shareInvite({String? inviteCode}) async {
    final code = inviteCode ?? _generateInviteCode();
    
    String inviteText = '''
🎁 邀请你一起养成吃早餐的好习惯！

我正在使用「胆结石早餐打卡」App：
✅ 每天05:00-11:00打卡吃早餐
✅ 漏打卡结石会长大（游戏化提醒）
✅ 100%免费，零广告

📲 下载链接：https://github.com/yujietang/breakfast_checkin
🎫 我的邀请码：$code

一起健康生活吧！💪
''';

    await Share.share(inviteText);
  }

  /// 分享应用下载
  static Future<void> shareApp() async {
    String appText = '''
🌟 推荐一个超实用的健康App

「胆结石早餐打卡」

💡 核心功能：
• 每天早餐打卡，养成好习惯
• 漏打卡胆囊会长"结石"（游戏化提醒）
• 连续打卡解锁成就和皮肤
• 数据本地存储，隐私安全

✨ 亮点：
✅ 100%免费
✅ 零广告打扰
✅ 界面清爽简洁

📲 下载：https://github.com/yujietang/breakfast_checkin

#健康 #早餐 #习惯养成 #自律
''';

    await Share.share(appText);
  }

  /// 导出数据分享
  static Future<void> shareExportedData(String csvData) async {
    await Share.share(
      csvData,
      subject: '早餐打卡记录_${TimeUtils.formatDate(DateTime.now())}',
    );
  }

  /// 截图widget
  static Future<Uint8List?> _captureWidget(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() 
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('截图失败: $e');
      return null;
    }
  }

  /// 生成邀请码
  static String _generateInviteCode() {
    final now = DateTime.now();
    final random = now.millisecond % 10000;
    return 'BC${now.year % 100}${now.month}${now.day}$random';
  }

  /// 获取状态描述
  static String _getStatusText(int stoneLevel) {
    final texts = [
      '健康胆囊 🟢',
      '砂砾沉淀 🟡',
      '小结石 🟠',
      '大结石 🔴',
      '胆囊充满 🟤',
    ];
    return texts[stoneLevel.clamp(0, 4)];
  }
}

/// 分享卡片组件（用于截图分享）
class ShareCard extends StatelessWidget {
  final UserData userData;
  final int streak;

  const ShareCard({
    super.key,
    required this.userData,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7CB342), Color(0xFF558B2F)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            const Text(
              '🌟 今日早餐打卡成功',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 连续天数
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '$streak',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '连续打卡天数',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // 状态
            Text(
              ShareService._getStatusText(userData.stoneLevel),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            
            // 底部信息
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Text(
                  '胆结石早餐打卡',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
