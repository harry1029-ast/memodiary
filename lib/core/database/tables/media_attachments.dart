import 'package:drift/drift.dart';
import 'entries.dart';

/// MediaAttachments table tracking photos and media linked to diary entries.
/// Note: Never store absolute gallery paths; relative_path must always be
/// relative to the app's sandboxed media directory (e.g., 'media/uuid.webp').
@DataClassName('MediaAttachment')
class MediaAttachments extends Table {
  /// Unique media attachment UUID
  TextColumn get id => text()();

  /// Foreign key referencing the parent entry
  TextColumn get entryId => text().references(Entries, #id)();

  /// Media type: 'image', 'video'
  TextColumn get mediaType => text()();

  /// Strictly relative sandboxed path (e.g., 'media/3fa85f64-5717-4562-b3fc-2c963f66afa6.webp')
  TextColumn get relativePath => text()();

  /// Optional relative path to generated low-res thumbnail
  TextColumn get thumbnailPath => text().nullable()();

  /// Extracted offline OCR text (if processed)
  TextColumn get ocrText => text().nullable()();

  /// Normalized line bounding boxes JSON (if processed)
  TextColumn get ocrBlocksJson => text().nullable()();

  /// Diarist-authored caption, kept apart from [ocrText] so captions never
  /// enter photo text search and OCR never overwrites what the diarist wrote.
  TextColumn get caption => text().nullable()();

  /// Normalized horizontal anchor offset [0.0..1.0] for folio ephemera overlay.
  RealColumn get overlayXRatio => real().nullable()();

  /// Normalized vertical anchor offset [0.0..1.0] for folio ephemera overlay.
  RealColumn get overlayYRatio => real().nullable()();

  /// Attachment creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

