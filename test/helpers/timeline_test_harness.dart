import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/services/ocr/ocr_queue_manager.dart';
import 'package:memodiary/features/editor/services/audio_sanctum_service.dart';
import 'package:memodiary/features/home/models/home_tab.dart';
import 'package:memodiary/features/scenery/services/scenery_settings_service.dart';
import 'package:memodiary/features/timeline/screens/timeline_screen.dart';

/// Shared test harness for pumping [TimelineScreen] inside a [MaterialApp]
/// with optional viewport sizing, text-scale, and reduced-motion overrides.
Future<void> pumpTimelineScreen(
  WidgetTester tester, {
  required AppDatabase database,
  required MediaSandboxService mediaService,
  ScenerySettingsService? scenerySettingsService,
  AudioSanctumService? audioSanctumService,
  bool? enableSceneryAnimation = false,
  OcrQueueManager? ocrQueueManager,
  HomeTabPrimaryAction? primaryAction,
  Listenable? diaryChanged,
  ThemeData? theme,
  Size? surfaceSize,
  double textScale = 1.0,
  bool disableAnimations = false,
}) async {
  if (surfaceSize != null) {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: TimelineScreen(
        database: database,
        mediaService: mediaService,
        scenerySettingsService: scenerySettingsService,
        audioSanctumService: audioSanctumService,
        enableSceneryAnimation: enableSceneryAnimation,
        ocrQueueManager: ocrQueueManager,
        primaryAction: primaryAction,
        diaryChanged: diaryChanged,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
