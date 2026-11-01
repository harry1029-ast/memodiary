import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/settings/services/signature_seal_service.dart';

void main() {
  group('SignatureSealService Tests', () {
    late FlutterSecureStorage storage;
    late SignatureSealService service;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      storage = const FlutterSecureStorage();
      service = SignatureSealService(storage: storage);
    });

    test('defaults to 心迹安放 when no seal text has been configured', () async {
      final text = await service.getSealText();
      expect(text, equals('心迹安放'));
    });

    test('persists and retrieves valid 2 to 4 character signature seal text', () async {
      await service.setSealText('清欢记');
      expect(await service.getSealText(), equals('清欢记'));

      await service.setSealText('拾光存卷');
      expect(await service.getSealText(), equals('拾光存卷'));

      await service.setSealText('墨客');
      expect(await service.getSealText(), equals('墨客'));
    });

    test('rejects texts shorter than 2 or longer than 4 characters and preserves default or previous text', () async {
      await service.setSealText('心迹安放');

      // 1 char -> rejected
      await service.setSealText('墨');
      expect(await service.getSealText(), equals('心迹安放'));

      // 5 chars -> rejected
      await service.setSealText('江南烟雨客');
      expect(await service.getSealText(), equals('心迹安放'));

      // empty / whitespace -> rejected
      await service.setSealText('   ');
      expect(await service.getSealText(), equals('心迹安放'));
    });
  });
}
