#!/bin/bash
# census.sh — canonical Bedrock gate census.
#
# Runs the full scheme (unit + UI) with parallel testing disabled, because this
# app still has process-global singletons. Writes an .xcresult and prints the
# canonical summary. Pass --unit-only for the isolation/benchmark gates.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ONLY=()
if [[ "${1:-}" == "--unit-only" ]]; then
  ONLY=(-only-testing:"AsterismaV1.0Tests")
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="${TMPDIR:-/tmp}/rt-census-$STAMP.xcresult"
LOG="${TMPDIR:-/tmp}/rt-census-$STAMP.log"

set +e
xcodebuild test \
  -project "AsterismaV1.0.xcodeproj" \
  -scheme "AsterismaV1.0" \
  -configuration Debug \
  -destination 'platform=macOS' \
  -parallel-testing-enabled NO \
  -resultBundlePath "$OUT" \
  ${ONLY[@]+"${ONLY[@]}"} 2>&1 | tee "$LOG" | tail -20
STATUS=${PIPESTATUS[0]}
set -e

echo "---- census log: $LOG"
if [[ -d "$OUT" ]]; then
  echo "---- xcresult: $OUT"
  xcrun xcresulttool get test-results summary --path "$OUT" 2>/dev/null || true
fi

exit "$STATUS"
