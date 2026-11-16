import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/ink_choreography/arphic_license.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registered licence exposes the shipped Arphic Public License', () async {
    registerArphicLicense();
    final entries = await LicenseRegistry.licenses.toList();
    final arphic = entries.where(
      (entry) => entry.packages.contains(arphicLicensePackage),
    );
    expect(arphic, hasLength(1));
    final text = arphic.single.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('ARPHIC PUBLIC LICENSE'));
  });
}
