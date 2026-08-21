#!/usr/bin/env bash
# CampusPulse verification gate — run this on a machine with the Flutter
# SDK installed. It was NOT run by the assistant that built this repo
# (no SDK in that sandbox — see TASKS.md section 0). Run it yourself
# before treating the app as verified.
#
# Usage: ./scripts/verify.sh
set -uo pipefail

pass=0
fail=0

step() {
  local name="$1"; shift
  echo ""
  echo "=== $name ==="
  if "$@"; then
    echo "--- PASS: $name ---"
    pass=$((pass + 1))
  else
    echo "--- FAIL: $name ---"
    fail=$((fail + 1))
  fi
}

if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: flutter is not on PATH. Install the Flutter SDK first (flutter.dev)."
  exit 127
fi

flutter --version

step "flutter pub get" flutter pub get
step "dart format (check only)" dart format --output=none --set-exit-if-changed .
step "flutter analyze" flutter analyze
step "flutter test" flutter test
step "flutter build apk --debug" flutter build apk --debug
step "flutter build web" flutter build web

echo ""
echo "================================"
echo " Verification summary: $pass passed, $fail failed"
echo "================================"

if [ "$fail" -gt 0 ]; then
  exit 1
fi
