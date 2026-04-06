import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/user_data.dart';
import '../services/user_data_service.dart';
import '../theme/app_colors.dart';
import '../utils/time_utils.dart';
import '../widgets/common/disclaimer_dialog.dart';
import '../widgets/home/checkin_button_v2.dart';
import '../widgets/home/gallstone_visual_v2.dart';
import '../widgets/home/streak_card.dart';
import 'store_screen.dart';

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

    // 检查是否需要显示免责声明
    if (!mounted) return;
    if (!_userData!.disclaimerAccepted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await DisclaimerDialog.show(context, () async {
          await _userService.acceptDisclaimer();
          await _loadData();
        });
      }
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
    final newAchievements = await _userService.addCheckIn(now);

    await _loadData();
    _animationController.forward(from: 0);

    if (mounted) {
      _showCheckInSuccess(newAchievements);
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              '打卡成功！',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '今天又是健康的一天~\n当前连续打卡 ${_userData?.currentStreak ?? 0} 天',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            if (newAchievements.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          '解锁新成就！',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...newAchievements.map((id) {
                      final achievement = Achievement.getById(id);
                      if (achievement == null) return const SizedBox.shrink();
                      return Text(
                        achievement.name,
                        style: const TextStyle(color: AppColors.textSecondary),
                      );
                    }),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('太棒了！'),
              ),
            ),
          ],
        ),
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
          // 导出按钮
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.textPrimary),
            onPressed: _showExportDialog,
            tooltip: '导出数据',
          ),
          // 商店按钮
          IconButton(
            icon: const Icon(Icons.store, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StoreScreen()),
              ).then((_) => _loadData());
            },
            tooltip: '商店',
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
              const SizedBox(height: 24),
              
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
              
              // 会员提示
              if (!userData.isPremiumValid)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withAlpha(30),
                        Colors.orange.withAlpha(20),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.diamond,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '升级会员',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '解锁全部结石等级、无限补卡、去除广告',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const StoreScreen()),
                          ).then((_) => _loadData());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('查看'),
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
