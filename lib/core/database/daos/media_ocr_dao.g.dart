// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_ocr_dao.dart';

// ignore_for_file: type=lint
mixin _$MediaOcrDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediaAttachmentsTable get mediaAttachments =>
      attachedDatabase.mediaAttachments;
  $EntriesTable get entries => attachedDatabase.entries;
  $AlbumCollectionsTable get albumCollections =>
      attachedDatabase.albumCollections;
  $AlbumPhotosTable get albumPhotos => attachedDatabase.albumPhotos;
  MediaOcrDaoManager get managers => MediaOcrDaoManager(this);
}

class MediaOcrDaoManager {
  final _$MediaOcrDaoMixin _db;
  MediaOcrDaoManager(this._db);
  $$MediaAttachmentsTableTableManager get mediaAttachments =>
      $$MediaAttachmentsTableTableManager(
          _db.attachedDatabase, _db.mediaAttachments);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db.attachedDatabase, _db.entries);
  $$AlbumCollectionsTableTableManager get albumCollections =>
      $$AlbumCollectionsTableTableManager(
          _db.attachedDatabase, _db.albumCollections);
  $$AlbumPhotosTableTableManager get albumPhotos =>
      $$AlbumPhotosTableTableManager(_db.attachedDatabase, _db.albumPhotos);
}
