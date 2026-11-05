import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Release Build Packaging & ProGuard Regression Audit', () {
    test('android/app/build.gradle.kts enforces legacy packaging for native libraries', () {
      final buildGradleFile = File('android/app/build.gradle.kts');
      expect(
        buildGradleFile.existsSync(),
        isTrue,
        reason: 'android/app/build.gradle.kts must exist',
      );

      final content = buildGradleFile.readAsStringSync();
      expect(
        content.contains('useLegacyPackaging = true'),
        isTrue,
        reason: 'build.gradle.kts must enable useLegacyPackaging = true to ensure '
            'native libraries (libsqlcipher.so) are extracted at install time, '
            'preventing UnsatisfiedLinkError dlopen crashes on launch in release builds.',
      );
      expect(
        content.contains('proguard-rules.pro'),
        isTrue,
        reason: 'build.gradle.kts release buildType must configure proguard-rules.pro',
      );
    });

    test('android/app/proguard-rules.pro exists and preserves critical reflection & JNI symbols', () {
      final proguardFile = File('android/app/proguard-rules.pro');
      expect(
        proguardFile.existsSync(),
        isTrue,
        reason: 'android/app/proguard-rules.pro must exist',
      );

      final rules = proguardFile.readAsStringSync();

      // ML Kit & Firebase ComponentRegistrars
      expect(
        rules.contains('com.google.firebase.components.ComponentRegistrar'),
        isTrue,
        reason: 'Must preserve ComponentRegistrar constructors used by MlKitInitProvider '
            'to prevent NoSuchMethodException crashes on cold launch.',
      );
      expect(
        rules.contains('com.google.mlkit.**'),
        isTrue,
        reason: 'Must preserve ML Kit text recognition packages.',
      );

      // SQLCipher & SQLite
      expect(
        rules.contains('net.zetetic.**'),
        isTrue,
        reason: 'Must preserve Zetetic SQLCipher symbols.',
      );
      expect(
        rules.contains('eu.simonbinder.sqlite3_flutter_libs.**'),
        isTrue,
        reason: 'Must preserve sqlite3_flutter_libs plugin symbols.',
      );

      // Keystore & Storage
      expect(
        rules.contains('androidx.security.crypto.**'),
        isTrue,
        reason: 'Must preserve Jetpack Security Crypto symbols for EncryptedSharedPreferences.',
      );

      // Deferred components suppression
      expect(
        rules.contains('-dontwarn com.google.android.play.core.**'),
        isTrue,
        reason: 'Must suppress missing Play Core references from Flutter engine deferred components.',
      );
    });
  });
}

