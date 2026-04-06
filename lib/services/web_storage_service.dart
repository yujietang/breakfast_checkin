import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/breakfast_record.dart';

/// Web 端持久化存储服务
/// 使用 shared_preferences（底层是 localStorage）
class WebStorageService {
  static final WebStorageService _instance = WebStorageService._internal();
  factory WebStorageService() => _instance;
  WebStorageService._internal();

  SharedPreferences? _prefs;
  static const String _recordsKey = 'breakfast_records';

  Future<void> init() async {
    if (!kIsWeb) return;
    _prefs = await SharedPreferences.getInstance();
  }

  /// 保存打卡记录
  Future<void> saveRecords(List<BreakfastRecord> records) async {
    if (_prefs == null) return;
    final jsonList = records.map((r) => r.toMap()).toList();
    await _prefs!.setString(_recordsKey, jsonEncode(jsonList));
  }

  /// 读取打卡记录
  List<BreakfastRecord> loadRecords() {
    if (_prefs == null) return [];
    final jsonStr = _prefs!.getString(_recordsKey);
    if (jsonStr == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonStr) as List;
      return jsonList.map((j) => BreakfastRecord.fromMap(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 添加单条记录
  Future<void> addRecord(BreakfastRecord record) async {
    final records = loadRecords();
    records.add(record);
    await saveRecords(records);
  }

  /// 清空记录
  Future<void> clearRecords() async {
    if (_prefs == null) return;
    await _prefs!.remove(_recordsKey);
  }
}
