import 'package:flutter_test/flutter_test.dart';
import 'package:breakfast_checkin/models/user_data.dart';

void main() {
  group('UserData Tests', () {
    test('Default UserData should have correct initial values', () {
      const userData = UserData();
      
      expect(userData.checkIns, isEmpty);
      expect(userData.currentStreak, 0);
      expect(userData.longestStreak, 0);
      expect(userData.missedDays, 0);
      expect(userData.consecutiveMissedDays, 0);
      expect(userData.currentSkin, 'default');
      expect(userData.isPremium, false);
      expect(userData.emergencyCards, 1);
      expect(userData.unlockedAchievements, isEmpty);
      expect(userData.purchasedSkins, contains('default'));
      expect(userData.disclaimerAccepted, false);
    });

    test('stoneLevel should be 0 when currentStreak >= 7', () {
      const userData = UserData(currentStreak: 7, consecutiveMissedDays: 0);
      expect(userData.stoneLevel, 0);
    });

    test('stoneLevel should be 1 when consecutiveMissedDays is 1', () {
      const userData = UserData(consecutiveMissedDays: 1);
      expect(userData.stoneLevel, 1);
    });

    test('stoneLevel should be 2 when consecutiveMissedDays is 2-3', () {
      expect(const UserData(consecutiveMissedDays: 2).stoneLevel, 2);
      expect(const UserData(consecutiveMissedDays: 3).stoneLevel, 2);
    });

    test('stoneLevel should be 3 when consecutiveMissedDays is 4-6', () {
      expect(const UserData(consecutiveMissedDays: 4).stoneLevel, 3);
      expect(const UserData(consecutiveMissedDays: 6).stoneLevel, 3);
    });

    test('stoneLevel should be 4 when consecutiveMissedDays >= 7', () {
      expect(const UserData(consecutiveMissedDays: 7).stoneLevel, 4);
      expect(const UserData(consecutiveMissedDays: 10).stoneLevel, 4);
    });

    test('isPremiumValid should be false when not premium', () {
      const userData = UserData(isPremium: false);
      expect(userData.isPremiumValid, false);
    });

    test('isPremiumValid should be true when premium not expired', () {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final userData = UserData(
        isPremium: true,
        premiumExpiry: futureDate,
      );
      expect(userData.isPremiumValid, true);
    });

    test('isPremiumValid should be false when premium expired', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final userData = UserData(
        isPremium: true,
        premiumExpiry: pastDate,
      );
      expect(userData.isPremiumValid, false);
    });

    test('usedEmergencyCardThisWeek should be false when never used', () {
      const userData = UserData(lastEmergencyCardUsed: null);
      expect(userData.usedEmergencyCardThisWeek, false);
    });

    test('usedEmergencyCardThisWeek should be true when used within 7 days', () {
      final recentDate = DateTime.now().subtract(const Duration(days: 3));
      final userData = UserData(lastEmergencyCardUsed: recentDate);
      expect(userData.usedEmergencyCardThisWeek, true);
    });

    test('usedEmergencyCardThisWeek should be false when used more than 7 days ago', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 10));
      final userData = UserData(lastEmergencyCardUsed: oldDate);
      expect(userData.usedEmergencyCardThisWeek, false);
    });

    test('weeklyEmergencyCards should be 999 for premium users', () {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final userData = UserData(
        isPremium: true,
        premiumExpiry: futureDate,
      );
      expect(userData.weeklyEmergencyCards, 999);
    });

    test('UserData copyWith should work correctly', () {
      const userData = UserData();
      final newUserData = userData.copyWith(
        currentStreak: 5,
        isPremium: true,
      );
      
      expect(newUserData.currentStreak, 5);
      expect(newUserData.isPremium, true);
      expect(newUserData.longestStreak, userData.longestStreak);
    });

    test('UserData toMap and fromMap should work correctly', () {
      final now = DateTime.now();
      final original = UserData(
        checkIns: [now],
        currentStreak: 5,
        longestStreak: 10,
        missedDays: 2,
        consecutiveMissedDays: 1,
        currentSkin: 'gold',
        isPremium: true,
        premiumExpiry: now.add(const Duration(days: 30)),
        emergencyCards: 0,
        lastEmergencyCardUsed: now,
        unlockedAchievements: const ['streak_7'],
        purchasedSkins: const ['default', 'gold'],
        disclaimerAccepted: true,
        lastCheckInDate: now,
      );

      final map = original.toMap();
      final restored = UserData.fromMap(map);

      expect(restored.currentStreak, original.currentStreak);
      expect(restored.longestStreak, original.longestStreak);
      expect(restored.missedDays, original.missedDays);
      expect(restored.consecutiveMissedDays, original.consecutiveMissedDays);
      expect(restored.currentSkin, original.currentSkin);
      expect(restored.isPremium, original.isPremium);
      expect(restored.emergencyCards, original.emergencyCards);
      expect(restored.unlockedAchievements, original.unlockedAchievements);
      expect(restored.purchasedSkins, original.purchasedSkins);
      expect(restored.disclaimerAccepted, original.disclaimerAccepted);
    });
  });
}
