import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/home/data/diarist_stats_repository.dart';

void main() {
  late AppDatabase db;
  late DiaristStatsRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    repository = DiaristStatsRepository(database: db);
  });

  tearDown(() => db.close());

  Future<void> addEntry(
    String id, {
    bool isWeeklyReview = false,
    DateTime? unlockAt,
    bool isDeleted = false,
  }) {
    return db.entriesDao.createEntry(
      EntriesCompanion.insert(
        id: id,
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        contentDelta: '[{"insert":"$id\\n"}]',
        plainText: id,
        entryDate: DateTime(2026, 11, 20),
        isWeeklyReview: Value(isWeeklyReview),
        unlockAt: Value(unlockAt),
        isDeleted: Value(isDeleted),
      ),
    );
  }

  Future<void> addAlbum(String id) {
    return db.albumsDao.insertCollection(
      AlbumCollectionsCompanion.insert(id: id, title: id),
    );
  }

  test('an empty diary has no entries, no albums and an empty Recycle Bin', () async {
    final stats = await repository.load();

    expect(stats.entryCount, 0);
    expect(stats.albumCount, 0);
    expect(stats.recycleBinCount, 0);
  });

  test('counts entries that are not soft-deleted, weekly reviews and time capsules included', () async {
    await addEntry('plain_1');
    await addEntry('plain_2');
    await addEntry('weekly_review', isWeeklyReview: true);
    await addEntry('time_capsule', unlockAt: DateTime(2030, 1, 1));
    await addEntry('in_recycle_bin', isDeleted: true);

    final stats = await repository.load();

    expect(stats.entryCount, 4);
  });

  test('counts entries in the Recycle Bin, of every kind', () async {
    await addEntry('active');
    await addEntry('binned_1', isDeleted: true);
    await addEntry('binned_review', isWeeklyReview: true, isDeleted: true);
    await addEntry('binned_capsule', unlockAt: DateTime(2030, 1, 1), isDeleted: true);

    final stats = await repository.load();

    expect(stats.recycleBinCount, 3);
    expect(stats.entryCount, 1);
  });

  test('counts album collections', () async {
    await addAlbum('album_1');
    await addAlbum('album_2');
    await addAlbum('album_3');

    final stats = await repository.load();

    expect(stats.albumCount, 3);
  });

  test('a later load reflects entries and albums created or deleted since', () async {
    await addEntry('first');
    await addAlbum('album_1');
    expect((await repository.load()).entryCount, 1);

    await addEntry('second');
    await db.entriesDao.softDeleteEntry('first');
    await addAlbum('album_2');
    await db.albumsDao.deleteCollectionRecords('album_1');
    await addAlbum('album_3');

    final stats = await repository.load();
    expect(stats.entryCount, 1);
    expect(stats.albumCount, 2);
    expect(stats.recycleBinCount, 1);
  });
}
