#!/bin/bash
# verify-sentinel-surface.sh — fail when the generated Sentinel surface
# manifest no longer matches the app sources.
#
# This is the "caught up by tomorrow" guarantee at the inventory layer: a new
# table, defaults key, or notification cannot land silently. Either the author
# regenerates the manifest (and SQL-016/SELF-011 immediately see the surface),
# or CI fails here with the exact command to run.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

python3 scripts/sentinel-surface.py --check --report
