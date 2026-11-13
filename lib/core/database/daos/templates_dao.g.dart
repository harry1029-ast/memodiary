// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'templates_dao.dart';

// ignore_for_file: type=lint
mixin _$TemplatesDaoMixin on DatabaseAccessor<AppDatabase> {
  $TemplatesTable get templates => attachedDatabase.templates;
  $NotebooksTable get notebooks => attachedDatabase.notebooks;
  $EntriesTable get entries => attachedDatabase.entries;
  TemplatesDaoManager get managers => TemplatesDaoManager(this);
}

class TemplatesDaoManager {
  final _$TemplatesDaoMixin _db;
  TemplatesDaoManager(this._db);
  $$TemplatesTableTableManager get templates =>
      $$TemplatesTableTableManager(_db.attachedDatabase, _db.templates);
  $$NotebooksTableTableManager get notebooks =>
      $$NotebooksTableTableManager(_db.attachedDatabase, _db.notebooks);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db.attachedDatabase, _db.entries);
}
