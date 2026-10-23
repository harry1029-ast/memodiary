import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/albums/data/album_repository.dart';
import 'package:memodiary/features/albums/services/album_ingestion_service.dart';
import 'package:path/path.dart' as p;

/// Deterministic 1x1 transparent PNG byte fixture (valid magic header + IEND)
/// so `Image.file` and `ui.instantiateImageCodec` never fail in widget tests.
final Uint8List kDeterministic1x1Png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

/// Shared test harness context bundling an in-memory [AppDatabase],
/// temporary sandbox directory, [MediaSandboxService], [AlbumRepository],
/// and [AlbumIngestionService].
class AlbumTestHarness {
  final AppDatabase database;
  final Directory tempDir;
  final MediaSandboxService mediaService;
  final AlbumRepository repository;
  final AlbumIngestionService ingestionService;

  AlbumTestHarness._({
    required this.database,
    required this.tempDir,
    required this.mediaService,
    required this.repository,
    required this.ingestionService,
  });

  static Future<AlbumTestHarness> create({
    Future<DateTime?> Function(File source)? captureDateReader,
    DateTime Function()? clock,
  }) async {
    final db = AppDatabase.memory();
    final dir = await Directory.systemTemp.createTemp('memodiary_albums_test_');
    final media = MediaSandboxService(
      baseDirProvider: () async => dir,
      compressor: (
        sourcePath,
        targetPath, {
        int minWidth = 1600,
        int minHeight = 1600,
        int quality = 80,
      }) async {
        final src = File(sourcePath);
        if (!src.existsSync()) {
          throw FileSystemException('Missing source file', sourcePath);
        }
        final target = File(targetPath);
        target.parent.createSync(recursive: true);
        target.writeAsBytesSync(kDeterministic1x1Png);
        return target;
      },
      aspectRatioExtractor: (_) async => 1.0,
    );
    final repo = AlbumRepository(
      database: db,
      mediaService: media,
    );
    final ingestion = AlbumIngestionService(
      repository: repo,
      mediaService: media,
      captureDateReader: captureDateReader,
      clock: clock,
    );

    return AlbumTestHarness._(
      database: db,
      tempDir: dir,
      mediaService: media,
      repository: repo,
      ingestionService: ingestion,
    );
  }

  /// Creates a source image file in the temporary directory with valid 1x1 PNG bytes.
  File createSourcePhoto(String name) {
    final file = File(p.join(tempDir.path, name));
    file.writeAsBytesSync(kDeterministic1x1Png);
    return file;
  }

  /// Disposes the database and removes the temporary sandbox directory.
  Future<void> dispose() async {
    await database.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}

/// Pumps an album screen/widget inside [InkDiaryTheme.light] with a standard mobile
/// viewport (390x844).
Future<void> pumpAlbumScreen(
  WidgetTester tester,
  Widget child, {
  Size viewportSize = const Size(390, 844),
}) async {
  tester.view.physicalSize = viewportSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: InkDiaryTheme.light,
      home: child,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// Disposes the mounted widget tree and elapses time so any active Drift stream
/// timers are cleanly drained before `_verifyInvariants` checks the test.
Future<void> tearDownAlbumScreen(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 100));
}

