# MemoDiary: Claude Code Instructions

Project rules are shared with Antigravity. `GEMINI.md` is the source of truth; do not duplicate its content here.

@GEMINI.md

- Read `CODING_STANDARDS.md` during `/code-review` and before UI/service refactors.
- Read `GLOSSARY.md` before exploring or naming domain concepts.

## Claude Code overrides

The imports above contain some Antigravity-specific instructions. For Claude Code:

- **Sandbox flags**: Ignore `BypassSandbox: true/false`. Claude Code uses its own permission prompts.
- **Scratch files**: Ignore `<appDataDir>/brain/<id>/scratch/`. Use the session scratchpad directory.
- **Skills**: Skills live in `.agents/skills/` (shared with Antigravity) and are symlinked into `.claude/skills/`. Never rename or edit them in place; they are tracked in `skills-lock.json` for upstream updates. When a new skill is added under `.agents/skills/`, add a matching symlink in `.claude/skills/`.
- **`code-review`**: Means the project skill (`.agents/skills/code-review`, Standards + Spec review), not the built-in `/code-review`.
- **`implement-spec`**: Implementer briefs carry Displacement over Coexistence (`CODING_STANDARDS.md` § 3). Worktrees land in `.claude/worktrees/agent-*` on flat hyphenated branches (`spec-NNN-XX-<slug>`, never slashes under an existing `spec-NNN` branch); when based on `main`, the brief's first step is `git reset --hard <integration branch>` (the pre-commit hook rejects a commit still based on `main`); clean up with `git worktree remove` on each, then `git branch -d` (merged branches only).

## Agent skills

### Issue tracker

Local markdown: specs in `docs/specs/NNNN-<slug>.md` (committed), tickets in `.scratch/<slug>/issues/` (gitignored). See `docs/agents/issue-tracker.md`.

### Triage labels

Default five roles, recorded as `Status:` lines, plus `claimed` / `completed`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: root `GLOSSARY.md` + `docs/adr/`. See `docs/agents/domain.md`.
