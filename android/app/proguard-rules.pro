# Flutter & Platform Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn com.google.android.play.core.**

# ML Kit (On-Device Text Recognition v2)
# Preserves dynamically discovered component registrars instantiated via reflection
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
    public *;
}
-keep class com.google.firebase.components.** { *; }
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.internal.mlkit_**

# App Native Channels (ADR 0004)
-keep class com.memodiary.memodiary.** { *; }

# SQLCipher & Native Database (ADR 0001 / GEMINI.md)
-keep class net.zetetic.** { *; }
-dontwarn net.zetetic.**
-keep class eu.simonbinder.sqlite3_flutter_libs.** { *; }

# Security & Hardware Keystore (flutter_secure_storage)
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Preserve native JNI methods across all classes
-keepclasseswithmembernames class * {
    native <methods>;
}

