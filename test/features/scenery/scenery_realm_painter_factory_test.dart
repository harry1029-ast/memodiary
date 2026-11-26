import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/scenery/models/shanshui_palette.dart';
import 'package:memodiary/features/scenery/painters/ancient_room_painter.dart';
import 'package:memodiary/features/scenery/painters/fenghuang_painter.dart';
import 'package:memodiary/features/scenery/painters/outdoor_street_painter.dart';
import 'package:memodiary/features/scenery/painters/shanshui_atmospheric_effects.dart';
import 'package:memodiary/features/scenery/painters/west_lake_painter.dart';
import 'package:memodiary/features/scenery/widgets/scenery_realm_painter_factory.dart';
import 'package:memodiary/features/scenery/widgets/shanshui_canvas_painter.dart';

void main() {
  group('SceneryRealmDescriptor & SceneryRealmPictureCache', () {
    test('provides descriptors for every ShanshuiRealm with expected policies', () {
      expect(SceneryRealmDescriptor.of(ShanshuiRealm.nature).rippleMinY, 615.0);
      expect(
        SceneryRealmDescriptor.of(ShanshuiRealm.nature).spawnPetalSwirl,
        isFalse,
      );

      expect(SceneryRealmDescriptor.of(ShanshuiRealm.westLake).rippleMinY, 520.0);
      expect(
        SceneryRealmDescriptor.of(ShanshuiRealm.westLake).spawnPetalSwirl,
        isTrue,
      );

      expect(
        SceneryRealmDescriptor.of(ShanshuiRealm.fenghuang).rippleMinY,
        555.0,
      );
      expect(
        SceneryRealmDescriptor.of(ShanshuiRealm.fenghuang).spawnPetalSwirl,
        isTrue,
      );

      expect(SceneryRealmDescriptor.of(ShanshuiRealm.indoor).rippleMinY, isNull);
      expect(
        SceneryRealmDescriptor.of(ShanshuiRealm.indoor).spawnPetalSwirl,
        isTrue,
      );

      expect(SceneryRealmDescriptor.of(ShanshuiRealm.outdoor).rippleMinY, 615.0);
      expect(
        SceneryRealmDescriptor.of(ShanshuiRealm.outdoor).spawnPetalSwirl,
        isTrue,
      );
    });

    test('dispatches every realm to its concrete CustomPainter and caches non-nature static pictures', () {
      final cache = SceneryRealmPictureCache();
      addTearDown(cache.dispose);

      final expectedTypes = <ShanshuiRealm, Type>{
        ShanshuiRealm.nature: ShanshuiCanvasPainter,
        ShanshuiRealm.westLake: WestLakePainter,
        ShanshuiRealm.fenghuang: FenghuangPainter,
        ShanshuiRealm.indoor: AncientRoomPainter,
        ShanshuiRealm.outdoor: OutdoorStreetPainter,
      };

      for (final realm in ShanshuiRealm.values) {
        final atmosphere = ShanshuiAtmosphereState(
          realm: realm,
          season: ShanshuiSeason.spring,
          timeOfDay: ShanshuiTimeOfDay.day,
          weather: ShanshuiWeather.sunny,
        );
        final painter = buildSceneryRealmPainter(
          atmosphere: atmosphere,
          palette: ShanshuiPalette.of(atmosphere.season, atmosphere.timeOfDay),
          cache: cache,
          animationTime: 0.0,
          particles: const [],
          weatherDrops: const [],
          cranes: const [],
          ripples: const [],
          showCalligraphy: true,
          fullPoem: true,
          lightningAlpha: 0.0,
        );
        expect(painter.runtimeType, expectedTypes[realm]);
      }

      expect(cache.contains(ShanshuiRealm.nature), isFalse);
      expect(cache.contains(ShanshuiRealm.westLake), isTrue);
      expect(cache.contains(ShanshuiRealm.fenghuang), isTrue);
      expect(cache.contains(ShanshuiRealm.indoor), isTrue);
      expect(cache.contains(ShanshuiRealm.outdoor), isTrue);
      expect(cache.length, equals(4));

      cache.dispose();
      expect(cache.length, equals(0));
    });

    test('getOrRecord reuses existing ui.Picture for the same realm and skips null', () {
      final cache = SceneryRealmPictureCache();
      addTearDown(cache.dispose);

      int natureCalls = 0;
      expect(
        cache.getOrRecord(ShanshuiRealm.nature, () {
          natureCalls++;
          return null;
        }),
        isNull,
      );
      expect(natureCalls, equals(1));
      expect(cache.contains(ShanshuiRealm.nature), isFalse);

      int recordCalls = 0;
      ui.Picture recordDummy() {
        recordCalls++;
        final recorder = ui.PictureRecorder();
        Canvas(recorder, const Rect.fromLTWH(0, 0, 10, 10));
        return recorder.endRecording();
      }

      final first = cache.getOrRecord(ShanshuiRealm.westLake, recordDummy);
      final second = cache.getOrRecord(ShanshuiRealm.westLake, recordDummy);
      expect(first, isNotNull);
      expect(identical(first, second), isTrue);
      expect(recordCalls, equals(1));
    });
  });

  group('ShanshuiAtmosphericEffects shared calligraphy & seal', () {
    test('splitPoemColumns splits on clause punctuation and falls back to midpoint', () {
      expect(
        ShanshuiAtmosphericEffects.splitPoemColumns('间株杨柳间株桃，水光潋滟晴方好'),
        equals(['间株杨柳间株桃', '水光潋滟晴方好']),
      );
      expect(
        ShanshuiAtmosphericEffects.splitPoemColumns('万名塔下秋波静。虹桥风起落丹枫！'),
        equals(['万名塔下秋波静', '虹桥风起落丹枫']),
      );
      expect(
        ShanshuiAtmosphericEffects.splitPoemColumns('绿蚁新醅酒，红泥小火炉。晚来天欲雪，能饮一杯无'),
        equals(['绿蚁新醅酒红泥小火炉', '晚来天欲雪能饮一杯无']),
      );
      expect(
        ShanshuiAtmosphericEffects.splitPoemColumns('春山如笑水如蓝'),
        equals(['春山如笑', '水如蓝']),
      );
      expect(ShanshuiAtmosphericEffects.splitPoemColumns(''), isEmpty);
    });

    test('drawCinnabarSeal & drawCalligraphyAndSeal render cleanly across 1..4 chars and themes', () {
      const config = SceneryCalligraphyConfig(
        titleX: 1418.0,
        titleY: 58.0,
        poemStartX: 1372.0,
        poemStartY: 66.0,
        sealX: 1408.0,
      );

      for (final isNight in [false, true]) {
        for (final sealText in ['春', '春晓', '苏堤春', '苏堤春晓']) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1500, 1000));
          ShanshuiAtmosphericEffects.drawCinnabarSeal(
            canvas,
            x: 100,
            y: 100,
            size: 36,
            sealText: sealText,
          );
          ShanshuiAtmosphericEffects.drawCalligraphyAndSeal(
            canvas,
            atmosphere: const ShanshuiAtmosphereState(
              realm: ShanshuiRealm.westLake,
              season: ShanshuiSeason.spring,
              timeOfDay: ShanshuiTimeOfDay.day,
              weather: ShanshuiWeather.sunny,
            ),
            isNight: isNight,
            fullPoem: true,
            config: config,
          );
          ShanshuiAtmosphericEffects.drawVignette(canvas, isNight: isNight);
          final picture = recorder.endRecording();
          picture.dispose();
        }
      }
    });
  });
}
