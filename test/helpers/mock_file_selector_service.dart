import 'dart:io';

import 'package:memodiary/features/import_export/services/file_selector_service.dart';

/// Shared [FileSelectorService] double: returns the files a test sets and
/// records what the code under test saved.
class MockFileSelectorService implements FileSelectorService {
  File? pickedFile;
  File? pickedBackupFile;
  String? lastSavedFileName;
  String? lastSavedContent;
  File? lastSavedBackupSource;
  String? mockBackupSaveDestination;

  @override
  Future<File?> pickTextOrMarkdownFile() async => pickedFile;

  @override
  Future<String?> saveExportFile({
    required String fileName,
    required String content,
  }) async {
    lastSavedFileName = fileName;
    lastSavedContent = content;
    return '/mock/path/$fileName';
  }

  @override
  Future<File?> pickBackupFile() async => pickedBackupFile;

  @override
  Future<String?> saveBackupFile({
    required String fileName,
    required File sourceFile,
  }) async {
    lastSavedFileName = fileName;
    lastSavedBackupSource = sourceFile;
    if (mockBackupSaveDestination != null) {
      await sourceFile.copy(mockBackupSaveDestination!);
      return mockBackupSaveDestination;
    }
    return '/mock/path/$fileName';
  }
}
