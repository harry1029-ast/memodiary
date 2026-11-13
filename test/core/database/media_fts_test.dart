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
        await db.entriesDao.createEntry(
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

        await db.mediaOcrDao.attachMediaToEntry(
          id: 'att_receipt',
          entryId: 'entry_cafe',
          relativePath: 'media/receipt.webp',
          thumbnailPath: 'media/receipt_thumb.webp',
        );

        // Initially NULL ocrText -> not matched
        expect(await db.mediaOcrDao.searchPhotoText('Latte'), isEmpty);

        // Update NULL -> text
        const receiptBlocks =
            '[{"text":"Oat Milk Latte 38","box":[0.12,0.25,0.64,0.07]}]';
        await db.mediaOcrDao.updateMediaOcr(
          'att_receipt',
          ocrText: 'Oat Milk Latte 38',
          ocrBlocksJson: receiptBlocks,
        );

        final hitsAfterUpdate = await db.mediaOcrDao.searchPhotoText('Latte');
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
        await db.mediaOcrDao.updateMediaOcr(
          'att_receipt',
          ocrText: '',
          ocrBlocksJson: '[]',
        );
        expect(await db.mediaOcrDao.searchPhotoText('Latte'), isEmpty);
        final ftsAfterSentinel = await db
            .customSelect(
              "SELECT id FROM media_fts WHERE id = 'att_receipt'",
            )
            .get();
        expect(ftsAfterSentinel, isEmpty);

        // Video attachments are never indexed in media_fts even if ocrText is written
        await db.mediaOcrDao.attachMediaToEntry(
          id: 'att_video',
          entryId: 'entry_cafe',
          relativePath: 'media/clip.mp4',
          mediaType: 'video',
        );
        await db.mediaOcrDao.updateMediaOcr(
          'att_video',
          ocrText: 'Hidden Video Text',
          ocrBlocksJson: '[]',
        );
        expect(await db.mediaOcrDao.searchPhotoText('Hidden'), isEmpty);

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

        await db.mediaOcrDao.updateAlbumPhotoOcr(
          'album_plaque_1',
          ocrText: 'Bronze Mirror Gallery',
          ocrBlocksJson:
              '[{"text":"Bronze Mirror Gallery","box":[0.1,0.1,0.8,0.1]}]',
        );
        await db.mediaOcrDao.updateAlbumPhotoOcr(
          'album_ticket_2',
          ocrText: 'Admission Ticket Hall B',
          ocrBlocksJson: '[]',
        );

        final plaqueHits = await db.mediaOcrDao.searchPhotoText('Bronze');
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
        final ticketHits = await db.mediaOcrDao.searchPhotoText('Admission');
        expect(ticketHits.single.parentDate, equals(createdAt));

        // Deleting parent album_collection cascades to album_photos AND cleans up media_fts via album_photos_ad
        await (db.delete(db.albumCollections)
              ..where((tbl) => tbl.id.equals('col_museum')))
            .go();

        expect(await db.mediaOcrDao.searchPhotoText('Bronze'), isEmpty);
        expect(await db.mediaOcrDao.searchPhotoText('Admission'), isEmpty);
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
        await db.entriesDao.createEntry(
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
        expect(await db.mediaOcrDao.searchPhotoText('   '), isEmpty);

        // Mid-token CJK compound word '咖啡' recalled via parameterized LIKE fallback
        final cjkSubstringHits = await db.mediaOcrDao.searchPhotoText('咖啡');
        expect(cjkSubstringHits.length, equals(1));
        expect(cjkSubstringHits.single.id, equals('media_starbucks'));

        // Prefix CJK term '星巴克' matches BOTH FTS5 MATCH and CJK LIKE -> deduplicated to 1 result
        final cjkPrefixHits = await db.mediaOcrDao.searchPhotoText('星巴克');
        expect(cjkPrefixHits.length, equals(1));
        expect(cjkPrefixHits.single.id, equals('media_starbucks'));

        // Wildcard characters '%' and '_' in CJK query are escaped literally
        expect(await db.mediaOcrDao.searchPhotoText('咖啡%厅'), isEmpty);
        final literalPercentHits =
            await db.mediaOcrDao.searchPhotoText('100% 阿拉比卡');
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

        await db.entriesDao.createEntry(
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
        await db.entriesDao.createEntry(
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
        await db.entriesDao.createEntry(
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
        await db.entriesDao.createEntry(
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
          final visible =
              await db.mediaOcrDao.searchPhotoText(query, now: refNow);
          expect(
            visible.map((item) => item.id).toList(),
            equals(['media_for_entry_active']),
            reason:
                'Only active unlocked unsealed entry media should match for "$query"',
          );
        }

        // Soft-delete active entry -> disappears; restore trashed entry -> reappears!
        await db.entriesDao.softDeleteEntry('entry_active');
        expect(
          await db.mediaOcrDao.searchPhotoText('西湖专列', now: refNow),
          isEmpty,
        );

        await db.entriesDao.restoreEntry('entry_trashed');
        final afterRestore =
            await db.mediaOcrDao.searchPhotoText('西湖专列', now: refNow);
        expect(
          afterRestore.map((item) => item.id).toList(),
          equals(['media_for_entry_trashed']),
        );

        // Unlock locked entry -> reappears!
        await db.entriesDao.unlockEntryPermanently('entry_locked');
        final afterUnlockPin =
            await db.mediaOcrDao.searchPhotoText('西湖专列', now: refNow);
        expect(
          afterUnlockPin.map((item) => item.id).toSet(),
          equals({'media_for_entry_trashed', 'media_for_entry_locked'}),
        );

        // Advance clock past Time Capsule unlockAt -> capsule photo becomes searchable!
        final afterCapsuleTime = await db.mediaOcrDao.searchPhotoText(
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
}
