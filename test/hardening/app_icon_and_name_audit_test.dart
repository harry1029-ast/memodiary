import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// SPEC-023 Implementation Decision 6: the app is named 云皓日记 everywhere
/// and ships the diarist's painting as an adaptive, themed and iOS icon.
void main() {
  const appName = '云皓日记';
  const res = 'android/app/src/main/res';
  const densities = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];
  const appIconSet = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

  group('App name', () {
    test('Android default and zh labels are $appName, referenced by the manifest', () {
      for (final strings in ['$res/values/strings.xml', '$res/values-zh/strings.xml']) {
        expect(File(strings).readAsStringSync(), contains('<string name="app_name">$appName</string>'),
            reason: strings);
      }
      expect(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        contains('android:label="@string/app_name"'),
      );
    });

    test('iOS display name is $appName in Info.plist and the zh-Hans strings', () {
      expect(
        File('ios/Runner/Info.plist').readAsStringSync(),
        contains('<key>CFBundleDisplayName</key>\n\t<string>$appName</string>'),
      );
      expect(
        File('ios/Runner/zh-Hans.lproj/InfoPlist.strings').readAsStringSync(),
        contains('"CFBundleDisplayName" = "$appName";'),
      );
    });

    test('no user-visible iOS or Android string still says MemoDiary', () {
      final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
      final plistValues = RegExp(r'<string>([^<]*)</string>').allMatches(infoPlist).map((match) => match.group(1)!);
      expect(plistValues, isNotEmpty);
      for (final value in plistValues) {
        expect(value, isNot(contains('MemoDiary')), reason: 'ios/Runner/Info.plist: $value');
      }

      final localized = [
        for (final dir in Directory('ios/Runner').listSync().whereType<Directory>())
          if (dir.path.endsWith('.lproj'))
            ...dir.listSync().whereType<File>().where((file) => file.path.endsWith('.strings')),
        for (final dir in Directory(res).listSync().whereType<Directory>())
          if (File('${dir.path}/strings.xml').existsSync()) File('${dir.path}/strings.xml'),
        File('android/app/src/main/AndroidManifest.xml'),
      ];
      expect(localized, isNotEmpty);
      for (final file in localized) {
        expect(file.readAsStringSync(), isNot(contains('MemoDiary')), reason: file.path);
      }
    });
  });

  group('Android launcher icon', () {
    test('manifest names the square and round launcher icons', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
      expect(manifest, contains('android:roundIcon="@mipmap/ic_launcher_round"'));
    });

    test('square and round adaptive icons declare background, foreground and monochrome layers', () {
      for (final name in ['ic_launcher', 'ic_launcher_round']) {
        final xml = File('$res/mipmap-anydpi-v26/$name.xml').readAsStringSync();
        expect(xml, contains('<background android:drawable="@drawable/ic_launcher_background"/>'), reason: name);
        expect(xml, contains('android:drawable="@drawable/ic_launcher_foreground"'), reason: name);
        expect(xml, contains('<monochrome>'), reason: name);
        expect(xml, contains('android:drawable="@drawable/ic_launcher_monochrome"'), reason: name);
      }
    });

    test('every density ships the adaptive layers and the legacy square and round PNGs', () {
      for (final density in densities) {
        for (final layer in ['ic_launcher_background', 'ic_launcher_foreground', 'ic_launcher_monochrome']) {
          expect(File('$res/drawable-$density/$layer.png').existsSync(), isTrue, reason: '$density $layer');
        }
        for (final legacy in ['ic_launcher', 'ic_launcher_round']) {
          expect(File('$res/mipmap-$density/$legacy.png').existsSync(), isTrue, reason: '$density $legacy');
        }
      }
    });
  });

  group('iOS app icon', () {
    test('the 1024px marketing icon is listed and has no alpha channel', () {
      expect(File('$appIconSet/Contents.json').readAsStringSync(), contains('Icon-App-1024x1024@1x.png'));
      final png = File('$appIconSet/Icon-App-1024x1024@1x.png').readAsBytesSync();
      final header = ByteData.sublistView(png);
      expect(header.getUint32(16), 1024, reason: 'IHDR width');
      expect(header.getUint32(20), 1024, reason: 'IHDR height');
      // IHDR colour type: 0 = greyscale, 2 = RGB; 4 and 6 carry alpha.
      expect([0, 2], contains(png[25]), reason: 'App Store rejects a 1024 icon with alpha');
      expect(String.fromCharCodes(png).contains('tRNS'), isFalse, reason: 'no transparency chunk');
    });
  });
}
