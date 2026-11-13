// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_dao.dart';

// ignore_for_file: type=lint
mixin _$BackupDaoMixin on DatabaseAccessor<AppDatabase> {
  $TemplatesTable get templates => attachedDatabase.templates;
  $NotebooksTable get notebooks => attachedDatabase.notebooks;
  $EntriesTable get entries => attachedDatabase.entries;
  $MediaAttachmentsTable get mediaAttachments =>
      attachedDatabase.mediaAttachments;
  $AlbumCollectionsTable get albumCollections =>
      attachedDatabase.albumCollections;
  $AlbumPhotosTable get albumPhotos => attachedDatabase.albumPhotos;
  BackupDaoManager get managers => BackupDaoManager(this);
}

class BackupDaoManager {
  final _$BackupDaoMixin _db;
  BackupDaoManager(this._db);
  $$TemplatesTableTableManager get templates =>
      $$TemplatesTableTableManager(_db.attachedDatabase, _db.templates);
  $$NotebooksTableTableManager get notebooks =>
      $$NotebooksTableTableManager(_db.attachedDatabase, _db.notebooks);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db.attachedDatabase, _db.entries);
  $$MediaAttachmentsTableTableManager get mediaAttachments =>
      $$MediaAttachmentsTableTableManager(
          _db.attachedDatabase, _db.mediaAttachments);
  $$AlbumCollectionsTableTableManager get albumCollections =>
      $$AlbumCollectionsTableTableManager(
          _db.attachedDatabase, _db.albumCollections);
  $$AlbumPhotosTableTableManager get albumPhotos =>
      $$AlbumPhotosTableTableManager(_db.attachedDatabase, _db.albumPhotos);
}
