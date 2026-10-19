import 'dart:io';
import 'package:file_picker/file_picker.dart';

/// Abstract service decoupling file selection and disk saving for testability.
abstract class FileSelectorService {
  /// Prompts the user to pick a .txt or .md diary file
  Future<File?> pickTextOrMarkdownFile();

  /// Prompts the user to select a destination path and writes exported content
  Future<String?> saveExportFile({
    required String fileName,
    required String content,
  });

  /// Prompts the user to pick a `.mdbak` full-archive backup file.
  Future<File?> pickBackupFile();

  /// Prompts the user to select a destination path and copies [sourceFile] to it.
  Future<String?> saveBackupFile({
    required String fileName,
    required File sourceFile,
  });
}

/// Production implementation utilizing native OS file picker
class NativeFileSelectorService implements FileSelectorService {
  const NativeFileSelectorService();

  @override
  Future<File?> pickTextOrMarkdownFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'markdown'],
    );
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  @override
  Future<String?> saveExportFile({
    required String fileName,
    required String content,
  }) async {
    final path = await FilePicker.saveFile(
      dialogTitle: 'Save Diary Export',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['md', 'txt'],
    );
    if (path != null) {
      final file = File(path);
      await file.writeAsString(content);
      return file.path;
    }
    return null;
  }

  @override
  Future<File?> pickBackupFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
    );
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  @override
  Future<String?> saveBackupFile({
    required String fileName,
    required File sourceFile,
  }) async {
    final bytes = await sourceFile.readAsBytes();
    final path = await FilePicker.saveFile(
      dialogTitle: 'Save MemoDiary Backup',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['mdbak'],
      bytes: bytes,
    );
    if (path != null) {
      final outFile = File(path);
      if (!await outFile.exists() || await outFile.length() == 0) {
        await sourceFile.copy(path);
      }
      return path;
    }
    return null;
  }
}
