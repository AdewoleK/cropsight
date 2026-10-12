#!/usr/bin/env bash
# Regenerates the screenshot set in cropsight-redesign-screens/ by driving
# the real app on an iOS simulator (integration_test/screenshots_test.dart).
#
#   tool/capture_screenshots.sh <simulator-udid>
#
# The simulator must already have the bundled models installed (run the app
# on it once). One real photo diagnosis runs on the Mac's CPU, which takes a
# few minutes.
set -euo pipefail

UDID="${1:?usage: tool/capture_screenshots.sh <simulator-udid>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/cropsight-redesign-screens"
PHOTOS="$ROOT/tool/screenshot_photos"
LOG="$(mktemp -t cropsight-shots).log"

mkdir -p "$OUT"
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged \
  --batteryLevel 100 --wifiBars 3 --cellularMode active --cellularBars 4
trap 'xcrun simctl status_bar "$UDID" clear' EXIT

(cd "$ROOT" && flutter test integration_test/screenshots_test.dart -d "$UDID" \
  --dart-define=PHOTOS_DIR="$PHOTOS" >"$LOG" 2>&1) &
TEST_PID=$!

taken=0
while kill -0 "$TEST_PID" 2>/dev/null; do
  while IFS= read -r name; do
    taken=$((taken + 1))
    [[ "$name" == "DONE" ]] && continue
    xcrun simctl io "$UDID" screenshot "$OUT/$name.png" >/dev/null 2>&1
    echo "captured $name"
  done < <(grep -o 'SNAP:[A-Za-z0-9-]*' "$LOG" | sed 's/^SNAP://' | tail -n +$((taken + 1)))
  sleep 0.3
done

wait "$TEST_PID" && status=0 || status=$?
grep -E 'DIAGNOSIS|DESCRIPTION|ANSWER|LITE |ERROR' -A12 "$LOG" | head -60 || true
echo "log: $LOG"
exit "$status"
