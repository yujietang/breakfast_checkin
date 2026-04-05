import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/breakfast_record.dart';
import '../models/reminder_setting.dart';

/// 数据库服务
/// 
/// 注意：Web平台不支持SQLite，使用内存存储作为降级方案
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  
  // Web/测试环境使用内存存储
  final List<BreakfastRecord> _memoryRecords = [];
  final List<ReminderSetting> _memoryReminders = [
    const ReminderSetting(
      id: 'default',
      time: TimeOfDay(hour: 7, minute: 30),
      isEnabled: true,
      label: '早餐提醒',
    ),
  ];

  /// 是否使用内存存储（Web/测试环境）
  bool get _useMemoryStorage => kIsWeb;

  Future<Database> get database async {
    if (_useMemoryStorage) {
      throw UnsupportedError('Web平台不支持SQLite数据库');
    }
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'breakfast_checkin.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 创建打卡记录表
    await db.execute('''
      CREATE TABLE breakfast_records (
        id TEXT PRIMARY KEY,
        check_in_time TEXT NOT NULL,
        note TEXT,
        photo_path TEXT
      )
    ''');

    // 创建提醒设置表
    await db.execute('''
      CREATE TABLE reminder_settings (
        id TEXT PRIMARY KEY,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        repeat_days TEXT NOT NULL,
        label TEXT
      )
    ''');

    // 插入默认提醒（早上7:30）
    await db.insert('reminder_settings', {
      'id': 'default',
      'hour': 7,
      'minute': 30,
      'is_enabled': 1,
      'repeat_days': '1,2,3,4,5,6,7',
      'label': '早餐提醒',
    });
  }

  // ==================== 打卡记录操作 ====================

  /// 添加打卡记录
  Future<void> insertRecord(BreakfastRecord record) async {
    if (_useMemoryStorage) {
      _memoryRecords.add(record);
      return;
    }
    final db = await database;
    await db.insert(
      'breakfast_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有打卡记录
  Future<List<BreakfastRecord>> getAllRecords() async {
    if (_useMemoryStorage) {
      return List.unmodifiable(_memoryRecords);
    }
    final db = await database;
    final maps = await db.query('breakfast_records', orderBy: 'check_in_time DESC');
    return maps.map((m) => BreakfastRecord.fromMap(m)).toList();
  }

  /// 获取今日打卡记录
  Future<BreakfastRecord?> getTodayRecord() async {
    if (_useMemoryStorage) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      return _memoryRecords.where((r) {
        return r.checkInTime.isAfter(today) && r.checkInTime.isBefore(tomorrow);
      }).firstOrNull;
    }
    
    final db = await database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final maps = await db.query(
      'breakfast_records',
      where: 'check_in_time >= ? AND check_in_time < ?',
      whereArgs: [today.toIso8601String(), tomorrow.toIso8601String()],
      orderBy: 'check_in_time DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return BreakfastRecord.fromMap(maps.first);
  }

  /// 获取某月打卡记录
  Future<List<BreakfastRecord>> getRecordsByMonth(int year, int month) async {
    if (_useMemoryStorage) {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1);
      return _memoryRecords.where((r) {
        return r.checkInTime.isAfter(start) && r.checkInTime.isBefore(end);
      }).toList();
    }
    
    final db = await database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final maps = await db.query(
      'breakfast_records',
      where: 'check_in_time >= ? AND check_in_time < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'check_in_time ASC',
    );

    return maps.map((m) => BreakfastRecord.fromMap(m)).toList();
  }

  /// 获取连续打卡天数
  Future<int> getCurrentStreak() async {
    final records = await getAllRecords();
    if (records.isEmpty) return 0;

    int streak = 0;
    final now = DateTime.now();
    var checkDate = DateTime(now.year, now.month, now.day);

    // 检查今天是否打卡
    final todayRecord = await getTodayRecord();
    if (todayRecord == null) {
      // 今天没打卡，检查昨天
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      streak = 1;
    }

    // 往前检查连续天数
    final sortedRecords = records.toList()
      ..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    
    for (var record in sortedRecords) {
      final recordDate = DateTime(
        record.checkInTime.year,
        record.checkInTime.month,
        record.checkInTime.day,
      );

      if (recordDate == checkDate) {
        if (streak == 0 || recordDate != DateTime(now.year, now.month, now.day)) {
          streak++;
        }
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (recordDate.isBefore(checkDate)) {
        break;
      }
    }

    return streak;
  }

  /// 获取总打卡天数
  Future<int> getTotalCheckIns() async {
    if (_useMemoryStorage) {
      return _memoryRecords.length;
    }
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(DISTINCT DATE(check_in_time)) as count FROM breakfast_records');
    return result.first['count'] as int? ?? 0;
  }

  /// 获取漏打卡天数
  Future<int> getMissedDays() async {
    final records = await getAllRecords();
    if (records.isEmpty) return 0;

    final now = DateTime.now();
    final lastRecord = records.first;
    final lastDate = DateTime(
      lastRecord.checkInTime.year,
      lastRecord.checkInTime.month,
      lastRecord.checkInTime.day,
    );
    final today = DateTime(now.year, now.month, now.day);

    // 如果今天已打卡，漏打卡为0
    final todayRecord = await getTodayRecord();
    if (todayRecord != null) return 0;

    // 计算从上次打卡到今天漏了几天
    final diff = today.difference(lastDate).inDays;
    return diff.clamp(0, 999);
  }

  // ==================== 提醒设置操作 ====================

  /// 获取所有提醒设置
  Future<List<ReminderSetting>> getAllReminders() async {
    if (_useMemoryStorage) {
      return List.unmodifiable(_memoryReminders);
    }
    final db = await database;
    final maps = await db.query('reminder_settings');
    return maps.map((m) => ReminderSetting.fromMap(m)).toList();
  }

  /// 更新提醒设置
  Future<void> updateReminder(ReminderSetting reminder) async {
    if (_useMemoryStorage) {
      final index = _memoryReminders.indexWhere((r) => r.id == reminder.id);
      if (index >= 0) {
        _memoryReminders[index] = reminder;
      } else {
        _memoryReminders.add(reminder);
      }
      return;
    }
    final db = await database;
    await db.insert(
      'reminder_settings',
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 删除提醒
  Future<void> deleteReminder(String id) async {
    if (_useMemoryStorage) {
      _memoryReminders.removeWhere((r) => r.id == id);
      return;
    }
    final db = await database;
    await db.delete(
      'reminder_settings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
