---
description: Audit codebase for zero outbound network calls and $0 dependency compliance
---
1. Search the codebase and `pubspec.yaml` for any HTTP client calls, analytics SDKs, or paid cloud APIs.
2. Verify all `media_attachments` paths are stored as relative sandbox paths and never raw OS gallery paths[cite: 1, 5].
3. Output a concise compliance checklist confirming 100% offline execution[cite: 5].