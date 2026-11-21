import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:memodiary/core/database/app_database.dart';

/// Notes whether anything wrote to the tables the 日记 timeline shows
/// (entries and their media) while a screen opened from the Diarist Panel was
/// up, so the timeline reloads only when that screen changed something.
class DiaryWriteWatch {
  final StreamSubscription<void> _subscription;
  bool _sawWrite = false;

  DiaryWriteWatch._(Stream<void> writes) : _subscription = writes.listen(null) {
    _subscription.onData((_) => _sawWrite = true);
  }

  /// Starts watching [database] for timeline writes.
  factory DiaryWriteWatch.start(AppDatabase database) => DiaryWriteWatch._(
        database.tableUpdates(
          TableUpdateQuery.onAllTables([database.entries, database.mediaAttachments]),
        ),
      );

  /// Stops watching; true when any timeline write was seen since [start].
  bool stop() {
    // Nothing waits on the cancel: the answer is already known.
    unawaited(_subscription.cancel());
    return _sawWrite;
  }
}
