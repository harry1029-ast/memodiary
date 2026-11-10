import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// System copies of Noto Sans SC, the CJK face Android falls back to and whose
/// proportional digits set the real width of a date line. Under `flutter test`
/// every glyph is Ahem (one em wide), which overstates Latin digits.
const _realCjkFontCandidates = [
  '/mnt/c/Windows/Fonts/NotoSansSC-VF.ttf',
  '/usr/share/fonts/truetype/noto/NotoSansSC-VF.ttf',
  '/usr/share/fonts/opentype/noto/NotoSansSC-VF.otf',
  '/Library/Fonts/NotoSansSC-VF.ttf',
];

/// The first installed real CJK font file, or null when this machine has none.
/// Pass `skip: realCjkFontPath == null` to tests that need one.
final String? realCjkFontPath = _realCjkFontCandidates
    .cast<String?>()
    .firstWhere((path) => File(path!).existsSync(), orElse: () => null);

/// Registers the real CJK font under [family] so text styled with that family
/// is measured with true glyph widths. Requires [realCjkFontPath] to be non-null.
Future<void> loadRealCjkFont(WidgetTester tester, String family) async {
  final bytes = File(realCjkFontPath!).readAsBytesSync();
  final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes)));
  await tester.runAsync(loader.load);
}
