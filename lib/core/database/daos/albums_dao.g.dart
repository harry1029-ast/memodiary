// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'albums_dao.dart';

// ignore_for_file: type=lint
mixin _$AlbumsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AlbumCollectionsTable get albumCollections =>
      attachedDatabase.albumCollections;
  $AlbumPhotosTable get albumPhotos => attachedDatabase.albumPhotos;
  AlbumsDaoManager get managers => AlbumsDaoManager(this);
}

class AlbumsDaoManager {
  final _$AlbumsDaoMixin _db;
  AlbumsDaoManager(this._db);
  $$AlbumCollectionsTableTableManager get albumCollections =>
      $$AlbumCollectionsTableTableManager(
          _db.attachedDatabase, _db.albumCollections);
  $$AlbumPhotosTableTableManager get albumPhotos =>
      $$AlbumPhotosTableTableManager(_db.attachedDatabase, _db.albumPhotos);
}
