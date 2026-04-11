import 'package:flutter/material.dart';
import '../models/reminder_setting.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

/// 提醒设置页面
class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();
  
  List<ReminderSetting> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final reminders = await _db.getAllReminders();
      if (mounted) {
        setState(() {
          _reminders = reminders;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载提醒失败: $e');
      if (mounted) {
        setState(() {
          _reminders = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('提醒设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addReminder,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reminders.length,
                  itemBuilder: (context, index) {
                    return _buildReminderCard(_reminders[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          const Text(
            '还没有设置提醒',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _addReminder,
            icon: const Icon(Icons.add),
            label: const Text('添加提醒'),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(ReminderSetting reminder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: reminder.isEnabled
                ? AppColors.primary.withAlpha(20)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.alarm,
            color: reminder.isEnabled ? AppColors.primary : AppColors.textHint,
          ),
        ),
        title: Text(
          '${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time.minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: reminder.isEnabled
                ? AppColors.textPrimary
                : AppColors.textHint,
          ),
        ),
        subtitle: Text(
          _getRepeatText(reminder),
          style: TextStyle(
            color: reminder.isEnabled
                ? AppColors.textSecondary
                : AppColors.textHint,
          ),
        ),
        trailing: Switch(
          value: reminder.isEnabled,
          onChanged: (value) => _toggleReminder(reminder, value),
          activeColor: AppColors.primary,
        ),
        onTap: () => _editReminder(reminder),
        onLongPress: () => _deleteReminder(reminder),
      ),
    );
  }

  String _getRepeatText(ReminderSetting reminder) {
    if (reminder.isDaily) return '每天';
    if (reminder.isWeekdays) return '工作日';
    if (reminder.repeatDays.length == 2 &&
        reminder.repeatDays.contains(0) &&
        reminder.repeatDays.contains(7)) {
      return '周末';
    }
    return '每周 ${reminder.repeatDays.length} 天';
  }

  Future<void> _addReminder() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 30),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      final reminder = ReminderSetting(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        time: time,
        isEnabled: true,
      );

      await _db.updateReminder(reminder);
      await _notifications.scheduleDailyReminder(reminder);
      
      _loadReminders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已设置 ${time.hour}:${time.minute.toString().padLeft(2, '0')} 提醒'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _editReminder(ReminderSetting reminder) async {
    final time = await showTimePicker(
      context: context,
      initialTime: reminder.time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      final updated = reminder.copyWith(time: time);
      await _db.updateReminder(updated);
      await _notifications.scheduleDailyReminder(updated);
      _loadReminders();
    }
  }

  Future<void> _toggleReminder(ReminderSetting reminder, bool enabled) async {
    final updated = reminder.copyWith(isEnabled: enabled);
    await _db.updateReminder(updated);
    
    if (enabled) {
      await _notifications.scheduleDailyReminder(updated);
    } else {
      await _notifications.cancelReminder(updated.id);
    }
    
    _loadReminders();
  }

  Future<void> _deleteReminder(ReminderSetting reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除提醒'),
        content: const Text('确定要删除这个提醒吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteReminder(reminder.id);
      await _notifications.cancelReminder(reminder.id);
      _loadReminders();
    }
  }
}
