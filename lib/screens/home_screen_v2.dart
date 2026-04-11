import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/user_data.dart';
import '../services/user_data_service.dart';
import '../theme/app_colors.dart';
import '../utils/time_utils.dart';
import '../widgets/home/checkin_button_v2.dart';
import '../widgets/home/gallstone_visual_v2.dart';
import '../widgets/home/streak_card.dart';

/// 升级版首页
class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2>
    with SingleTickerProviderStateMixin {
  final UserDataService _userService = UserDataService();
  bool _isLoading = true;
  UserData? _userData;
  late AnimationController _animationController;
  bool _isDebugVisible = false; // 调试模式开关

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _initData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await _userService.loadUserData();
    
    // 检查漏打
    await _userService.checkMissedDays();
    
    setState(() {
      _userData = _userService.userData;
      _isLoading = false;
    });

    // 免费版：自动接受免责声明，不弹窗
    if (!_userData!.disclaimerAccepted) {
      await _userService.acceptDisclaimer();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _userService.loadUserData();
    setState(() {
      _userData = _userService.userData;
      _isLoading = false;
    });
  }

  Future<void> _handleCheckIn() async {
    if (_userData == null) return;

    // 检查是否在打卡时间窗口内
    if (!TimeUtils.isInCheckInWindow()) {
      _showTimeWindowError();
      return;
    }

    final now = DateTime.now();
    final result = await _userService.addCheckIn(now);

    await _loadData();

    if (!result.success) {
      // 打卡失败（如防作弊检测未通过）
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    _animationController.forward(from: 0);

    if (mounted) {
      _showCheckInSuccess(result.unlockedAchievements);
    }
  }

  Future<void> _handleMakeUp() async {
    if (_userData == null) return;

    final success = await _userService.useEmergencyCard();
    if (success) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('补卡成功！连续打卡保住了~'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('补卡失败，可能没有急救卡了'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showTimeWindowError() {
    final now = DateTime.now();
    final isBefore = now.hour < TimeUtils.checkInStartHour;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('打卡时间限制'),
        content: Text(isBefore
            ? '打卡时间还没到哦~\n请在 ${TimeUtils.formatTime(TimeUtils.checkInStartHour, 0)} 后再来！'
            : '今天的打卡时间已过~\n明天 ${TimeUtils.formatTime(TimeUtils.checkInStartHour, 0)} 再来吧！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _showCheckInSuccess(List<String> newAchievements) {
    // 显示轻量级的成功提示，不弹窗
    String message = '打卡成功！';
    if (newAchievements.isNotEmpty) {
      final achievementName = Achievement.getById(newAchievements.first)?.name ?? '新成就';
      message = '打卡成功！解锁：$achievementName';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showExportDialog() async {
    final csvData = _userService.exportToCSV();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出数据'),
        content: const Text('数据将以CSV格式导出，可用于Excel等软件查看'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 实际导出到文件并分享
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据已导出')),
              );
            },
            child: const Text('导出'),
          ),
        ],
      ),
    );
  }

  /// 漏打状态警告
  Widget _buildMissedWarning(UserData userData) {
    final level = userData.stoneLevel;
    final missedDays = userData.consecutiveMissedDays;
    
    Color warningColor;
    String warningText;
    IconData icon;
    
    if (level >= 4) {
      warningColor = Colors.brown;
      warningText = '⚠️ 紧急！胆囊已被结石填满，连续漏打 $missedDays 天';
      icon = Icons.warning_amber;
    } else if (level >= 3) {
      warningColor = Colors.red;
      warningText = '🔴 警告！大结石形成中，连续漏打 $missedDays 天';
      icon = Icons.error;
    } else if (level >= 2) {
      warningColor = Colors.orange;
      warningText = '🟠 注意！小结石在长大，连续漏打 $missedDays 天';
      icon = Icons.warning;
    } else {
      warningColor = Colors.yellow.shade700;
      warningText = '🟡 提醒：漏打 $missedDays 天，结石开始形成';
      icon = Icons.info;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: warningColor.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningColor.withAlpha(100)),
      ),
      child: Row(
        children: [
          Icon(icon, color: warningColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              warningText,
              style: TextStyle(
                color: warningColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示调试信息
  void _showDebugInfo() {
    final debugInfo = _userService.getDebugInfo();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('调试信息'),
        content: SingleChildScrollView(
          child: Text(debugInfo),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userData = _userData!;
    final isCheckedInToday = userData.checkIns.any(
      (d) => TimeUtils.isToday(d),
    );
    final isInWindow = TimeUtils.isInCheckInWindow();
    final canMakeUp = !isCheckedInToday && 
                      userData.lastCheckInDate != null &&
                      TimeUtils.isYesterday(userData.lastCheckInDate!);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '早餐打卡',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          // 调试按钮（长按触发）
          GestureDetector(
            onLongPress: _showDebugInfo,
            child: IconButton(
              icon: const Icon(Icons.bug_report, color: AppColors.textPrimary),
              onPressed: () {
                // 短按切换调试信息显示
                setState(() => _isDebugVisible = !_isDebugVisible);
              },
              tooltip: '长按查看调试信息',
            ),
          ),
          // 导出按钮
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.textPrimary),
            onPressed: _showExportDialog,
            tooltip: '导出数据',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 连续打卡卡片
              StreakCard(
                currentStreak: userData.currentStreak,
                longestStreak: userData.longestStreak,
              ),
              const SizedBox(height: 16),
              
              // 漏打状态警告（如果有）
              if (userData.consecutiveMissedDays > 0)
                _buildMissedWarning(userData),
              
              const SizedBox(height: 16),
              
              // 胆结石视觉展示
              GallstoneVisualV2(
                userData: userData,
                size: 200,
                showPercentage: true,
              ),
              const SizedBox(height: 32),
              
              // 打卡按钮
              CheckInButtonV2(
                isCheckedIn: isCheckedInToday,
                isInWindow: isInWindow,
                canMakeUp: canMakeUp,
                emergencyCards: userData.weeklyEmergencyCards,
                onPressed: _handleCheckIn,
                onMakeUpPressed: _handleMakeUp,
                size: 140,
              ),
              const SizedBox(height: 24),
              
              // 打卡时间提示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isInWindow
                      ? AppColors.success.withAlpha(20)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isInWindow ? Icons.access_time_filled : Icons.access_time,
                      size: 16,
                      color: isInWindow ? AppColors.success : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '打卡时间: ${TimeUtils.formatTime(TimeUtils.checkInStartHour, 0)} - ${TimeUtils.formatTime(TimeUtils.checkInEndHour, 0)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isInWindow ? AppColors.success : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              

            ],
          ),
        ),
      ),
    );
  }
}
