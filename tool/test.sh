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

if [ -n "${MEMODIARY_TEST_WALL_TIMEOUT:-}" ]; then
  WALL_TIMEOUT="$MEMODIARY_TEST_WALL_TIMEOUT"
elif [ "$#" -gt 0 ]; then
  WALL_TIMEOUT="120s"
else
  WALL_TIMEOUT="300s"
fi

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

if command -v timeout >/dev/null 2>&1; then
  timeout -k 5s "$WALL_TIMEOUT" "$FLUTTER_BIN" test "${EXTRA_FLAGS[@]}" --reporter=expanded "$@" >"$LOG" 2>&1
else
  "$FLUTTER_BIN" test "${EXTRA_FLAGS[@]}" --reporter=expanded "$@" >"$LOG" 2>&1
fi
STATUS=$?

tr '\r' '\n' <"$LOG" | grep -E "All tests passed|Some tests failed|No tests ran" | tail -n 1 || true
if [ "$STATUS" -eq 124 ]; then
  echo "[tool/test.sh] Timed out after $WALL_TIMEOUT — last test activity:"
  tr '\r' '\n' <"$LOG" | grep -v "^\s*$" | tail -n 20
elif [ "$STATUS" -ne 0 ]; then
  MATCHES="$(tr '\r' '\n' <"$LOG" \
    | grep -E "\[E\]$|^\s+(Expected|Actual|Which):|Exception:|Error:|^test/.*:[0-9]+:[0-9]+" \
    | grep -v "^\s*$" | head -n 60 || true)"
  if [ -n "$MATCHES" ]; then
    printf '%s\n' "$MATCHES"
  else
    tr '\r' '\n' <"$LOG" | grep -v "^\s*$" | tail -n 20
  fi
fi
exit "$STATUS"
