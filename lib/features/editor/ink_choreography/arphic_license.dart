import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Package label shown in the app's licence page for the stroke data.
const String arphicLicensePackage =
    'Make Me a Hanzi stroke data (Arphic PL KaitiM GB / Arphic PL UKai)';

const String arphicLicenseAssetPath =
    'assets/calligraphy/ARPHIC_PUBLIC_LICENSE.txt';

/// Registers the Arphic Public License text (ADR-0011) with Flutter's
/// `LicenseRegistry`. Call once at startup; the asset is read lazily.
void registerArphicLicense({AssetBundle? bundle}) {
  LicenseRegistry.addLicense(() async* {
    final text = await (bundle ?? rootBundle).loadString(
      arphicLicenseAssetPath,
    );
    yield LicenseEntryWithLineBreaks(const [arphicLicensePackage], text);
  });
}
