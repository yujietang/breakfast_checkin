/// 早餐打卡记录
class BreakfastRecord {
  final String id;
  final DateTime checkInTime;
  final String? note;
  final String? photoPath;

  const BreakfastRecord({
    required this.id,
    required this.checkInTime,
    this.note,
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'checkInTime': checkInTime.toIso8601String(),
      'note': note,
      'photoPath': photoPath,
    };
  }

  factory BreakfastRecord.fromMap(Map<String, dynamic> map) {
    return BreakfastRecord(
      id: map['id'] as String,
      checkInTime: DateTime.parse(map['checkInTime'] as String),
      note: map['note'] as String?,
      photoPath: map['photoPath'] as String?,
    );
  }

  BreakfastRecord copyWith({
    String? id,
    DateTime? checkInTime,
    String? note,
    String? photoPath,
  }) {
    return BreakfastRecord(
      id: id ?? this.id,
      checkInTime: checkInTime ?? this.checkInTime,
      note: note ?? this.note,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
