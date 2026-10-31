import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('media_fts Triggers & updateMediaOcr / updateAlbumPhotoOcr', () {
    test(
      'maintains media_fts across insert, NULL->text update, text->sentinel clear, delete, and collection cascade delete',
      () async {
        final entryDate = DateTime(2026, 10, 15, 9, 30);
        await db.createEntry(
          EntriesCompanion.insert(
            id: 'entry_cafe',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Morning Coffee'),
            contentDelta: '[{"insert":"Cafe receipt.\\n"}]',
            plainText: 'Cafe receipt.',
            entryDate: entryDate,
          ),
        );

        await db.attachMediaToEntry(
          id: 'att_receipt',
          entryId: 'entry_cafe',
          relativePath: 'media/receipt.webp',
          thumbnailPath: 'media/receipt_thumb.webp',
        );

        // Initially NULL ocrText -> not matched
        expect(await db.searchPhotoText('Latte'), isEmpty);

        // Update NULL -> text
        const receiptBlocks =
            '[{"text":"Oat Milk Latte 38","box":[0.12,0.25,0.64,0.07]}]';
        await db.updateMediaOcr(
          'att_receipt',
          ocrText: 'Oat Milk Latte 38',
          ocrBlocksJson: receiptBlocks,
        );

        final hitsAfterUpdate = await db.searchPhotoText('Latte');
        expect(hitsAfterUpdate.length, equals(1));
        final match = hitsAfterUpdate.single;
        expect(match.id, equals('att_receipt'));
        expect(match.sourceType, equals('entry_media'));
        expect(match.parentId, equals('entry_cafe'));
        expect(match.relativePath, equals('media/receipt.webp'));
        expect(match.thumbnailPath, equals('media/receipt_thumb.webp'));
        expect(match.ocrText, equals('Oat Milk Latte 38'));
        expect(match.ocrBlocksJson, equals(receiptBlocks));
        expect(match.parentTitle, equals('Morning Coffee'));
        expect(match.parentDate, equals(entryDate));

        // Update text -> OCR Sentinel ('', '[]') removes record from media_fts
        await db.updateMediaOcr(
          'att_receipt',
          ocrText: '',
          ocrBlocksJson: '[]',
        );
        expect(await db.searchPhotoText('Latte'), isEmpty);
        final ftsAfterSentinel = await db
            .customSelect(
              "SELECT id FROM media_fts WHERE id = 'att_receipt'",
            )
            .get();
        expect(ftsAfterSentinel, isEmpty);

        // Video attachments are never indexed in media_fts even if ocrText is written
        await db.attachMediaToEntry(
          id: 'att_video',
          entryId: 'entry_cafe',
          relativePath: 'media/clip.mp4',
          mediaType: 'video',
        );
        await db.updateMediaOcr(
          'att_video',
          ocrText: 'Hidden Video Text',
          ocrBlocksJson: '[]',
        );
        expect(await db.searchPhotoText('Hidden'), isEmpty);

        // Album photo insert -> updateAlbumPhotoOcr -> collection ON DELETE CASCADE
        final createdAt = DateTime(2026, 10, 20, 14, 0);
        final shotAt = DateTime(2026, 10, 18, 11, 0);
        await db.into(db.albumCollections).insert(
              AlbumCollectionsCompanion.insert(
                id: 'col_museum',
                title: '浙江省博物馆纪行',
                createdAt: Value(createdAt),
                updatedAt: Value(createdAt),
              ),
            );
        await db.into(db.albumPhotos).insert(
              AlbumPhotosCompanion.insert(
                id: 'album_plaque_1',
                collectionId: 'col_museum',
                relativeImagePath: 'media/plaque.webp',
                relativeThumbnailPath: 'media/plaque_thumb.webp',
                shotAt: Value(shotAt),
                createdAt: Value(createdAt),
              ),
            );
        await db.into(db.albumPhotos).insert(
              AlbumPhotosCompanion.insert(
                id: 'album_ticket_2',
                collectionId: 'col_museum',
                relativeImagePath: 'media/ticket.webp',
                relativeThumbnailPath: 'media/ticket_thumb.webp',
                createdAt: Value(createdAt),
              ),
            );

        await db.updateAlbumPhotoOcr(
          'album_plaque_1',
          ocrText: 'Bronze Mirror Gallery',
          ocrBlocksJson: '[{"text":"Bronze Mirror Gallery","box":[0.1,0.1,0.8,0.1]}]',
        );
        await db.updateAlbumPhotoOcr(
          'album_ticket_2',
          ocrText: 'Admission Ticket Hall B',
          ocrBlocksJson: '[]',
        );

        final plaqueHits = await db.searchPhotoText('Bronze');
        expect(plaqueHits.length, equals(1));
        expect(plaqueHits.single.sourceType, equals('album_photo'));
        expect(plaqueHits.single.parentId, equals('col_museum'));
        expect(plaqueHits.single.parentTitle, equals('浙江省博物馆纪行'));
        expect(plaqueHits.single.parentDate, equals(shotAt));
        expect(
          plaqueHits.single.thumbnailPath,
          equals('media/plaque_thumb.webp'),
        );

        // When shotAt is null, parentDate falls back to createdAt
        final ticketHits = await db.searchPhotoText('Admission');
        expect(ticketHits.single.parentDate, equals(createdAt));

        // Deleting parent album_collection cascades to album_photos AND cleans up media_fts via album_photos_ad
        await (db.delete(db.albumCollections)
              ..where((tbl) => tbl.id.equals('col_museum')))
            .go();

        expect(await db.searchPhotoText('Bronze'), isEmpty);
        expect(await db.searchPhotoText('Admission'), isEmpty);
        final remainingFts = await db
            .customSelect('SELECT id FROM media_fts')
            .get();
        expect(remainingFts, isEmpty);
      },
    );
  });

  group('Dual-Path CJK Substring Search & Deduplication', () {
    test(
      'recalls CJK compound substrings like 咖啡 in 星巴克咖啡厅 without duplicates and safely escapes wildcards',
      () async {
        final now = DateTime(2026, 10, 25, 16, 0);
        await db.createEntry(
          EntriesCompanion.insert(
            id: 'entry_cjk',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('西湖漫步'),
            contentDelta: '[{"insert":"Walk.\\n"}]',
            plainText: 'Walk.',
            entryDate: now,
          ),
        );

        await db.into(db.mediaAttachments).insert(
              MediaAttachmentsCompanion.insert(
                id: 'media_starbucks',
                entryId: 'entry_cjk',
                mediaType: 'image',
                relativePath: 'media/starbucks.webp',
                ocrText: const Value('Starbucks 星巴克咖啡厅 100% 阿拉比卡豆'),
                ocrBlocksJson: const Value('[]'),
                createdAt: Value(now),
              ),
            );

        // Empty / whitespace query returns empty list
        expect(await db.searchPhotoText('   '), isEmpty);

        // Mid-token CJK compound word '咖啡' recalled via parameterized LIKE fallback
        final cjkSubstringHits = await db.searchPhotoText('咖啡');
        expect(cjkSubstringHits.length, equals(1));
        expect(cjkSubstringHits.single.id, equals('media_starbucks'));

        // Prefix CJK term '星巴克' matches BOTH FTS5 MATCH and CJK LIKE -> deduplicated to 1 result
        final cjkPrefixHits = await db.searchPhotoText('星巴克');
        expect(cjkPrefixHits.length, equals(1));
        expect(cjkPrefixHits.single.id, equals('media_starbucks'));

        // Wildcard characters '%' and '_' in CJK query are escaped literally
        expect(await db.searchPhotoText('咖啡%厅'), isEmpty);
        final literalPercentHits = await db.searchPhotoText('100% 阿拉比卡');
        expect(literalPercentHits.length, equals(1));
      },
    );
  });

  group('Privacy Invariants in searchPhotoText', () {
    test(
      'excludes soft-deleted entries, locked entries, and sealed Time Capsules, and restores visibility when unsealed/restored',
      () async {
        final refNow = DateTime(2026, 10, 31, 12, 0);
        final futureUnlock = DateTime(2026, 12, 31, 0, 0);

        await db.createEntry(
          EntriesCompanion.insert(
            id: 'entry_active',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Active Entry'),
            contentDelta: '[{"insert":"Active\\n"}]',
            plainText: 'Active',
            entryDate: refNow,
          ),
        );
        await db.createEntry(
          EntriesCompanion.insert(
            id: 'entry_trashed',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Trashed Entry'),
            contentDelta: '[{"insert":"Trashed\\n"}]',
            plainText: 'Trashed',
            entryDate: refNow,
            isDeleted: const Value(true),
          ),
        );
        await db.createEntry(
          EntriesCompanion.insert(
            id: 'entry_locked',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Locked Entry'),
            contentDelta: '[{"insert":"Locked\\n"}]',
            plainText: 'Locked',
            entryDate: refNow,
            isLocked: const Value(true),
            entryPinHash: const Value('salt:hash'),
          ),
        );
        await db.createEntry(
          EntriesCompanion.insert(
            id: 'entry_sealed_capsule',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Future Capsule'),
            contentDelta: '[{"insert":"Capsule\\n"}]',
            plainText: 'Capsule',
            entryDate: refNow,
            unlockAt: Value(futureUnlock),
          ),
        );

        for (final entryId in [
          'entry_active',
          'entry_trashed',
          'entry_locked',
          'entry_sealed_capsule',
        ]) {
          await db.into(db.mediaAttachments).insert(
                MediaAttachmentsCompanion.insert(
                  id: 'media_for_$entryId',
                  entryId: entryId,
                  mediaType: 'image',
                  relativePath: 'media/$entryId.webp',
                  ocrText: const Value('秘密车票 SecretTicket 西湖专列'),
                  ocrBlocksJson: const Value('[]'),
                  createdAt: Value(refNow),
                ),
              );
        }

        // Check both Latin FTS path and CJK LIKE path enforce identical privacy filtering
        for (final query in ['SecretTicket', '西湖专列']) {
          final visible = await db.searchPhotoText(query, now: refNow);
          expect(
            visible.map((item) => item.id).toList(),
            equals(['media_for_entry_active']),
            reason: 'Only active unlocked unsealed entry media should match for "$query"',
          );
        }

        // Soft-delete active entry -> disappears; restore trashed entry -> reappears!
        await db.softDeleteEntry('entry_active');
        expect(await db.searchPhotoText('西湖专列', now: refNow), isEmpty);

        await db.restoreEntry('entry_trashed');
        final afterRestore = await db.searchPhotoText('西湖专列', now: refNow);
        expect(
          afterRestore.map((item) => item.id).toList(),
          equals(['media_for_entry_trashed']),
        );

        // Unlock locked entry -> reappears!
        await db.unlockEntryPermanently('entry_locked');
        final afterUnlockPin = await db.searchPhotoText('西湖专列', now: refNow);
        expect(
          afterUnlockPin.map((item) => item.id).toSet(),
          equals({'media_for_entry_trashed', 'media_for_entry_locked'}),
        );

        // Advance clock past Time Capsule unlockAt -> capsule photo becomes searchable!
        final afterCapsuleTime = await db.searchPhotoText(
          '西湖专列',
          now: DateTime(2027, 1, 1),
        );
        expect(
          afterCapsuleTime.map((item) => item.id).toSet(),
          contains('media_for_entry_sealed_capsule'),
        );
      },
    );
  });

  group('Unindexed Image Queries & Reactive Session Watch', () {
    test(
      'getUnindexedImages and countUnindexedImages return only NULL ocr_text images on non-deleted entries and albums ordered by createdAt ASC',
      () async {
        final t1 = DateTime(2026, 10, 1, 8, 0);
        final t2 = DateTime(2026, 10, 2, 9, 0);
        final t3 = DateTime(2026, 10, 3, 10, 0);

        await db.createEntry(
          EntriesCompanion.insert(
            id: 'entry_live',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Live'),
            contentDelta: '[{"insert":"Live\\n"}]',
            plainText: 'Live',
            entryDate: t1,
          ),
        );
        await db.createEntry(
          EntriesCompanion.insert(
            id: 'entry_deleted',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Deleted'),
            contentDelta: '[{"insert":"Deleted\\n"}]',
            plainText: 'Deleted',
            entryDate: t1,
            isDeleted: const Value(true),
          ),
        );
        await db.into(db.albumCollections).insert(
              AlbumCollectionsCompanion.insert(
                id: 'col_live',
                title: 'Autumn Album',
                createdAt: Value(t1),
                updatedAt: Value(t1),
              ),
            );

        // 1. Unindexed album photo at t2
        await db.into(db.albumPhotos).insert(
              AlbumPhotosCompanion.insert(
                id: 'unindexed_album_t2',
                collectionId: 'col_live',
                relativeImagePath: 'media/album_t2.webp',
                relativeThumbnailPath: 'media/album_t2_thumb.webp',
                createdAt: Value(t2),
              ),
            );

        // 2. Unindexed entry image at t1 (earlier than t2 -> must sort first)
        await db.into(db.mediaAttachments).insert(
              MediaAttachmentsCompanion.insert(
                id: 'unindexed_entry_t1',
                entryId: 'entry_live',
                mediaType: 'image',
                relativePath: 'media/entry_t1.webp',
                createdAt: Value(t1),
              ),
            );

        // 3. Video attachment with NULL ocrText -> excluded
        await db.into(db.mediaAttachments).insert(
              MediaAttachmentsCompanion.insert(
                id: 'video_t3',
                entryId: 'entry_live',
                mediaType: 'video',
                relativePath: 'media/video_t3.mp4',
                createdAt: Value(t3),
              ),
            );

        // 4. Image on soft-deleted entry -> excluded
        await db.into(db.mediaAttachments).insert(
              MediaAttachmentsCompanion.insert(
                id: 'deleted_entry_img',
                entryId: 'entry_deleted',
                mediaType: 'image',
                relativePath: 'media/deleted.webp',
                createdAt: Value(t3),
              ),
            );

        // 5. Sentinel-scanned image (ocrText = '') -> excluded
        await db.into(db.mediaAttachments).insert(
              MediaAttachmentsCompanion.insert(
                id: 'sentinel_img',
                entryId: 'entry_live',
                mediaType: 'image',
                relativePath: 'media/scenery.webp',
                ocrText: const Value(''),
                ocrBlocksJson: const Value('[]'),
                createdAt: Value(t3),
              ),
            );

        expect(await db.countUnindexedImages(), equals(2));
        final unindexed = await db.getUnindexedImages();
        expect(
          unindexed.map((item) => item.id).toList(),
          equals(['unindexed_entry_t1', 'unindexed_album_t2']),
        );
        expect(unindexed.first.sourceType, equals('entry_media'));
        expect(unindexed.first.relativePath, equals('media/entry_t1.webp'));
        expect(unindexed.first.createdAt, equals(t1));
        expect(unindexed.last.sourceType, equals('album_photo'));
        expect(unindexed.last.relativePath, equals('media/album_t2.webp'));
        expect(unindexed.last.createdAt, equals(t2));
      },
    );

    test(
      'watchUnindexedImagesSince reactively emits only unindexed images created at or after since and drops them once scanned',
      () async {
        final legacyTime = DateTime(2026, 10, 1, 10, 0);
        final launchTime = DateTime(2026, 10, 31, 12, 0);
        final sessionTime = DateTime(2026, 10, 31, 12, 5);

        await db.createEntry(
          EntriesCompanion.insert(
            id: 'entry_session',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Session Entry'),
            contentDelta: '[{"insert":"Session\\n"}]',
            plainText: 'Session',
            entryDate: launchTime,
          ),
        );
        await db.into(db.albumCollections).insert(
              AlbumCollectionsCompanion.insert(
                id: 'col_session',
                title: 'Session Album',
                createdAt: Value(launchTime),
                updatedAt: Value(launchTime),
              ),
            );

        // Legacy unindexed image prior to launchTime -> must NOT appear in session watch
        await db.into(db.mediaAttachments).insert(
              MediaAttachmentsCompanion.insert(
                id: 'legacy_unindexed',
                entryId: 'entry_session',
                mediaType: 'image',
                relativePath: 'media/legacy.webp',
                createdAt: Value(legacyTime),
              ),
            );

        final emissions = <List<String>>[];
        final subscription = db
            .watchUnindexedImagesSince(launchTime)
            .listen((items) => emissions.add(items.map((item) => item.id).toList()));
        addTearDown(subscription.cancel);

        await pumpEventQueue();
        expect(emissions.last, isEmpty);

        // Insert new entry image at launchTime and album photo at sessionTime
        await db.into(db.mediaAttachments).insert(
              MediaAttachmentsCompanion.insert(
                id: 'session_entry_img',
                entryId: 'entry_session',
                mediaType: 'image',
                relativePath: 'media/new_entry.webp',
                createdAt: Value(launchTime),
              ),
            );
        await pumpEventQueue();
        expect(emissions.last, equals(['session_entry_img']));

        await db.into(db.albumPhotos).insert(
              AlbumPhotosCompanion.insert(
                id: 'session_album_img',
                collectionId: 'col_session',
                relativeImagePath: 'media/new_album.webp',
                relativeThumbnailPath: 'media/new_album_thumb.webp',
                createdAt: Value(sessionTime),
              ),
            );
        await pumpEventQueue();
        expect(
          emissions.last,
          equals(['session_entry_img', 'session_album_img']),
        );

        // Mark session_entry_img with sentinel -> drops from stream
        await db.updateMediaOcr(
          'session_entry_img',
          ocrText: '',
          ocrBlocksJson: '[]',
        );
        await pumpEventQueue();
        expect(emissions.last, equals(['session_album_img']));

        // Mark session_album_img with OCR text -> drops from stream
        await db.updateAlbumPhotoOcr(
          'session_album_img',
          ocrText: 'Scanned Sign',
          ocrBlocksJson: '[{"text":"Scanned Sign","box":[0.1,0.1,0.5,0.1]}]',
        );
        await pumpEventQueue();
        expect(emissions.last, isEmpty);
      },
    );
  });
}
