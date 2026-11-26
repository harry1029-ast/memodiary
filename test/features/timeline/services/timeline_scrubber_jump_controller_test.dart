import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' hide Column, isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_summary.dart';
import 'package:memodiary/features/timeline/services/timeline_scrubber_jump_controller.dart';
import 'package:memodiary/features/timeline/services/timeline_viewport_tracker.dart';

import '../../../helpers/sql_capture_interceptor.dart';

void main() {
  group('TimelineScrubberJumpController.backfillVisibleMedia coalescing', () {
    testWidgets(
      'coalesces mid-flight calls while loading and runs one follow-up pass for newly entered entries',
      (tester) async {
        final firstMediaQueryGate = Completer<void>();
        var mediaSelectCount = 0;

        final interceptor = SqlCaptureInterceptor(
          onBeforeSelect: (statement, args) async {
            if (statement.toLowerCase().contains('media_attachments')) {
              mediaSelectCount++;
              if (mediaSelectCount == 1) {
                await firstMediaQueryGate.future;
              }
            }
          },
        );
        final db = AppDatabase.forTesting(
          NativeDatabase.memory().interceptWith(interceptor),
        );
        addTearDown(db.close);

        final anchor = DateTime(2026, 11, 20, 12, 0);
        final entries = <TimelineEntrySummary>[];
        for (var index = 0; index < 30; index++) {
          final id = 'coalesce_entry_$index';
          final entryDate = anchor.subtract(Duration(days: index));
          await db.entriesDao.createEntry(
            EntriesCompanion.insert(
              id: id,
              notebookId: 'notebook_default',
              templateId: 'template_minimalist_white',
              title: Value('Entry $index'),
              contentDelta: jsonEncode([
                {'insert': 'Body $index\n'},
              ]),
              plainText: 'Body $index',
              entryDate: entryDate,
            ),
          );
          entries.add(
            TimelineEntrySummary(
              id: id,
              title: 'Entry $index',
              plainTextSnippet: 'Body $index',
              entryDate: entryDate,
            ),
          );
        }

        await db.mediaOcrDao.attachMediaToEntry(
          id: 'media_22',
          entryId: 'coalesce_entry_22',
          relativePath: 'media/entry_22.webp',
        );
        await db.mediaOcrDao.attachMediaToEntry(
          id: 'media_12',
          entryId: 'coalesce_entry_12',
          relativePath: 'media/entry_12.webp',
        );
        await db.mediaOcrDao.attachMediaToEntry(
          id: 'media_3',
          entryId: 'coalesce_entry_3',
          relativePath: 'media/entry_3.webp',
        );

        final tracker = TimelineViewportTracker();
        addTearDown(tracker.dispose);
        final controller = TimelineScrubberJumpController();
        // Simulate initial load only queried entry 0..9? No: pretend entries 20..24 are mounted first,
        // then upward scroll brings 10..14 and finally 1..5 into view mid-query.
        final visibleIndicesNotifier = ValueNotifier<List<int>>([22]);
        addTearDown(visibleIndicesNotifier.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<List<int>>(
                valueListenable: visibleIndicesNotifier,
                builder: (context, indices, _) {
                  return Column(
                    children: [
                      for (final idx in indices)
                        TimelineViewportMarker(
                          key: ValueKey('marker_$idx'),
                          entryIndex: idx,
                          tracker: tracker,
                          child: const SizedBox(width: 100, height: 60),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        final mergedMedia = <String, MediaAttachment>{};
        var mounted = true;
        interceptor.clear();

        // Start initial backfill while entry 22 is mounted; gate pauses DB query.
        final initialFuture = controller.backfillVisibleMedia(
          database: db,
          currentEntries: entries,
          viewportTracker: tracker,
          isMounted: () => mounted,
          onMergeMedia: mergedMedia.addAll,
        );
        await tester.pump();
        expect(mediaSelectCount, equals(1));

        // Rapid upward scroll #1 (mid-flight): entry 12 enters viewport.
        visibleIndicesNotifier.value = [12];
        await tester.pump();
        await controller.backfillVisibleMedia(
          database: db,
          currentEntries: entries,
          viewportTracker: tracker,
          isMounted: () => mounted,
          onMergeMedia: mergedMedia.addAll,
        );

        // Rapid upward scroll #2 (still mid-flight): entry 3 enters viewport.
        visibleIndicesNotifier.value = [3];
        await tester.pump();
        await controller.backfillVisibleMedia(
          database: db,
          currentEntries: entries,
          viewportTracker: tracker,
          isMounted: () => mounted,
          onMergeMedia: mergedMedia.addAll,
        );

        // No extra DB query fired while first query is still in flight.
        expect(mediaSelectCount, equals(1));

        // Release first query and await completion of coalesced follow-up pass.
        firstMediaQueryGate.complete();
        await initialFuture;
        await tester.pump();

        expect(mediaSelectCount, equals(2));
        expect(mergedMedia.keys, contains('coalesce_entry_22'));
        expect(mergedMedia.keys, contains('coalesce_entry_3'));
      },
    );
  });
}
