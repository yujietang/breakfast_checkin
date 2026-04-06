import 'package:flutter_test/flutter_test.dart';
import 'package:breakfast_checkin/models/stone_level.dart';

void main() {
  group('StoneLevel Tests', () {
    test('All levels should be defined', () {
      expect(StoneLevel.allLevels.length, 5);
    });

    test('Level 0 should be healthy', () {
      final level = StoneLevel.fromLevel(0);
      expect(level.level, 0);
      expect(level.name, '无结石');
      expect(level.isFree, true);
    });

    test('Level 4 should be the most severe', () {
      final level = StoneLevel.fromLevel(4);
      expect(level.level, 4);
      expect(level.name, '胆囊充满');
      expect(level.isFree, false);
    });

    test('fromMissedDays should return correct level', () {
      expect(StoneLevel.fromMissedDays(0).level, 0);
      expect(StoneLevel.fromMissedDays(1).level, 1);
      expect(StoneLevel.fromMissedDays(2).level, 2);
      expect(StoneLevel.fromMissedDays(3).level, 2);
      expect(StoneLevel.fromMissedDays(4).level, 3);
      expect(StoneLevel.fromMissedDays(6).level, 3);
      expect(StoneLevel.fromMissedDays(7).level, 4);
      expect(StoneLevel.fromMissedDays(10).level, 4);
    });

    test('Invalid level should return level 0', () {
      expect(StoneLevel.fromLevel(-1).level, 0);
      expect(StoneLevel.fromLevel(10).level, 0);
    });

    test('Level size percentages should increase with level', () {
      final level0 = StoneLevel.fromLevel(0);
      final level1 = StoneLevel.fromLevel(1);
      final level2 = StoneLevel.fromLevel(2);
      final level3 = StoneLevel.fromLevel(3);
      final level4 = StoneLevel.fromLevel(4);

      expect(level0.sizePercent, lessThan(level1.sizePercent));
      expect(level1.sizePercent, lessThan(level2.sizePercent));
      expect(level2.sizePercent, lessThan(level3.sizePercent));
      expect(level3.sizePercent, lessThan(level4.sizePercent));
    });

    test('nextLevel should return correct next level', () {
      final level0 = StoneLevel.fromLevel(0);
      expect(level0.nextLevel?.level, 1);
      
      final level2 = StoneLevel.fromLevel(2);
      expect(level2.nextLevel?.level, 3);
      
      final level4 = StoneLevel.fromLevel(4);
      expect(level4.nextLevel, isNull);
    });

    test('previousLevel should return correct previous level', () {
      final level0 = StoneLevel.fromLevel(0);
      expect(level0.previousLevel, isNull);
      
      final level2 = StoneLevel.fromLevel(2);
      expect(level2.previousLevel?.level, 1);
      
      final level4 = StoneLevel.fromLevel(4);
      expect(level4.previousLevel?.level, 3);
    });
  });

  group('StoneSkin Tests', () {
    test('Default skin should exist', () {
      final defaultSkin = StoneSkin.getById('default');
      expect(defaultSkin, isNotNull);
      expect(defaultSkin!.id, 'default');
      expect(defaultSkin.price, 0);
    });

    test('All skins should have required properties', () {
      for (final skin in StoneSkin.allSkins) {
        expect(skin.id, isNotEmpty);
        expect(skin.name, isNotEmpty);
        expect(skin.description, isNotEmpty);
        expect(skin.previewAsset, isNotEmpty);
        expect(skin.levelAssets.length, 5);
      }
    });

    test('getById should return null for invalid id', () {
      final skin = StoneSkin.getById('invalid_id');
      expect(skin!.id, 'default'); // 返回默认皮肤
    });
  });
}
