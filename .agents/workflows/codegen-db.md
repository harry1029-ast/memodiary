---
description: Run Drift SQLite code generation and schema validation
---
1. Run `dart run build_runner build --delete-conflicting-outputs` in the terminal.
2. Verify there are no analyzer errors in `lib/core/database/` using `flutter analyze`.
3. Run `flutter test test/database/` to confirm schema integrity.