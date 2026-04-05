import 'package:flutter/material.dart';
import '../models/breakfast_record.dart';
import '../models/health_status.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/home/checkin_button.dart';
import '../widgets/home/gallstone_visual.dart';
import '../widgets/home/streak_card.dart';

/// 首页 - 打卡主界面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();
  
  bool _isLoading = true;
  int _currentStreak = 0;
  final int _longestStreak = 12; // 示例数据
  int _totalCheckIns = 0;
  bool _isCheckedIn = false;
  int _missedDays = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final streak = await _db.getCurrentStreak();
    final total = await _db.getTotalCheckIns();
    final missed = await _db.getMissedDays();
    final todayRecord = await _db.getTodayRecord();

    setState(() {
      _currentStreak = streak;
      _totalCheckIns = total;
      _missedDays = missed;
      _isCheckedIn = todayRecord != null;
      _isLoading = false;
    });
  }

  Future<void> _handleCheckIn() async {
    if (_isCheckedIn) return;

    // 创建打卡记录
    final now = DateTime.now();
    await _db.insertRecord(
      BreakfastRecord(
        id: now.millisecondsSinceEpoch.toString(),
        checkInTime: now,
      ),
    );

    // 显示打卡成功通知
    await _notifications.showNotification(
      title: '打卡成功！🎉',
      body: '你今天消灭了胆结石，继续保持健康好习惯～',
    );

    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('打卡成功！继续保持 💪'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final healthStatus = HealthStatus(
      missedDays: _missedDays,
      totalCheckIns: _totalCheckIns,
      lastCheckIn: _isCheckedIn ? DateTime.now() : null,
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // 连续打卡卡片
              StreakCard(
                currentStreak: _currentStreak,
                longestStreak: _longestStreak,
              ),
              
              const SizedBox(height: 32),
              
              // 胆结石视觉展示
              GallstoneVisual(
                missedDays: _missedDays,
                size: 220,
                showPercentage: true,
              ),
              
              const SizedBox(height: 24),
              
              // 状态提示文字
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: healthStatus.level.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: healthStatus.level.color.withAlpha(77),
                    width: 1,
                  ),
                ),
                child: Text(
                  healthStatus.level.tip,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: healthStatus.level.color,
                    height: 1.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 打卡按钮
              CheckInButton(
                isCheckedIn: _isCheckedIn,
                onPressed: _handleCheckIn,
                size: 160,
              ),
              
              const SizedBox(height: 16),
              
              // 打卡时间提示
              if (_isCheckedIn)
                Text(
                  '今日已打卡 ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.success,
                  ),
                )
              else
                const Text(
                  '记得吃早餐，消灭胆结石！',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
