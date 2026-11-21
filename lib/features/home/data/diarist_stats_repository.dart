import 'package:memodiary/core/database/app_database.dart';

/// The Diarist Panel's counts: the stats strip and the 回收站 row.
class DiaristStats {
  /// Entries not soft-deleted, weekly reviews and time capsules included (the
  /// same rule as Writing Analytics' `总篇数`).
  final int entryCount;

  /// Album collections.
  final int albumCount;

  /// Entries in the Recycle Bin, shown on the panel's `回收站 (N)` row.
  final int recycleBinCount;

  const DiaristStats({
    required this.entryCount,
    required this.albumCount,
    required this.recycleBinCount,
  });
}

/// Read model behind the Diarist Panel's counts, fetched each time the panel
/// opens.
class DiaristStatsRepository {
  final AppDatabase database;

  const DiaristStatsRepository({required this.database});

  Future<DiaristStats> load() async {
    final (entryCount, albumCount, recycleBinCount) = await (
      database.entriesDao.countActiveEntries(),
      database.albumsDao.countCollections(),
      database.entriesDao.countDeletedEntries(),
    ).wait;
    return DiaristStats(
      entryCount: entryCount,
      albumCount: albumCount,
      recycleBinCount: recycleBinCount,
    );
  }
}
