#!/bin/bash
# Token-lean Flutter test runner for agents.
# Usage: tool/test.sh [test paths...]   (no paths = full suite)
# Prints one summary line on success; on failure, each failing test's name
# plus its Expected/Actual/exception lines. Exit code matches `flutter test`.

if command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="flutter"
else
  FLUTTER_BIN="/home/harry1029/development/flutter/bin/flutter"
fi

EXTRA_FLAGS=()
if [ -f ".dart_tool/package_config.json" ]; then
  EXTRA_FLAGS+=(--no-pub)
fi

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

"$FLUTTER_BIN" test "${EXTRA_FLAGS[@]}" --reporter=expanded "$@" >"$LOG" 2>&1
STATUS=$?

tr '\r' '\n' <"$LOG" | grep -E "All tests passed|Some tests failed|No tests ran" | tail -n 1
if [ "$STATUS" -ne 0 ]; then
  tr '\r' '\n' <"$LOG" \
    | grep -E "\[E\]$|^\s+(Expected|Actual|Which):|Exception:|Error:|^test/.*:[0-9]+:[0-9]+" \
    | grep -v "^\s*$" | head -n 60
fi
exit "$STATUS"
