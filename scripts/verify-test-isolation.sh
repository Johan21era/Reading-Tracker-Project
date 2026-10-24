#!/bin/bash
# verify-test-isolation.sh — prove a unit census does not mutate real user data.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$HOME/Library/Containers/johan.Reading-Tracker/Data/Library/Application Support/Asterisma"
BEFORE="$(mktemp "${TMPDIR:-/tmp}/rt-isolation-before.XXXXXX")"
AFTER="$(mktemp "${TMPDIR:-/tmp}/rt-isolation-after.XXXXXX")"

hash_tree() {
  find "$SRC" -type f ! -name ".DS_Store" -print0 \
    | sort -z \
    | xargs -0 shasum -a 256 \
    | sed "s|$SRC|READTRACKER|g"
}

hash_tree > "$BEFORE"
"$ROOT/scripts/census.sh" --unit-only >/dev/null
hash_tree > "$AFTER"

if diff -u "$BEFORE" "$AFTER"; then
  echo "TEST ISOLATION OK — real app-support data is byte-identical."
  rm -f "$BEFORE" "$AFTER"
else
  echo "TEST ISOLATION FAILED — a test wrote to real app-support data." >&2
  echo "before=$BEFORE after=$AFTER" >&2
  exit 1
fi
