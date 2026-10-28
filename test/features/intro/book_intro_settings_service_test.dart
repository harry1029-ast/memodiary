import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/intro/services/book_intro_settings_service.dart';

class _MockSecureStorage extends FlutterSecureStorage {
  final Map<String, String> data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      data[key] = value;
    } else {
      data.remove(key);
    }
  }
}

void main() {
  group('BookIntroSettingsService Tests', () {
    late _MockSecureStorage mockStorage;
    late BookIntroSettingsService service;

    setUp(() {
      mockStorage = _MockSecureStorage();
      service = BookIntroSettingsService(storage: mockStorage);
    });

    test('defaults to true when no value is stored', () async {
      expect(await service.getShouldShowOnLaunch(), isTrue);
    });

    test('persists and retrieves false when toggled off', () async {
      await service.setShouldShowOnLaunch(false);
      expect(await service.getShouldShowOnLaunch(), isFalse);
    });

    test('persists and retrieves true when toggled on', () async {
      await service.setShouldShowOnLaunch(false);
      expect(await service.getShouldShowOnLaunch(), isFalse);

      await service.setShouldShowOnLaunch(true);
      expect(await service.getShouldShowOnLaunch(), isTrue);
    });
  });
}

