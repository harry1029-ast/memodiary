#!/bin/bash
# Regenerates every launcher icon from the diarist's painting (SPEC-023
# Implementation Decision 6). Run from the repo root.
# Usage: tool/app_icon/generate_app_icons.sh

set -euo pipefail

if command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="flutter"
  DART_BIN="dart"
else
  FLUTTER_BIN="/home/harry1029/development/flutter/bin/flutter"
  DART_BIN="/home/harry1029/development/flutter/bin/dart"
fi

"$FLUTTER_BIN" test tool/app_icon/build_icon_master.dart
"$FLUTTER_BIN" test tool/app_icon/build_monochrome_icon.dart
# flutter_launcher_icons 0.14.4 rewrites the unrelated
# ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS setting in the
# Xcode project to "AppIcon"; the project already names AppIcon, so keep it.
PBXPROJ="ios/Runner.xcodeproj/project.pbxproj"
PBXPROJ_BACKUP="$(mktemp)"
trap 'rm -f "$PBXPROJ_BACKUP"' EXIT
cp "$PBXPROJ" "$PBXPROJ_BACKUP"
"$DART_BIN" run flutter_launcher_icons -f flutter_launcher_icons.yaml
cp "$PBXPROJ_BACKUP" "$PBXPROJ"
"$FLUTTER_BIN" test tool/app_icon/build_round_icons.dart
