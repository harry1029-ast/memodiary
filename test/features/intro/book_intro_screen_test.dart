import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/intro/screens/book_intro_screen.dart';
import 'package:memodiary/features/intro/widgets/book_3d_stage.dart';
import 'package:memodiary/features/intro/widgets/bottom_seal_slider.dart';
import 'package:memodiary/features/timeline/screens/timeline_screen.dart';

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase.memory();
    tempDir = Directory.systemTemp.createTempSync('book_intro_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  /// Shared test harness extracting view dimensions and dependency wiring
  /// to eliminate duplicated boilerplate and maintain CODING_STANDARDS.md §4 compliance.
  Future<void> pumpBookIntroScreen(
    WidgetTester tester, {
    required AppDatabase database,
    required MediaSandboxService mediaService,
    bool startOpened = false,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BookIntroScreen(
          database: database,
          mediaService: mediaService,
          startOpened: startOpened,
        ),
      ),
    );
    await tester.pump();
    if (startOpened) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('BookIntroScreen Widget Tests', () {
    testWidgets('renders closed thread-bound book cover and slider on initial load', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: false,
      );

      // Verify top title and slider widgets
      expect(find.text('拾光 · 云笺日记'), findsOneWidget);
      expect(find.byType(BottomSealSlider), findsOneWidget);
      expect(find.byType(Book3DStage), findsOneWidget);
      expect(find.textContaining('Swipe Left to Open'), findsOneWidget);

      // In closed state, vertical cover slip is visible
      expect(find.textContaining('拾\n光\n云\n笺'), findsOneWidget);
    });

    testWidgets('reveals 私人日记 and 旅行画册 when startOpened is true', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: true,
      );

      expect(find.text('私人日记'), findsOneWidget);
      expect(find.text('今日心绪，静落成笺'), findsOneWidget);
      expect(find.text('旅行画册'), findsOneWidget);
      expect(find.text('山河沿路，笔底留痕'), findsOneWidget);
      expect(find.textContaining('点选书页'), findsOneWidget);
    });

    testWidgets('tapping 私人日记 navigates to TimelineScreen', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: true,
      );

      await tester.tap(find.text('私人日记'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TimelineScreen), findsOneWidget);
    });

    testWidgets('swiping left across the book opens it smoothly', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: false,
      );

      // Swipe left across the book stage (effortless book-opening motion)
      await tester.drag(find.byType(Book3DStage), const Offset(-200, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      // After swiping left, it animates fully open
      expect(find.text('私人日记'), findsOneWidget);
      expect(find.text('旅行画册'), findsOneWidget);
    });

    testWidgets('tapping bottom seal slider toggles book open and closed', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: false,
      );

      // Tap bottom slider to open
      await tester.tap(find.byType(BottomSealSlider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('私人日记'), findsOneWidget);
      expect(find.text('旅行画册'), findsOneWidget);

      // Tap bottom slider again to close
      await tester.tap(find.byType(BottomSealSlider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.textContaining('Swipe Left to Open'), findsOneWidget);
    });

    testWidgets('tapping directly on the closed book cover opens it', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: false,
      );

      // Tap directly on the closed book
      await tester.tap(find.byType(Book3DStage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('私人日记'), findsOneWidget);
      expect(find.text('旅行画册'), findsOneWidget);
    });

    testWidgets('swiping right when opened closes the book', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: true,
      );

      expect(find.text('私人日记'), findsOneWidget);

      // Swipe right across the open book to close it
      await tester.drag(find.byType(Book3DStage), const Offset(200, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.textContaining('Swipe Left to Open'), findsOneWidget);
    });

    testWidgets('dragging bottom slider handle left opens the book', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: false,
      );

      // Drag the slider handle leftwards
      await tester.drag(find.byType(BottomSealSlider), const Offset(-200, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('私人日记'), findsOneWidget);
      expect(find.text('旅行画册'), findsOneWidget);
    });
  });
}
