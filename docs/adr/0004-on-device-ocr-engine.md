# Dual-Engine Native On-Device OCR Channel & Manifest Network Quarantine

## Context
Phase 17 introduces offline Optical Character Recognition (OCR) so diarists can search words printed or handwritten inside attached diary photos and travel album photographs (`media_fts`) and view matched lines highlighted in-app.

Evaluating candidate OCR stacks against MemoDiary's core architectural invariants (**100% Local-First**, **Zero Backend**, **$0 Build & Runtime Cost**, **Zero Network Permissions**, and **iOS 15.0+ / Android 10+ deployment targets**) exposed three structural conflicts with standard third-party Flutter OCR plugins (`google_mlkit_text_recognition`):

1. **FOSS & Binary Licensing Boundary**:
   - `GEMINI.md § 1` mandates 100% free open-source packages (MIT/BSD/Apache/SIL OFL) and built-in native OS APIs. While the Dart wrapper `google_mlkit_text_recognition` is MIT-licensed, the underlying Google ML Kit SDK is a free, closed-source binary governed by the ML Kit Terms of Service.
   - Pure FOSS engines such as Tesseract (`Apache-2.0`) perform poorly on unconstrained scene text (tilted street signs, train tickets, café menus, mixed Chinese/Latin receipts) and add ~12–15 MB of uncompressed `chi_sim`/`chi_tra` traineddata weights.
   - Android (10–15) provides no built-in OS API equivalent to Apple's `Vision` framework for general offline scene-text OCR.

2. **Transitive Network Telemetry (`datatransport`)**:
   - `com.google.mlkit:text-recognition-chinese` transitively depends on `com.google.android.datatransport:transport-backend-cct`, whose library `AndroidManifest.xml` declares `android.permission.INTERNET` and `android.permission.ACCESS_NETWORK_STATE` to upload SDK usage telemetry.
   - Allowing those permissions into the merged release manifest would violate MemoDiary's zero-network quarantine invariant and fail `test/hardening/network_quarantine_audit_test.dart`.

3. **iOS Deployment Target Pinning (`15.0` vs `15.5`)**:
   - `google_mlkit_text_recognition` (`0.17.x`) bumps the minimum iOS deployment target to **iOS 15.5** and embeds a redundant third-party closed binary on iOS, whereas MemoDiary is pinned to **iOS 15.0+** and iOS already ships Apple's first-party `Vision` framework (`VNRecognizeTextRequest`) with accurate offline Simplified Chinese, Traditional Chinese, and English recognition built into the OS.

## Decision
We adopt a **thin, first-party native `MethodChannel('memodiary/ocr')` dual-engine architecture** behind the Dart `OcrService` vision seam, with zero `google_mlkit_*` pub dependencies:

1. **Unified Vision Seam & Pure-Dart Normalization**:
   - Define an abstract `OcrService` interface (`recognizeText(String absolutePath)` and `dispose()`) with `PlatformOcrService`, `StubOcrService` (headless desktop/CI fallback), and `FakeOcrService` (shared test double).
   - Native handlers perform image decoding and text recognition on background worker queues/executors and return raw top-left pixel line boxes (`{imageWidth, imageHeight, lines: [{text, left, top, width, height}]}`).
   - All coordinate clamping (`0.0..1.0`), 4-decimal-place rounding, degenerate/zero-area box filtering, and C0/C1 control-character sanitization execute in pure Dart (`OcrResultNormalizer`) so geometry and sanitization invariants are 100% unit-tested on Linux CI.

2. **iOS Engine — Built-In Apple Vision (`iOS 15.0+`)**:
   - Implement `ios/Runner/OcrChannelHandler.swift` using `VNRecognizeTextRequest` (`.accurate`, `usesLanguageCorrection = true`, `recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]`).
   - Preserves the **iOS 15.0** deployment target, adds **0 KB** to the iOS app bundle, and uses 100% built-in OS APIs.
   - Converts Vision's bottom-left normalized `boundingBox` coordinates (`[0, 1]`, origin bottom-left) into top-left pixel coordinates accounting for EXIF `CGImagePropertyOrientation`.

3. **Android Engine — Narrow Scoped Exception for Bundled ML Kit Chinese v2**:
   - Record a narrow, explicit exception in `GEMINI.md § 1 / § 2` permitting **only** the free, bundled on-device `com.google.mlkit:text-recognition-chinese:16.0.1` library in `android/app/build.gradle.kts` (which recognizes both Chinese and Latin scripts offline without Google Play Services model downloads).
   - Implement `OcrChannelHandler.kt` directly in Kotlin, decoding images off the UI thread and closing `TextRecognizer` cleanly in `MainActivity.cleanUpFlutterEngine`.

4. **OS-Level Manifest Network Quarantine (`tools:node="remove"`)**:
   - Explicitly strip transitive network permissions in `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <uses-permission android:name="android.permission.INTERNET" tools:node="remove" />
     <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" tools:node="remove" />
     ```
   - Rather than brittle bytecode stripping of internal `datatransport` classes (which risks `NoClassDefFoundError` at runtime), stripping permissions via the Android Manifest Merger guarantees at the OS kernel level that the packaged APK holds **zero** network socket permissions; any internal SDK telemetry attempt fails harmlessly offline.
   - Update `network_quarantine_audit_test.dart` to permit **only** `tools:node="remove"` directives in source `AndroidManifest.xml` while continuing to enforce strict zero `android.permission.INTERNET` presence in merged release manifests.

## Consequences
- **Guaranteed Offline Privacy**: Merged release APKs and iOS bundles retain zero network permissions; user photographs and recognized text cannot leave the device under any circumstance.
- **High-Accuracy Bilingual Recognition at $0 Cost**: Both Simplified/Traditional Chinese and Latin scene text (tickets, signs, menus, book pages) are recognized offline with zero cloud API fees.
- **Preserved Platform Compatibility & Lean iOS Binary**: iOS stays at minimum deployment target 15.0 with zero third-party OCR binary bloat; Linux/macOS/Windows test suites run deterministically in milliseconds via `StubOcrService` and `FakeOcrService`.
- **Verification Trade-off**: Because iOS `Vision` runs natively in Swift, iOS coordinate projection requires manual verification on macOS/iOS hardware or simulator, while all normalization math and Android manifest quarantine rules are continuously verified on Linux CI.
