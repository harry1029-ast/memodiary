# MemoDiary: Claude Code Instructions

Project rules are shared with Antigravity. `GEMINI.md` is the source of truth; do not duplicate its content here.

@GEMINI.md
@CODING_STANDARDS.md
@GLOSSARY.md

## Claude Code overrides

The imports above contain some Antigravity-specific instructions. For Claude Code:

- **Sandbox flags**: Ignore `BypassSandbox: true/false`. Claude Code uses its own permission prompts.
- **Scratch files**: Ignore `<appDataDir>/brain/<id>/scratch/`. Use the session scratchpad directory.
- **Flutter/Dart**: If `flutter` is not on `$PATH`, use `/home/harry1029/development/flutter/bin/flutter` (and `.../dart`).
- **Skills**: Skills live in `.agents/skills/` (shared with Antigravity) and are symlinked into `.claude/skills/`. Never rename or edit them in place; they are tracked in `skills-lock.json` for upstream updates. When a new skill is added under `.agents/skills/`, add a matching symlink in `.claude/skills/`.
- **`code-review`**: Means the project skill (`.agents/skills/code-review`, Standards + Spec review), not the built-in `/code-review`.
