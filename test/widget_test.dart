import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:breakfast_checkin/models/health_status.dart';

void main() {
  group('HealthStatus Tests', () {
    test('Healthy status when 0 missed days', () {
      final status = HealthStatus(missedDays: 0);
      expect(status.isHealthy, true);
      expect(status.level, GallstoneLevel.healthy);
      expect(status.stoneSizePercent, 0);
    });

    test('Tiny stone after 1 missed day', () {
      final status = HealthStatus(missedDays: 1);
      expect(status.isHealthy, false);
      expect(status.level, GallstoneLevel.tiny);
      expect(status.stoneSizePercent, 10);
    });

    test('Huge stone after 5+ missed days', () {
      final status = HealthStatus(missedDays: 5);
      expect(status.level, GallstoneLevel.huge);
      expect(status.stoneSizePercent, 85);
    });
  });

  group('GallstoneLevel Tests', () {
    test('Level names are correct', () {
      expect(GallstoneLevel.healthy.displayName, '健康');
      expect(GallstoneLevel.tiny.displayName, '微小结石');
      expect(GallstoneLevel.huge.displayName, '巨大结石');
    });

    test('fromMissedDays returns correct level', () {
      expect(GallstoneLevelExtension.fromMissedDays(0), GallstoneLevel.healthy);
      expect(GallstoneLevelExtension.fromMissedDays(2), GallstoneLevel.small);
      expect(GallstoneLevelExtension.fromMissedDays(4), GallstoneLevel.large);
      expect(GallstoneLevelExtension.fromMissedDays(10), GallstoneLevel.huge);
    });
  });
}
