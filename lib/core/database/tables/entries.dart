import 'package:drift/drift.dart';
import 'notebooks.dart';
import 'templates.dart';

/// Entries table storing diary and weekly review records.
@DataClassName('Entry')
class Entries extends Table {
  /// Unique entry UUID
  TextColumn get id => text()();

  /// Foreign key referencing the parent notebook
  TextColumn get notebookId => text().references(Notebooks, #id)();

  /// Foreign key referencing the visual template (presentation layer)
  TextColumn get templateId => text().references(Templates, #id)();

  /// Optional entry title
  TextColumn get title => text().nullable()();

  /// Rich text semantic content encoded as Flutter Quill Delta JSON
  TextColumn get contentDelta => text()();

  /// Plain text representation extracted from Delta, used for full-text search indexing
  TextColumn get plainText => text()();

  /// User-selected date for this diary entry (stored as DateTime epoch)
  DateTimeColumn get entryDate => dateTime()();

  /// Mood rating (scale 1 to 5)
  IntColumn get mood => integer().nullable()();

  /// Weather indicator string/tag
  TextColumn get weather => text().nullable()();

  /// Whether this entry is flagged as a weekly review
  BoolColumn get isWeeklyReview => boolean().withDefault(const Constant(false))();

  /// ISO week number when entry is a weekly review
  IntColumn get weekNumber => integer().nullable()();

  /// Timestamp when Time Capsule locks expire (null if immediately accessible)
  DateTimeColumn get unlockAt => dateTime().nullable()();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record last-modified timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Soft delete flag (0 = active, 1 = in 30-day trash bin)
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

