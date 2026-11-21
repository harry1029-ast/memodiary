import 'package:memodiary/core/database/app_database.dart';

/// The Diarist Panel's stats strip counts.
class DiaristStats {
  /// Entries not soft-deleted, weekly reviews and time capsules included (the
  /// same rule as Writing Analytics' `总篇数`).
  final int entryCount;

  /// Album collections.
  final int albumCount;

  const DiaristStats({required this.entryCount, required this.albumCount});
}

/// Read model behind the Diarist Panel's stats strip, fetched each time the
/// panel opens.
class DiaristStatsRepository {
  final AppDatabase database;

  const DiaristStatsRepository({required this.database});

  Future<DiaristStats> load() async {
    final counts = await Future.wait([
      database.entriesDao.countActiveEntries(),
      database.albumsDao.countCollections(),
    ]);
    return DiaristStats(entryCount: counts[0], albumCount: counts[1]);
  }
}
