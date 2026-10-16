import 'dart:async';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

typedef DictationResultCallback = void Function(String text, bool isFinal);

/// Zero-cost native speech-to-text service calling iOS Speech / Android SpeechRecognizer.
/// Implements auto-restart on silence timeouts for uninterrupted voice journaling.
class DictationService {
  final SpeechToText _speech;
  bool _isContinuousActive = false;
  bool _isInitialized = false;
  DictationResultCallback? _currentCallback;

  DictationService({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  bool get isListening => _speech.isListening;
  bool get isAvailable => _speech.isAvailable;
  bool get isContinuousActive => _isContinuousActive;

  /// Initializes the native speech recognizer
  Future<bool> initialize({
    Function(SpeechRecognitionError)? onError,
    Function(String)? onStatus,
  }) async {
    if (_isInitialized) return true;

    _isInitialized = await _speech.initialize(
      onError: (val) {
        onError?.call(val);
        _handleRecognitionStopped();
      },
      onStatus: (status) {
        onStatus?.call(status);
        if (status == 'done' || status == 'notListening') {
          _handleRecognitionStopped();
        }
      },
    );
    return _isInitialized;
  }

  /// Starts listening with auto-restart loop on pause timeout
  Future<void> startDictation({
    required DictationResultCallback onResult,
    Duration pauseFor = const Duration(seconds: 4),
    Duration listenFor = const Duration(minutes: 5),
    String? localeId,
  }) async {
    _currentCallback = onResult;
    _isContinuousActive = true;

    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) {
        _isContinuousActive = false;
        return;
      }
    }

    await _startNativeListening(pauseFor: pauseFor, listenFor: listenFor, localeId: localeId);
  }

  Future<void> _startNativeListening({
    Duration pauseFor = const Duration(seconds: 4),
    Duration listenFor = const Duration(minutes: 5),
    String? localeId,
  }) async {
    if (!_isContinuousActive) return;

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        _currentCallback?.call(result.recognizedWords, result.finalResult);
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
        pauseFor: pauseFor,
        listenFor: listenFor,
        localeId: localeId,
      ),
    );
  }

  void _handleRecognitionStopped() {
    // If continuous dictation is still desired, automatically re-arm listening
    if (_isContinuousActive) {
      Timer(const Duration(milliseconds: 300), () {
        if (_isContinuousActive && !_speech.isListening) {
          _startNativeListening();
        }
      });
    }
  }

  /// Stops voice dictation permanently
  Future<void> stopDictation() async {
    _isContinuousActive = false;
    await _speech.stop();
  }

  /// Cancels voice dictation and discards pending words
  Future<void> cancelDictation() async {
    _isContinuousActive = false;
    await _speech.cancel();
  }

  void dispose() {
    _isContinuousActive = false;
    _speech.stop();
  }
}
