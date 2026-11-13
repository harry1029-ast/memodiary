#!/bin/bash
# Offline-first Flutter analyzer and test runner for isolated git worktrees.
# Usage: tool/worktree-verify.sh <worktree-path> [test-paths...]
# Bootstraps `.dart_tool/package_config.json` offline when missing so fresh
# worktrees do not hit network `pub get` or report path-mismatch errors.

set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: tool/worktree-verify.sh <worktree-path> [test-paths...]" >&2
  exit 2
fi

WORKTREE_DIR="$1"
shift

if [ ! -d "$WORKTREE_DIR" ] || [ ! -f "$WORKTREE_DIR/pubspec.yaml" ]; then
  echo "Invalid Flutter worktree: $WORKTREE_DIR" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="flutter"
else
  FLUTTER_BIN="/home/harry1029/development/flutter/bin/flutter"
fi

cd "$WORKTREE_DIR"

if [ ! -f ".dart_tool/package_config.json" ]; then
  "$FLUTTER_BIN" pub get --offline >/dev/null
fi

"$FLUTTER_BIN" analyze --no-pub

if [ "$#" -gt 0 ]; then
  "$REPO_ROOT/tool/test.sh" "$@"
fi
