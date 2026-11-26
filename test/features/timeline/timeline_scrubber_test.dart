import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/timeline/screens/timeline_screen.dart';
import 'package:memodiary/features/timeline/widgets/wet_mounted_thumbnail.dart';

import '../../helpers/editor_test_harness.dart';

class _ScrubberSqlCaptureInterceptor extends QueryInterceptor {
  final List<(String sql, List<Object?> args)> executedSelects = [];

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    executedSelects.add((statement, args));
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;

  setUp(() {
    db = AppDatabase.memory();
    mediaService = MediaSandboxService();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedMonthlyEntries({
    required int count,
    DateTime? newestDate,
    int daysStep = 5,
  }) async {
    final anchor = newestDate ?? DateTime(2026, 11, 20, 12, 0);
    for (var index = 0; index < count; index++) {
      final date = anchor.subtract(Duration(days: index * daysStep));
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'scrubber_entry_$index',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: Value('Scrubber Entry $index'),
          contentDelta: jsonEncode([
            {'insert': 'Body for entry $index\n'},
          ]),
          plainText: 'Body for entry $index',
          entryDate: date,
        ),
      );
    }
  }

  Future<void> pumpTimelineScreen(
    WidgetTester tester, {
    Size surfaceSize = const Size(360, 780),
    double textScale = 1.0,
    bool disableAnimations = false,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        home: TimelineScreen(
          database: db,
          mediaService: mediaService,
          enableSceneryAnimation: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double scrubberOpacity(WidgetTester tester) {
    final widget = tester.widget<AnimatedOpacity>(
      find.byKey(const Key('timeline_scrubber_visibility')),
    );
    return widget.opacity;
  }

  group('TimelineScrubber visibility and auto-fade', () {
    testWidgets(
      'stays hidden when fewer than 15 entries or when feed is not scrollable',
      (tester) async {
        await seedMonthlyEntries(count: 14);
        await pumpTimelineScreen(tester);

        expect(find.byKey(const Key('timeline_scrubber_track')), findsNothing);
        expect(find.bySemanticsLabel('时间轴快速滚动条'), findsNothing);

        // Add a 15th entry, but render on a very tall viewport with zero scroll range
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'scrubber_entry_14',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Scrubber Entry 14'),
            contentDelta: jsonEncode([
              {'insert': 'Body 14\n'},
            ]),
            plainText: 'Body 14',
            entryDate: DateTime(2026, 6, 1, 12, 0),
          ),
        );

        await pumpTimelineScreen(tester, surfaceSize: const Size(400, 6000));
        expect(find.byKey(const Key('timeline_scrubber_track')), findsNothing);
      },
    );

    testWidgets(
      'fades in on scroll, auto-fades after 1.5s idle, stays visible while dragging, and respects reduced motion',
      (tester) async {
        await seedMonthlyEntries(count: 20, daysStep: 10);
        await pumpTimelineScreen(tester);

        // Eligible (20 entries, scrollable), starts hidden
        expect(find.byKey(const Key('timeline_scrubber_track')), findsOneWidget);
        expect(find.bySemanticsLabel('时间轴快速滚动条'), findsOneWidget);
        expect(scrubberOpacity(tester), equals(0.0));

        // Scrolling reveals scrubber
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
        await tester.pump();
        expect(scrubberOpacity(tester), equals(1.0));

        // Still visible before 1.5s elapses, then auto-fades at ~1.5s
        await tester.pump(const Duration(milliseconds: 1000));
        expect(scrubberOpacity(tester), equals(1.0));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();
        expect(scrubberOpacity(tester), equals(0.0));

        // Touching/dragging right-edge track wakes scrubber and keeps plaque visible while held
        final trackRect = tester.getRect(
          find.byKey(const Key('timeline_scrubber_track')),
        );
        final gesture = await tester.startGesture(
          Offset(trackRect.center.dx, trackRect.top + 20),
        );
        await tester.pump();
        await gesture.moveBy(const Offset(0, 60));
        await tester.pump();

        expect(scrubberOpacity(tester), equals(1.0));
        expect(find.byKey(const Key('timeline_scrubber_plaque')), findsOneWidget);

        // Holding finger down past 2s must NOT auto-fade
        await tester.pump(const Duration(milliseconds: 2200));
        expect(scrubberOpacity(tester), equals(1.0));
        expect(find.byKey(const Key('timeline_scrubber_plaque')), findsOneWidget);

        // Releasing hides plaque and restarts 1.5s auto-fade
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('timeline_scrubber_plaque')), findsNothing);
        expect(scrubberOpacity(tester), equals(1.0));

        await tester.pump(const Duration(milliseconds: 1600));
        await tester.pumpAndSettle();
        expect(scrubberOpacity(tester), equals(0.0));

        // Reduced motion uses Duration.zero for visibility transitions
        await pumpTimelineScreen(tester, disableAnimations: true);
        final reducedOpacityWidget = tester.widget<AnimatedOpacity>(
          find.byKey(const Key('timeline_scrubber_visibility')),
        );
        expect(reducedOpacityWidget.duration, equals(Duration.zero));
      },
    );
  });

  group('TimelineScrubber progress tracking', () {
    testWidgets(
      'tracks progress across totalFilteredCount with Month Spine Dividers and never jumps backward on _loadMore()',
      (tester) async {
        await seedMonthlyEntries(count: 45, daysStep: 12);
        await pumpTimelineScreen(tester);

        final trackFinder = find.byKey(const Key('timeline_scrubber_track'));
        final thumbFinder = find.byKey(const Key('timeline_scrubber_thumb'));

        double currentTrackFraction() {
          final trackRect = tester.getRect(trackFinder);
          final thumbTop = tester.getTopLeft(thumbFinder).dy;
          return (thumbTop - trackRect.top) / (trackRect.height - 44.0);
        }

        expect(currentTrackFraction(), closeTo(0.0, 0.01));

        // Scroll partway through page 1 (before _loadMore triggers)
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -1400));
        await tester.pumpAndSettle();

        final fractionBeforeLoadMore = currentTrackFraction();
        final thumbTopBeforeLoadMore = tester.getTopLeft(thumbFinder).dy;
        expect(fractionBeforeLoadMore, greaterThan(0.10));
        expect(fractionBeforeLoadMore, lessThan(0.45));
        expect(find.text('Scrubber Entry 25'), findsNothing);

        // Scroll further to trigger _loadMore() (appending entries 20..39)
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
        await tester.pumpAndSettle();

        final fractionAfterLoadMore = currentTrackFraction();
        final thumbTopAfterLoadMore = tester.getTopLeft(thumbFinder).dy;
        expect(thumbTopAfterLoadMore, greaterThanOrEqualTo(thumbTopBeforeLoadMore));
        expect(fractionAfterLoadMore, greaterThan(fractionBeforeLoadMore));

        // Progress reflects all 45 entries (~0.35..0.55), not 20/20 (~1.0)
        expect(fractionAfterLoadMore, lessThan(0.60));
      },
    );
  });

  group('TimelineScrubber live plaque, haptics, and prefix jump', () {
    testWidgets(
      'updates floating YYYY年M月 plaque live while dragging and emits selectionClick haptics on month crossings',
      (tester) async {
        // 30 entries, 15 days apart (~15 months from 2026-11 back to 2025-09)
        await seedMonthlyEntries(count: 30, daysStep: 15);
        await pumpTimelineScreen(tester);

        final hapticCalls = <dynamic>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              hapticCalls.add(call.arguments);
            }
            return null;
          },
        );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          );
        });

        final trackRect = tester.getRect(
          find.byKey(const Key('timeline_scrubber_track')),
        );
        final gesture = await tester.startGesture(
          Offset(trackRect.center.dx, trackRect.top + 8),
        );
        await tester.pump();
        // Move past touch slop near the top of the track -> 2026年11月
        await gesture.moveBy(const Offset(0, 20));
        await tester.pump();

        final plaqueFinder = find.byKey(const Key('timeline_scrubber_plaque'));
        expect(plaqueFinder, findsOneWidget);
        final firstLabel = tester
            .widget<Text>(
              find.descendant(of: plaqueFinder, matching: find.byType(Text)),
            )
            .data;
        expect(firstLabel, equals('2026年11月'));
        expect(hapticCalls, isEmpty);

        // Drag through multiple months down to the bottom of the track
        final seenLabels = <String>{firstLabel!};
        final steps = 8;
        final dragDistance = (trackRect.height - 44.0) * 0.9;
        for (var step = 0; step < steps; step++) {
          await gesture.moveBy(Offset(0, dragDistance / steps));
          await tester.pump();
          final currentLabel = tester
              .widget<Text>(
                find.descendant(of: plaqueFinder, matching: find.byType(Text)),
              )
              .data!;
          seenLabels.add(currentLabel);
        }

        // Multiple distinct YYYY年M月 labels previewed and selectionClick fired on crossings
        expect(seenLabels.length, greaterThanOrEqualTo(5));
        expect(seenLabels.last, startsWith('2025年'));
        expect(
          hapticCalls,
          everyElement(equals('HapticFeedbackType.selectionClick')),
        );
        expect(hapticCalls.length, equals(seenLabels.length - 1));

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'releases to prefix-load unloaded month with landing-window media, preserves filters, and supports up/down scroll pagination',
      (tester) async {
        await db.close();
        final tempDir = Directory.systemTemp.createTempSync('scrubber_jump_');
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });
        final sandbox = SyncTestMediaSandboxService(tempDir: tempDir);

        // Minimal 1x1 WebP bytes so Image.file renders cleanly if decoded
        final mediaDir = Directory('${tempDir.path}/media')..createSync(recursive: true);
        File('${mediaDir.path}/skipped_25.webp').writeAsBytesSync(const [
          0x52, 0x49, 0x46, 0x46, 0x1A, 0x00, 0x00, 0x00,
          0x57, 0x45, 0x42, 0x50, 0x56, 0x50, 0x38, 0x4C,
          0x0D, 0x00, 0x00, 0x00, 0x2F, 0x00, 0x00, 0x00,
          0x10, 0x07, 0x10, 0x11, 0x11, 0x88, 0x88, 0xFE, 0x07, 0x00,
        ]);
        File('${mediaDir.path}/skipped_25.webp').copySync(
          '${mediaDir.path}/landing_45.webp',
        );

        final interceptor = _ScrubberSqlCaptureInterceptor();
        final interceptedDb = AppDatabase.forTesting(
          NativeDatabase.memory().interceptWith(interceptor),
        );
        addTearDown(interceptedDb.close);

        final anchor = DateTime(2026, 11, 20, 12, 0);
        for (var index = 0; index < 80; index++) {
          await interceptedDb.entriesDao.createEntry(
            EntriesCompanion.insert(
              id: 'jump_entry_$index',
              notebookId: 'notebook_default',
              templateId: 'template_minimalist_white',
              title: Value('Jump Entry $index'),
              contentDelta: jsonEncode([
                {'insert': 'Heavy delta $index\n'},
              ]),
              plainText: 'Body for jump entry $index',
              entryDate: anchor.subtract(Duration(days: index * 10)),
            ),
          );
        }
        // Attach media on skipped entry 25 and landing-window entry 45
        await interceptedDb.mediaOcrDao.attachMediaToEntry(
          id: 'media_25',
          entryId: 'jump_entry_25',
          relativePath: 'media/skipped_25.webp',
        );
        await interceptedDb.mediaOcrDao.attachMediaToEntry(
          id: 'media_45',
          entryId: 'jump_entry_45',
          relativePath: 'media/landing_45.webp',
        );

        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: TimelineScreen(
              database: interceptedDb,
              mediaService: sandbox,
              enableSceneryAnimation: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('共 80 篇'), findsOneWidget);
        expect(find.text('Jump Entry 0'), findsOneWidget);
        expect(find.text('Jump Entry 45'), findsNothing);

        interceptor.executedSelects.clear();

        // Drag scrubber to ~57% of track (near entry 45 of 80) and release
        final trackRect = tester.getRect(
          find.byKey(const Key('timeline_scrubber_track')),
        );
        final usableHeight = trackRect.height - 44.0;
        final targetFraction = 45.0 / 79.0;
        final startY = trackRect.top + 22.0;
        final targetY = startY + usableHeight * targetFraction;

        final gesture = await tester.startGesture(Offset(trackRect.center.dx, startY));
        await tester.pump();
        await gesture.moveTo(Offset(trackRect.center.dx, targetY));
        await tester.pump();

        final previewPlaque = tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(const Key('timeline_scrubber_plaque')),
                matching: find.byType(Text),
              ),
            )
            .data!;

        await gesture.up();
        await tester.pumpAndSettle();

        // Landed on entry 45 and its Month Spine Divider without altering filters
        expect(find.text('Jump Entry 45'), findsOneWidget);
        expect(find.text(previewPlaque), findsWidgets);
        expect(find.text('共 80 篇'), findsOneWidget);
        expect(find.text('筛选'), findsOneWidget);
        expect(find.byType(WetMountedThumbnail), findsOneWidget);

        // Verify prefix jump queried summaries without content_delta, and media query
        // included landing entry 45 while skipping entry 25 upfront
        final mediaSelectsDuringJump = interceptor.executedSelects
            .where((entry) => entry.$1.toLowerCase().contains('media_attachments'))
            .toList();
        expect(mediaSelectsDuringJump, isNotEmpty);
        final mediaArgStrings = mediaSelectsDuringJump
            .expand((entry) => entry.$2)
            .map((arg) => arg.toString())
            .toSet();
        expect(mediaArgStrings, contains('jump_entry_45'));
        expect(mediaArgStrings, isNot(contains('jump_entry_25')));
        for (final query in interceptor.executedSelects) {
          expect(query.$1.toLowerCase(), isNot(contains('content_delta')));
        }

        // Scroll UP naturally to skipped entry 25 -> its WetMountedThumbnail loads incrementally
        await tester.scrollUntilVisible(
          find.text('Jump Entry 25'),
          -300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Jump Entry 25'), findsOneWidget);
        expect(find.byType(WetMountedThumbnail), findsOneWidget);

        // Scroll DOWN past the initial prefix (45 + 20 = 65) to verify _loadMore() continues seamlessly
        await tester.scrollUntilVisible(
          find.text('Jump Entry 75'),
          500,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Jump Entry 75'), findsOneWidget);
      },
    );
  });

  group('TimelineScrubber sort, filters, gesture safety, and 320dp layout', () {
    testWidgets(
      'matches oldestFirst sort order and active Date Index Tray / charm filters',
      (tester) async {
        final anchor = DateTime(2026, 11, 20, 12, 0);
        for (var index = 0; index < 40; index++) {
          final isMoodFive = index.isEven; // 20 mood-5, 20 mood-2
          await db.entriesDao.createEntry(
            EntriesCompanion.insert(
              id: 'filter_sort_$index',
              notebookId: 'notebook_default',
              templateId: 'template_minimalist_white',
              title: Value('FilterSort $index'),
              contentDelta: jsonEncode([
                {'insert': 'Body $index\n'},
              ]),
              plainText: 'Body $index',
              entryDate: anchor.subtract(Duration(days: index * 20)),
              mood: Value(isMoodFive ? 5 : 2),
            ),
          );
        }

        await pumpTimelineScreen(tester);
        expect(find.text('共 40 篇'), findsOneWidget);

        // Switch to oldestFirst (最早 ↑)
        await tester.tap(find.byKey(const Key('timeline_sort_toggle_button')));
        await tester.pumpAndSettle();
        expect(find.text('最早'), findsOneWidget);

        // Drag scrubber from top to near bottom in oldestFirst order:
        // top previews ~2024年, bottom previews ~2026年11月
        final trackRect = tester.getRect(
          find.byKey(const Key('timeline_scrubber_track')),
        );
        final gesture = await tester.startGesture(
          Offset(trackRect.center.dx, trackRect.top + 8),
        );
        await tester.pump();
        await gesture.moveBy(const Offset(0, 20));
        await tester.pump();

        final plaqueFinder = find.byKey(const Key('timeline_scrubber_plaque'));
        final topLabel = tester
            .widget<Text>(
              find.descendant(of: plaqueFinder, matching: find.byType(Text)),
            )
            .data!;
        expect(topLabel, startsWith('2024年'));

        await gesture.moveTo(Offset(trackRect.center.dx, trackRect.bottom - 16));
        await tester.pump();
        final bottomLabel = tester
            .widget<Text>(
              find.descendant(of: plaqueFinder, matching: find.byType(Text)),
            )
            .data!;
        expect(bottomLabel, equals('2026年11月'));

        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.text('FilterSort 0'), findsOneWidget);

        // Scroll back to top and apply charm filter mood = 5 (20 entries >= 15)
        await tester.tap(find.byKey(const Key('timeline_tap_to_top_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('timeline_charm_filter_button')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('charm_filter_mood_5')));
        await tester.tap(find.byKey(const Key('charm_filter_mood_5')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('charm_filter_close_button')));
        await tester.pumpAndSettle();

        expect(find.text('共 20 篇'), findsOneWidget);
        expect(find.byKey(const Key('timeline_scrubber_track')), findsOneWidget);

        // Narrow further by year 2026 (< 15 entries) -> scrubber hides
        await tester.tap(find.byKey(const Key('timeline_year_chip_2026')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('timeline_scrubber_track')), findsNothing);
      },
    );

    testWidgets(
      'satisfies 44x44dp target, right-edge inset, horizontal gesture safety, semantics, and 320dp at 1.3x text scale',
      (tester) async {
        await seedMonthlyEntries(count: 24, daysStep: 12);
        await pumpTimelineScreen(
          tester,
          surfaceSize: const Size(320, 640),
          textScale: 1.3,
        );

        final trackFinder = find.byKey(const Key('timeline_scrubber_track'));
        expect(trackFinder, findsOneWidget);
        expect(find.bySemanticsLabel('时间轴快速滚动条'), findsOneWidget);

        final trackRect = tester.getRect(trackFinder);
        expect(trackRect.width, greaterThanOrEqualTo(44.0));
        expect(trackRect.height, greaterThanOrEqualTo(44.0));
        expect(trackRect.right, lessThanOrEqualTo(310.0));

        // Horizontal swipe across the scrubber strip must NOT activate scrubber drag
        await tester.dragFrom(
          Offset(trackRect.center.dx, trackRect.center.dy),
          const Offset(-80, 0),
        );
        await tester.pump();
        expect(find.byKey(const Key('timeline_scrubber_plaque')), findsNothing);

        // Vertical drag renders plaque cleanly within 320dp viewport at 1.3x text scale
        final gesture = await tester.startGesture(
          Offset(trackRect.center.dx, trackRect.top + 8),
        );
        await tester.pump();
        await gesture.moveBy(const Offset(0, 40));
        await tester.pump();

        final plaqueFinder = find.byKey(const Key('timeline_scrubber_plaque'));
        expect(plaqueFinder, findsOneWidget);
        final plaqueRect = tester.getRect(plaqueFinder);
        expect(plaqueRect.left, greaterThanOrEqualTo(0.0));
        expect(plaqueRect.right, lessThanOrEqualTo(320.0));
        expect(tester.takeException(), isNull);

        await gesture.up();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
