#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -z "${GODOT_BIN:-}" ]]; then
  if command -v godot >/dev/null 2>&1; then
    GODOT_BIN="godot"
  elif command -v godot4 >/dev/null 2>&1; then
    GODOT_BIN="godot4"
  elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
    GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
  else
    echo "ERROR: Godot binary not found. Set GODOT_BIN=/path/to/Godot." >&2
    exit 1
  fi
fi

echo "== CS 5v5 release preflight =="
echo "Godot: $GODOT_BIN"
rm -f .test_status
"$GODOT_BIN" --headless --quit-after 1 --path "$ROOT_DIR" -s tests/test_runner.gd
if [[ ! -f .test_status ]]; then
  echo "ERROR: Test runner did not write .test_status" >&2
  exit 1
fi
TEST_STATUS="$(cat .test_status)"
rm -f .test_status
if [[ "$TEST_STATUS" != "0" ]]; then
  echo "ERROR: Godot tests failed with $TEST_STATUS failure(s)." >&2
  exit 1
fi

grep -q 'name="Android Release"' export_presets.cfg
grep -q 'export_path="build/android/CS5v5.aab"' export_presets.cfg
grep -q 'package/show_as_launcher_app=true' export_presets.cfg
grep -q 'user_data_backup/allow=false' export_presets.cfg

test -f RELEASE_CHECKLIST.md
test -f docs/privacy-policy.md
test -f docs/store-listing.md
test -f docs/monetization-plan.md

echo "Preflight passed. You can proceed to manual QA and release export."
