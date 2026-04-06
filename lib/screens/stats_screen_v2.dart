import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/achievement.dart';
import '../models/user_data.dart';
import '../services/user_data_service.dart';
import '../theme/app_colors.dart';
import '../utils/time_utils.dart';

/// 升级版统计页面
class StatsScreenV2 extends StatefulWidget {
  const StatsScreenV2({super.key});

  @override
  State<StatsScreenV2> createState() => _StatsScreenV2State();
}

class _StatsScreenV2State extends State<StatsScreenV2> {
  final UserDataService _userService = UserDataService();
  bool _isLoading = true;
  UserData? _userData;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _userService.loadUserData();
    setState(() {
      _userData = _userService.userData;
      _isLoading = false;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userData = _userData!;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('统计'),
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 总览卡片
            _buildOverviewCard(userData),
            const SizedBox(height: 24),

            // 日历热力图
            _buildCalendarCard(userData),
            const SizedBox(height: 24),

            // 成就墙
            _buildAchievementsCard(userData),
            const SizedBox(height: 24),

            // 月度趋势图
            _buildMonthlyTrendCard(userData),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(UserData userData) {
    final totalDays = userData.checkIns.isEmpty
        ? 0
        : DateTime.now()
                .difference(userData.checkIns.reduce((a, b) =>
                    a.isBefore(b) ? a : b))
                .inDays +
            1;
    final completionRate = totalDays > 0
        ? (userData.checkIns.toSet().length / totalDays * 100).clamp(0, 100)
        : 0.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '打卡总览',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  userData.checkIns.toSet().length.toString(),
                  '总打卡天数',
                  Icons.calendar_today,
                  AppColors.primary,
                ),
                _buildStatItem(
                  userData.currentStreak.toString(),
                  '当前连续',
                  Icons.local_fire_department,
                  AppColors.warning,
                ),
                _buildStatItem(
                  '${completionRate.toStringAsFixed(1)}%',
                  '完成率',
                  Icons.trending_up,
                  AppColors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCard(UserData userData) {
    final daysInMonth =
        TimeUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final firstWeekday = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    ).weekday;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 月份选择器
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '${_selectedMonth.year}年${_selectedMonth.month}月',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 星期标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['一', '二', '三', '四', '五', '六', '日']
                  .map((d) => SizedBox(
                        width: 32,
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // 日历格子
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: daysInMonth + firstWeekday - 1,
              itemBuilder: (context, index) {
                if (index < firstWeekday - 1) {
                  return const SizedBox.shrink();
                }
                final day = index - firstWeekday + 2;
                final date = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month,
                  day,
                );
                final hasCheckIn = userData.checkIns.any(
                  (d) => TimeUtils.isSameDay(d, date),
                );
                final isToday = TimeUtils.isToday(date);

                return Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasCheckIn
                          ? AppColors.success
                          : isToday
                              ? AppColors.primary.withAlpha(30)
                              : Colors.transparent,
                      border: isToday
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: hasCheckIn
                              ? Colors.white
                              : isToday
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                          fontWeight: hasCheckIn || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // 图例
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('已打卡', AppColors.success),
                const SizedBox(width: 24),
                _buildLegendItem('今天', AppColors.primary),
                const SizedBox(width: 24),
                _buildLegendItem('未打卡', Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsCard(UserData userData) {
    final unlockedIds = userData.unlockedAchievements;
    final unlocked = unlockedIds
        .map((id) => Achievement.getById(id))
        .whereType<Achievement>()
        .toList();
    final locked = Achievement.allAchievements
        .where((a) => !unlockedIds.contains(a.id))
        .toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '成就墙',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${unlocked.length}/${Achievement.allAchievements.length}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 已解锁成就
            if (unlocked.isNotEmpty) ...[
              const Text(
                '已解锁',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: unlocked.map((a) => _buildAchievementBadge(a, true)).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // 未解锁成就
            if (locked.isNotEmpty) ...[
              const Text(
                '待解锁',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: locked
                    .where((a) => !a.isSecret)
                    .map((a) => _buildAchievementBadge(a, false))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(Achievement achievement, bool unlocked) {
    return Tooltip(
      message: '${achievement.name}\n${achievement.description}',
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.4,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: unlocked ? achievement.color.withAlpha(30) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: unlocked
                ? Border.all(color: achievement.color.withAlpha(100))
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                unlocked ? Icons.emoji_events : Icons.lock,
                color: unlocked ? achievement.color : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                achievement.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: unlocked ? achievement.color : Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendCard(UserData userData) {
    // 生成最近6个月的数据
    final now = DateTime.now();
    final monthlyData = <int>[];
    final monthLabels = <String>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final count = userData.checkIns
          .where((d) => d.year == month.year && d.month == month.month)
          .toSet()
          .length;
      monthlyData.add(count);
      monthLabels.add('${month.month}月');
    }

    final maxValue = monthlyData.isEmpty ? 1 : monthlyData.reduce((a, b) => a > b ? a : b);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '月度趋势',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue.toDouble() + 2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.grey[800]!,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${monthLabels[groupIndex]}\n${rod.toY.toInt()}天',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= monthLabels.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            monthLabels[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: monthlyData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: AppColors.primary,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
