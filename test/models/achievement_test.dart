import 'package:flutter_test/flutter_test.dart';
import 'package:breakfast_checkin/models/achievement.dart';

void main() {
  group('Achievement Tests', () {
    test('All achievements should have unique IDs', () {
      final ids = Achievement.allAchievements.map((a) => a.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length);
    });

    test('getById should return correct achievement', () {
      final achievement = Achievement.getById('streak_7');
      expect(achievement, isNotNull);
      expect(achievement!.id, 'streak_7');
      expect(achievement.name, '7天完美');
      expect(achievement.type, AchievementType.streak);
      expect(achievement.requirement, 7);
    });

    test('getById should return null for invalid id', () {
      final achievement = Achievement.getById('invalid_id');
      expect(achievement, isNull);
    });

    test('isUnlocked should return correct result', () {
      final achievement = Achievement.getById('streak_7')!;
      expect(achievement.isUnlocked(5), false);
      expect(achievement.isUnlocked(7), true);
      expect(achievement.isUnlocked(10), true);
    });

    test('Streak achievements should have increasing requirements', () {
      final streak7 = Achievement.getById('streak_7')!;
      final streak30 = Achievement.getById('streak_30')!;
      final streak100 = Achievement.getById('streak_100')!;
      final streak365 = Achievement.getById('streak_365')!;

      expect(streak7.requirement, lessThan(streak30.requirement));
      expect(streak30.requirement, lessThan(streak100.requirement));
      expect(streak100.requirement, lessThan(streak365.requirement));
    });

    test('Secret achievements should be marked as secret', () {
      final secretAchievements = Achievement.allAchievements
          .where((a) => a.isSecret)
          .toList();
      
      expect(secretAchievements.isNotEmpty, true);
      for (final achievement in secretAchievements) {
        expect(achievement.isSecret, true);
      }
    });
  });

  group('UserAchievement Tests', () {
    test('UserAchievement toMap and fromMap should work correctly', () {
      final original = UserAchievement(
        achievementId: 'streak_7',
        unlockedAt: DateTime(2024, 1, 1),
        isNew: true,
      );

      final map = original.toMap();
      final restored = UserAchievement.fromMap(map);

      expect(restored.achievementId, original.achievementId);
      expect(restored.isNew, original.isNew);
      expect(restored.unlockedAt.year, original.unlockedAt.year);
      expect(restored.unlockedAt.month, original.unlockedAt.month);
      expect(restored.unlockedAt.day, original.unlockedAt.day);
    });

    test('UserAchievement copyWith should work correctly', () {
      final original = UserAchievement(
        achievementId: 'streak_7',
        unlockedAt: DateTime(2024, 1, 1),
        isNew: true,
      );

      final copy = original.copyWith(isNew: false);
      expect(copy.achievementId, original.achievementId);
      expect(copy.isNew, false);
    });
  });
}
