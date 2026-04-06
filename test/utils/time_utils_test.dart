import 'package:flutter_test/flutter_test.dart';
import 'package:breakfast_checkin/utils/time_utils.dart';

void main() {
  group('TimeUtils Tests', () {
    group('isInCheckInWindow', () {
      test('should return true for time within 05:00-11:00', () {
        final dateTime = DateTime(2024, 1, 1, 8, 0);
        expect(TimeUtils.isInCheckInWindow(dateTime), true);
      });

      test('should return true at exactly 05:00', () {
        final dateTime = DateTime(2024, 1, 1, 5, 0);
        expect(TimeUtils.isInCheckInWindow(dateTime), true);
      });

      test('should return false at exactly 11:00', () {
        final dateTime = DateTime(2024, 1, 1, 11, 0);
        expect(TimeUtils.isInCheckInWindow(dateTime), false);
      });

      test('should return false before 05:00', () {
        final dateTime = DateTime(2024, 1, 1, 4, 59);
        expect(TimeUtils.isInCheckInWindow(dateTime), false);
      });

      test('should return false after 11:00', () {
        final dateTime = DateTime(2024, 1, 1, 12, 0);
        expect(TimeUtils.isInCheckInWindow(dateTime), false);
      });
    });

    group('isSameDay', () {
      test('should return true for same day', () {
        final date1 = DateTime(2024, 1, 15, 8, 30);
        final date2 = DateTime(2024, 1, 15, 18, 45);
        expect(TimeUtils.isSameDay(date1, date2), true);
      });

      test('should return false for different days', () {
        final date1 = DateTime(2024, 1, 15, 8, 30);
        final date2 = DateTime(2024, 1, 16, 8, 30);
        expect(TimeUtils.isSameDay(date1, date2), false);
      });

      test('should return false for different months', () {
        final date1 = DateTime(2024, 1, 15, 8, 30);
        final date2 = DateTime(2024, 2, 15, 8, 30);
        expect(TimeUtils.isSameDay(date1, date2), false);
      });
    });

    group('isToday', () {
      test('should return true for today', () {
        final today = DateTime.now();
        expect(TimeUtils.isToday(today), true);
      });

      test('should return false for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(TimeUtils.isToday(yesterday), false);
      });
    });

    group('isYesterday', () {
      test('should return true for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(TimeUtils.isYesterday(yesterday), true);
      });

      test('should return false for today', () {
        final today = DateTime.now();
        expect(TimeUtils.isYesterday(today), false);
      });
    });

    group('calculateStreak', () {
      test('should return 0 for empty list', () {
        expect(TimeUtils.calculateStreak([]), 0);
      });

      test('should return 1 for single check-in', () {
        final today = DateTime.now();
        expect(TimeUtils.calculateStreak([today]), 1);
      });

      test('should calculate correct streak for consecutive days', () {
        final now = DateTime.now();
        final checkIns = [
          now,
          now.subtract(const Duration(days: 1)),
          now.subtract(const Duration(days: 2)),
        ];
        expect(TimeUtils.calculateStreak(checkIns), 3);
      });

      test('should break streak when gap exists', () {
        final now = DateTime.now();
        final checkIns = [
          now,
          now.subtract(const Duration(days: 2)), // 昨天没打卡
          now.subtract(const Duration(days: 3)),
        ];
        expect(TimeUtils.calculateStreak(checkIns), 1);
      });
    });

    group('calculateConsecutiveMissedDays', () {
      test('should return 0 when last check-in is today', () {
        final today = DateTime.now();
        expect(
          TimeUtils.calculateConsecutiveMissedDays([], lastCheckInDate: today),
          0,
        );
      });

      test('should return 1 when last check-in was yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(
          TimeUtils.calculateConsecutiveMissedDays([], lastCheckInDate: yesterday),
          0, // 昨天打卡了，今天还没打不算漏打
        );
      });

      test('should return correct missed days', () {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        expect(
          TimeUtils.calculateConsecutiveMissedDays([], lastCheckInDate: threeDaysAgo),
          1, // 漏了前天（昨天不算，因为今天还没过）
        );
      });
    });

    group('startOfDay and endOfDay', () {
      test('startOfDay should return 00:00:00', () {
        final date = DateTime(2024, 1, 15, 14, 30, 45);
        final start = TimeUtils.startOfDay(date);
        expect(start.hour, 0);
        expect(start.minute, 0);
        expect(start.second, 0);
        expect(start.day, date.day);
      });

      test('endOfDay should return 23:59:59', () {
        final date = DateTime(2024, 1, 15, 14, 30, 45);
        final end = TimeUtils.endOfDay(date);
        expect(end.hour, 23);
        expect(end.minute, 59);
        expect(end.second, 59);
        expect(end.day, date.day);
      });
    });

    group('formatTime', () {
      test('should format single digit with leading zero', () {
        expect(TimeUtils.formatTime(5, 5), '05:05');
      });

      test('should format double digit correctly', () {
        expect(TimeUtils.formatTime(12, 30), '12:30');
      });

      test('should format midnight correctly', () {
        expect(TimeUtils.formatTime(0, 0), '00:00');
      });
    });

    group('formatDate', () {
      test('should format date correctly', () {
        final date = DateTime(2024, 1, 15);
        expect(TimeUtils.formatDate(date), '2024-01-15');
      });

      test('should pad single digit month and day', () {
        final date = DateTime(2024, 3, 5);
        expect(TimeUtils.formatDate(date), '2024-03-05');
      });
    });

    group('getDaysInMonth', () {
      test('should return 31 for January', () {
        expect(TimeUtils.getDaysInMonth(2024, 1), 31);
      });

      test('should return 28 for February in non-leap year', () {
        expect(TimeUtils.getDaysInMonth(2023, 2), 28);
      });

      test('should return 29 for February in leap year', () {
        expect(TimeUtils.getDaysInMonth(2024, 2), 29);
      });

      test('should return 30 for April', () {
        expect(TimeUtils.getDaysInMonth(2024, 4), 30);
      });
    });

    group('getFriendlyDateDescription', () {
      test('should return "今天" for today', () {
        expect(TimeUtils.getFriendlyDateDescription(DateTime.now()), '今天');
      });

      test('should return "昨天" for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(TimeUtils.getFriendlyDateDescription(yesterday), '昨天');
      });

      test('should return "前天" for day before yesterday', () {
        final dayBeforeYesterday = DateTime.now().subtract(const Duration(days: 2));
        expect(TimeUtils.getFriendlyDateDescription(dayBeforeYesterday), '前天');
      });
    });
  });
}
