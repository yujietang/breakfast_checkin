import 'package:flutter/material.dart';

/// 提醒设置
class ReminderSetting {
  final String id;
  final TimeOfDay time;
  final bool isEnabled;
  final List<int> repeatDays; // 0=周日, 1=周一...
  final String? label;

  const ReminderSetting({
    required this.id,
    required this.time,
    this.isEnabled = true,
    this.repeatDays = const [1, 2, 3, 4, 5, 6, 7], // 默认每天
    this.label,
  });

  /// 是否每天提醒
  bool get isDaily => repeatDays.length == 7;

  /// 是否仅工作日提醒
  bool get isWeekdays => repeatDays.length == 5 && 
    !repeatDays.contains(0) && !repeatDays.contains(7);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'isEnabled': isEnabled ? 1 : 0,
      'repeatDays': repeatDays.join(','),
      'label': label,
    };
  }

  factory ReminderSetting.fromMap(Map<String, dynamic> map) {
    return ReminderSetting(
      id: map['id'] as String,
      time: TimeOfDay(
        hour: map['hour'] as int,
        minute: map['minute'] as int,
      ),
      isEnabled: map['isEnabled'] == 1,
      repeatDays: (map['repeatDays'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => int.parse(s))
          .toList(),
      label: map['label'] as String?,
    );
  }

  ReminderSetting copyWith({
    String? id,
    TimeOfDay? time,
    bool? isEnabled,
    List<int>? repeatDays,
    String? label,
  }) {
    return ReminderSetting(
      id: id ?? this.id,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      label: label ?? this.label,
    );
  }
}
