import 'dart:async';
import 'package:memodiary/core/services/ocr/ocr_models.dart';
import 'package:memodiary/core/services/ocr/ocr_service.dart';

/// Shared deterministic test double for [OcrService] (`CODING_STANDARDS.md § 4`).
///
/// Supports scripted [OcrResult] responses by exact path or trailing suffix,
/// custom async callbacks/delays for queue concurrency tests, error injection,
/// and invocation tracking.
class FakeOcrService implements OcrService {
  final Map<String, OcrResult> _resultsByPath;
  final Map<String, Object> _errorsByPath;
  OcrResult defaultResult;
  Duration delay;
  Object? globalError;
  Future<OcrResult> Function(String absolutePath)? onRecognize;

  final List<String> recognizedPaths = <String>[];
  bool isDisposed = false;

  FakeOcrService({
    Map<String, OcrResult>? resultsByPath,
    Map<String, Object>? errorsByPath,
    this.defaultResult = OcrResult.empty,
    this.delay = Duration.zero,
    this.globalError,
    this.onRecognize,
  })  : _resultsByPath = Map<String, OcrResult>.from(
          resultsByPath ?? const <String, OcrResult>{},
        ),
        _errorsByPath = Map<String, Object>.from(
          errorsByPath ?? const <String, Object>{},
        );

  int get callCount => recognizedPaths.length;

  /// Registers or overrides a scripted [result] for [pathOrSuffix].
  void setResult(String pathOrSuffix, OcrResult result) {
    _errorsByPath.remove(pathOrSuffix);
    _resultsByPath[pathOrSuffix] = result;
  }

  /// Configures [recognizeText] to throw [error] when matching [pathOrSuffix].
  void setError(String pathOrSuffix, Object error) {
    _resultsByPath.remove(pathOrSuffix);
    _errorsByPath[pathOrSuffix] = error;
  }

  /// Clears recorded call history without removing scripted rules.
  void clearHistory() {
    recognizedPaths.clear();
  }

  @override
  Future<OcrResult> recognizeText(String absolutePath) async {
    recognizedPaths.add(absolutePath);

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    final activeGlobalError = globalError;
    if (activeGlobalError != null) {
      Error.throwWithStackTrace(activeGlobalError, StackTrace.current);
    }

    final matchedError = _lookupByExactOrSuffix<Object>(_errorsByPath, absolutePath);
    if (matchedError != null) {
      Error.throwWithStackTrace(matchedError, StackTrace.current);
    }

    final customHandler = onRecognize;
    if (customHandler != null) {
      return customHandler(absolutePath);
    }

    final matchedResult =
        _lookupByExactOrSuffix<OcrResult>(_resultsByPath, absolutePath);
    return matchedResult ?? defaultResult;
  }

  T? _lookupByExactOrSuffix<T>(Map<String, T> registry, String absolutePath) {
    final exact = registry[absolutePath];
    if (exact != null) {
      return exact;
    }
    final normalizedPath = absolutePath.replaceAll(r'\', '/');
    for (final entry in registry.entries) {
      final normalizedKey = entry.key.replaceAll(r'\', '/');
      if (normalizedKey.isNotEmpty && normalizedPath.endsWith(normalizedKey)) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
  }
}
