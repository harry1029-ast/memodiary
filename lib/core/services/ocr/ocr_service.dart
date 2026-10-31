import 'dart:io';
import 'package:flutter/services.dart';
import 'ocr_models.dart';
import 'ocr_result_normalizer.dart';

/// Primary vision seam for 100% offline on-device text recognition.
abstract class OcrService {
  /// Recognizes text and normalized line bounding boxes from [absolutePath].
  ///
  /// Returns [OcrResult.empty] when an image contains zero recognizable text
  /// or cannot be decoded by the native vision engine.
  Future<OcrResult> recognizeText(String absolutePath);

  /// Releases any underlying native recognition resources.
  Future<void> dispose();
}

/// Pure-Dart no-op fallback returning [OcrResult.empty] on headless desktop
/// platforms (Linux/macOS/Windows) and automated test runners.
class StubOcrService implements OcrService {
  const StubOcrService();

  @override
  Future<OcrResult> recognizeText(String absolutePath) async {
    return OcrResult.empty;
  }

  @override
  Future<void> dispose() async {}
}

/// Native platform-channel [OcrService] backed by `memodiary/ocr`
/// (Apple Vision on iOS 15.0+, bundled ML Kit Chinese v2 on Android).
///
/// Automatically falls back to [StubOcrService] on desktop platforms or when
/// the native channel throws [MissingPluginException] or [PlatformException].
class PlatformOcrService implements OcrService {
  static const String channelName = 'memodiary/ocr';

  final MethodChannel _channel;
  final OcrService _fallback;
  final bool Function() _isSupportedPlatform;
  bool _isDisposed = false;

  PlatformOcrService({
    MethodChannel? channel,
    OcrService? fallback,
    bool Function()? isSupportedPlatform,
  })  : _channel = channel ?? const MethodChannel(channelName),
        _fallback = fallback ?? const StubOcrService(),
        _isSupportedPlatform =
            isSupportedPlatform ?? _defaultSupportedPlatformCheck;

  static bool _defaultSupportedPlatformCheck() {
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  Future<OcrResult> recognizeText(String absolutePath) async {
    if (_isDisposed || absolutePath.trim().isEmpty) {
      return _fallback.recognizeText(absolutePath);
    }
    if (!_isSupportedPlatform()) {
      return _fallback.recognizeText(absolutePath);
    }

    try {
      final rawPayload = await _channel.invokeMapMethod<Object?, Object?>(
        'recognize',
        <String, Object?>{'path': absolutePath},
      );
      return OcrResultNormalizer.normalizeChannelPayload(rawPayload);
    } on MissingPluginException {
      return _fallback.recognizeText(absolutePath);
    } on PlatformException {
      return _fallback.recognizeText(absolutePath);
    }
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    await _fallback.dispose();
  }
}
