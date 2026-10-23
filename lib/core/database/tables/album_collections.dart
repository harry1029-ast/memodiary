import 'package:drift/drift.dart';

/// AlbumCollections table storing travel memory album metadata and cover styling.
@DataClassName('AlbumCollection')
class AlbumCollections extends Table {
  /// Unique collection UUID
  TextColumn get id => text()();

  /// Album title (1-100 chars, e.g., "江南春行纪")
  TextColumn get title => text().withLength(min: 1, max: 100)();

  /// Optional prologue / trip overview (卷首语)
  TextColumn get description => text().nullable()();

  /// Optional regional stamp tag (e.g., "江南", "川西")
  TextColumn get destinationTag => text().nullable()();

  /// Optional travel trajectory (e.g., "杭州 → 乌镇 → 苏州")
  TextColumn get routeSummary => text().nullable()();

  /// Optional relative sandboxed path to the cover WebP image (e.g., 'media/uuid.webp')
  TextColumn get coverImagePath => text().nullable()();

  /// Optional trip start date
  DateTimeColumn get startDate => dateTime().nullable()();

  /// Optional trip end date
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Photobook layout preset identifier
  TextColumn get layoutPreset =>
      text().withDefault(const Constant('classic_photobook'))();

  /// Explicit display ordering index among collections
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last modification timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

