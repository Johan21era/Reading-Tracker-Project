#!/bin/bash
# package-release.sh — ad-hoc local distribution build.
#
# Produces dist/AsterismaV1.0-<version>-arm64.zip with a signed .app inside.
# This is NOT notarized: first launch requires right-click Open (or one xattr
# command). See docs/plans/bedrock/DISTRIBUTION.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DIST="$ROOT/dist"
mkdir -p "$DIST"

xcodebuild build \
  -project "AsterismaV1.0.xcodeproj" \
  -scheme "AsterismaV1.0" \
  -configuration Release \
  -destination 'platform=macOS' 2>&1 | tail -8

SETTINGS="$(xcodebuild -showBuildSettings \
  -project "AsterismaV1.0.xcodeproj" \
  -scheme "AsterismaV1.0" \
  -configuration Release 2>/dev/null)"
TARGET_DIR="$(printf '%s\n' "$SETTINGS" | awk -F' = ' '/ TARGET_BUILD_DIR = /{print $2; exit}')"
WRAPPER="$(printf '%s\n' "$SETTINGS" | awk -F' = ' '/ WRAPPER_NAME = /{print $2; exit}')"
APP="$TARGET_DIR/$WRAPPER"
[[ -d "$APP" ]] || { echo "app not found: $APP" >&2; exit 1; }

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
# BUG-003: signing inside a Desktop/iCloud-synced tree gets a FileProvider
# xattr stamp that codesign refuses. Stage and sign in the system temp dir;
# only the finished zip comes back to dist/.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/rt-release.XXXXXX")"
STAGE="$WORK/AsterismaV1.0-$VERSION-arm64"
mkdir -p "$STAGE"
ditto "$APP" "$STAGE/AsterismaV1.0.app"
xattr -cr "$STAGE/AsterismaV1.0.app" 2>/dev/null || true

# Sign the embedded interpreter/dylibs first, then the app. Ad-hoc only.
RUNTIME="$STAGE/AsterismaV1.0.app/Contents/Resources/mirage-runtime"
if [[ -d "$RUNTIME" ]]; then
  # Smoke a COPY: running Python inside the signed bundle writes __pycache__
  # and breaks the seal. Bytecode writes are also disabled inside the smoke.
  SMOKE="$WORK/smoke-runtime"
  ditto "$RUNTIME" "$SMOKE"
  echo "---- embedded Mirage smoke (copy)"
  python3 "$ROOT/scripts/bundle_smoke.py" "$SMOKE"
  while IFS= read -r -d '' nested; do
    codesign --force --sign - --timestamp=none "$nested" >/dev/null 2>&1 || true
  done < <(find "$RUNTIME" -type f \( -name "*.so" -o -name "*.dylib" -o -perm -111 \) -print0)
fi

# Ad-hoc sign the whole bundle. No Developer ID, no notarization.
codesign --force --deep --sign - --timestamp=none "$STAGE/AsterismaV1.0.app"
codesign --verify --deep --strict --verbose=2 "$STAGE/AsterismaV1.0.app"



ZIP="$DIST/AsterismaV1.0-$VERSION-arm64.zip"
rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent --norsrc --noextattr \
  "$STAGE/AsterismaV1.0.app" "$ZIP"
shasum -a 256 "$ZIP" > "$ZIP.sha256"

echo "---- package: $ZIP"
cat "$ZIP.sha256"
echo "---- Gatekeeper verdict (expected: rejected until right-click Open):"
spctl -a -vv "$STAGE/AsterismaV1.0.app" 2>&1 || true
