import 'package:drift/drift.dart';
// ignore: unused_import
import 'album_collections.dart';

/// AlbumPhotos table storing sandboxed photos and per-photo annotations (写影札).
@DataClassName('AlbumPhoto')
class AlbumPhotos extends Table {
  /// Unique photo record UUID
  TextColumn get id => text()();

  /// Parent collection ID (cascades on collection deletion)
  TextColumn get collectionId => text().customConstraint(
        'NOT NULL REFERENCES album_collections(id) ON DELETE CASCADE',
      )();

  /// Strictly relative sandboxed path to 1600px WebP image ('media/{uuid}.webp')
  TextColumn get relativeImagePath => text()();

  /// Strictly relative sandboxed path to 300px WebP thumbnail ('media/{uuid}_thumb.webp')
  TextColumn get relativeThumbnailPath => text()();

  /// Optional travel note / story reflection for this photo
  TextColumn get caption => text().nullable()();

  /// Optional location pin (e.g., "杭州 · 西湖", "Kyoto · Fushimi Inari")
  TextColumn get locationTag => text().nullable()();

  /// Optional capture timestamp (from EXIF or manual override)
  DateTimeColumn get shotAt => dateTime().nullable()();

  /// Explicit narrative sort order within the collection
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Cached width / height aspect ratio (default 1.0) for zero-decode layout synthesis
  RealColumn get aspectRatio => real().withDefault(const Constant(1.0))();

  /// Extracted offline OCR text (if processed)
  TextColumn get ocrText => text().nullable()();

  /// Normalized line bounding boxes JSON (if processed)
  TextColumn get ocrBlocksJson => text().nullable()();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
