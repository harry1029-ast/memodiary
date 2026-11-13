import 'package:drift/drift.dart';
import '../../../features/import_export/models/backup_manifest.dart';
import '../app_database.dart';
import '../tables/album_collections.dart';
import '../tables/album_photos.dart';
import '../tables/entries.dart';
import '../tables/media_attachments.dart';
import '../tables/notebooks.dart';
import '../tables/templates.dart';

part 'backup_dao.g.dart';

/// Data access object for encrypted backup snapshot export and transactional
/// database restore.
@DriftAccessor(tables: [
  Templates,
  Notebooks,
  Entries,
  MediaAttachments,
  AlbumCollections,
  AlbumPhotos,
])
class BackupDao extends DatabaseAccessor<AppDatabase> with _$BackupDaoMixin {
  BackupDao(super.attachedDatabase);

  /// Exports a consistent snapshot of all SQLite tables inside a transaction.
  Future<BackupDatabaseSnapshot> exportAllTablesSnapshot() {
    return transaction(() async {
      final allTemplates = await select(templates).get();
      final allNotebooks = await select(notebooks).get();
      final allEntries = await select(entries).get();
      final allMedia = await select(mediaAttachments).get();
      final allAlbumCollections = await select(albumCollections).get();
      final allAlbumPhotos = await select(albumPhotos).get();
      return BackupDatabaseSnapshot(
        templates: allTemplates,
        notebooks: allNotebooks,
        entries: allEntries,
        mediaAttachments: allMedia,
        albumCollections: allAlbumCollections,
        albumPhotos: allAlbumPhotos,
      );
    });
  }

  /// Atomically replaces all database records with [snapshot] inside a single
  /// transaction, reusing [TemplatesDao]'s canonical built-in template seeds.
  Future<void> replaceAllFromBackup(BackupDatabaseSnapshot snapshot) async {
    await customStatement('PRAGMA foreign_keys = ON;');
    await transaction(() async {
      // 1. Delete existing rows in reverse foreign-key dependency order
      await delete(albumPhotos).go();
      await delete(albumCollections).go();
      await delete(mediaAttachments).go();
      await delete(entries).go();
      await customStatement('DELETE FROM entries_fts;');
      await customStatement('DELETE FROM media_fts;');
      await delete(notebooks).go();
      await delete(templates).go();

      // 2. Ensure the 4 default system templates are present if omitted in snapshot
      final templateIds =
          snapshot.templates.map((template) => template.id).toSet();
      final missingDefaultTemplates = TemplatesDao.buildDefaultTemplateCompanions()
          .where((companion) => !templateIds.contains(companion.id.value));

      // 3. Insert records in foreign-key dependency order
      for (final companion in missingDefaultTemplates) {
        await into(templates).insert(companion);
      }
      for (final template in snapshot.templates) {
        await into(templates).insert(template);
      }

      final validTemplateIds = <String>{
        ...TemplatesDao.builtInTemplateIds,
        ...templateIds,
      };

      final validNotebookIds = <String>{};
      if (snapshot.notebooks.isNotEmpty) {
        for (final notebook in snapshot.notebooks) {
          if (!validTemplateIds.contains(notebook.defaultTemplateId)) {
            throw StateError(
              'Foreign key violation: notebook ${notebook.id} references missing template ${notebook.defaultTemplateId}.',
            );
          }
          await into(notebooks).insert(notebook);
          validNotebookIds.add(notebook.id);
        }
      } else {
        final defaultNotebook = TemplatesDao.buildDefaultNotebookCompanion();
        await into(notebooks).insert(defaultNotebook);
        validNotebookIds.add(defaultNotebook.id.value);
      }

      final validEntryIds = <String>{};
      for (final entry in snapshot.entries) {
        if (!validNotebookIds.contains(entry.notebookId)) {
          throw StateError(
            'Foreign key violation: entry ${entry.id} references missing notebook ${entry.notebookId}.',
          );
        }
        if (!validTemplateIds.contains(entry.templateId)) {
          throw StateError(
            'Foreign key violation: entry ${entry.id} references missing template ${entry.templateId}.',
          );
        }
        await into(entries).insert(entry);
        validEntryIds.add(entry.id);
      }

      for (final attachment in snapshot.mediaAttachments) {
        if (!validEntryIds.contains(attachment.entryId)) {
          throw StateError(
            'Foreign key violation: mediaAttachment ${attachment.id} references missing entry ${attachment.entryId}.',
          );
        }
        await into(mediaAttachments).insert(attachment);
      }

      final validCollectionIds = <String>{};
      for (final collection in snapshot.albumCollections) {
        await into(albumCollections).insert(collection);
        validCollectionIds.add(collection.id);
      }

      for (final photo in snapshot.albumPhotos) {
        if (!validCollectionIds.contains(photo.collectionId)) {
          throw StateError(
            'Foreign key violation: albumPhoto ${photo.id} references missing albumCollection ${photo.collectionId}.',
          );
        }
        await into(albumPhotos).insert(photo);
      }
    });
  }
}
