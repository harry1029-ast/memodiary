import 'package:drift/drift.dart';
import 'templates.dart';

/// Notebooks table organizing diary entries.
@DataClassName('Notebook')
class Notebooks extends Table {
  /// Unique notebook UUID or system ID
  TextColumn get id => text()();

  /// Notebook display title
  TextColumn get title => text().withLength(min: 1, max: 100)();

  /// Default template used for new entries in this notebook
  TextColumn get defaultTemplateId => text().references(Templates, #id)();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

