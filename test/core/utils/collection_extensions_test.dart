import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/utils/collection_extensions.dart';

void main() {
  group('SafeIndexListExtension Tests', () {
    test('safeClampIndex returns null on empty list', () {
      final emptyList = <String>[];
      expect(emptyList.safeClampIndex(0), isNull);
      expect(emptyList.safeClampIndex(-5), isNull);
      expect(emptyList.safeClampIndex(10), isNull);
    });

    test('safeClampIndex correctly bounds within [0, length - 1]', () {
      final list = ['a', 'b', 'c'];
      expect(list.safeClampIndex(-1), 0);
      expect(list.safeClampIndex(0), 0);
      expect(list.safeClampIndex(1), 1);
      expect(list.safeClampIndex(2), 2);
      expect(list.safeClampIndex(3), 2);
      expect(list.safeClampIndex(99), 2);
    });
  });
}

