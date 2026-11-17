#!/bin/bash
# Renders all seven app icons from the real kit views (KitGround + KitOrb)
# on an iOS simulator and copies them into each app's icon set.
#
#   scripts/render-app-icons.sh <simulator UDID> [Developer dir]
#
# The Developer dir (default: the folder above this repo) holds the app
# repos side by side. See Tests/MicroKitTests/AppIconRenderTests.swift.
set -euo pipefail
SIM="${1:?usage: render-app-icons.sh <simulator UDID> [Developer dir]}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DEV="${2:-$(cd "$HERE/.." && pwd)}"
OUT="$(mktemp -d)"

cd "$HERE"
TEST_RUNNER_ICON_OUT="$OUT" xcodebuild test -scheme MicroKit \
  -destination "platform=iOS Simulator,id=$SIM" \
  -only-testing:MicroKitTests/AppIconRenderTests 2>&1 \
  | grep -E "error:|Executed|TEST (SUCCEEDED|FAILED)" || true

place() {  # place <name> <path inside the Developer dir>
  [ -s "$OUT/$1.png" ] || { echo "missing render: $1" >&2; exit 1; }
}
copy() { cp "$OUT/$1.png" "$DEV/$2"; echo "wrote $2"; }
PAIRS="catch:catch-the-thought/CatchTheThought/Assets.xcassets/AppIcon.appiconset/AppIcon.png
hold:hold/Hold/Assets.xcassets/AppIcon.appiconset/AppIcon.png
ramp:ramp/Ramp/Assets.xcassets/AppIcon.appiconset/AppIcon.png
actual:actual/Actual/Assets.xcassets/AppIcon.appiconset/AppIcon.png
runway:runway/Runway/Assets.xcassets/AppIcon.appiconset/AppIcon.png
sweep:sweep/Sweep/Assets.xcassets/AppIcon.appiconset/AppIcon.png
faces:meeting-place/CatchAFace/Assets.xcassets/AppIcon.appiconset/Icon-1024.png"
# All seven must exist before any icon set is touched.
for p in $PAIRS; do place "${p%%:*}" "${p#*:}"; done
for p in $PAIRS; do copy "${p%%:*}" "${p#*:}"; done
echo "renders kept in $OUT"
