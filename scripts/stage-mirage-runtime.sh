#!/bin/bash
# stage-mirage-runtime.sh — ADR-3 / PR-8: materialize the bundled Mirage runtime.
#
# Lays out RT.app's Resources/mirage-runtime/ bundle:
#   bin/python3              — pinned python-build-standalone CPython (relocatable)
#   lib/python3.12/...       — its standard library (stripped to what the engine needs)
#   mirage/                  — the engine package, copied VERBATIM from the pinned SHA
#   examples/mirage_sidecar.py
#   RUNTIME-MANIFEST.json    — engine version, interpreter version, content SHA-256s
#
# Discipline (ADR-3): every acquisition is pinned (release tag + recorded sha256);
# the engine tree is copied from the pinned engine checkout — never mutated;
# re-staging verifies checksums before replacing anything. The staged bundle is
# THE runtime: RT's locator reads it from Resources (or the dev gate in
# development); nothing at runtime mutates bundle contents except whole
# directory replacement on upgrade.
set -euo pipefail

MIRAGE_HOME="${MIRAGE_HOME:-/Users/johanrembeci/Desktop/MirageV1.0}"
STAGE_ROOT="${1:?usage: stage-mirage-runtime.sh <stage-root>}"

# ---- pinned inputs (recorded at adoption; the script halts on drift) --------
ENGINE_SHA="$(cd "$MIRAGE_HOME" && git rev-parse HEAD)"
case "$ENGINE_SHA" in
  81422613*) ;;  # the pinned contract SHA family (§1 confidence rules)
  *) echo "REFUSAL: engine checkout SHA $ENGINE_SHA is not the pinned generation" >&2; exit 2 ;;
esac

# python-build-standalone pinned release (aarch64-apple-darwin install_only).
# adopt-sha256 5a9cdbb8536839a83edae3e41eb44161b640d78181fec083e07c668ba796a875 (2026-10-18)
PYBS_LABEL="cpython-3.12.7+20241002-aarch64-apple-darwin"
PYBS_URL="https://github.com/astral-sh/python-build-standalone/releases/download/20241002/${PYBS_LABEL}-install_only.tar.gz"
PYBS_SHA256_EXPECT="${PYBS_SHA256_EXPECT:-5a9cdbb8536839a83edae3e41eb44161b640d78181fec083e07c668ba796a875}"
if [[ -z "$PYBS_SHA256_EXPECT" ]]; then
  echo "pin: PYBS_SHA256_EXPECT unset — computing from tonight's fetch and printing it" >&2
fi

TMP="$(mktemp -d /tmp/mirage-stage-XXXXXXXX)"
trap 'rm -rf "$TMP"' EXIT
echo "[1/5] fetching pinned interpreter…"
curl -sSL --retry 2 -o "$TMP/pybs.tar.gz" "$PYBS_URL"
PYBS_SHA256_ACTUAL="$(shasum -a 256 "$TMP/pybs.tar.gz" | awk '{print $1}')"
echo "      sha256=$PYBS_SHA256_ACTUAL"
if [[ -n "$PYBS_SHA256_EXPECT" && "$PYBS_SHA256_ACTUAL" != "$PYBS_SHA256_EXPECT" ]]; then
  echo "REFUSAL: interpreter checksum mismatch (expected $PYBS_SHA256_EXPECT, got $PYBS_SHA256_ACTUAL)" >&2
  exit 3
fi

echo "[2/5] unpacking runtime…"
mkdir -p "$TMP/runtime" && tar -xzf "$TMP/pybs.tar.gz" -C "$TMP/runtime"
SRC_PY="$TMP/runtime/python"            # install_only layout: ./python
"$SRC_PY/bin/python3" -c "import sys; print('interpreter', sys.version.split()[0])"

echo "[3/5] laying out bundle at $STAGE_ROOT …"
BUNDLE="$STAGE_ROOT/mirage-runtime"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE"
# The ENTIRE prefix is the relocatable unit: CPython resolves its stdlib via
# binary-relative discovery, so bin/+lib/+share/+Resources/ must stay intact.
cp -R "$SRC_PY"/. "$BUNDLE/"
# Strip the interpreter's test/ensurepip/idle heavy dirs (engine is stdlib-only).
rm -rf "$BUNDLE/lib/python3.12/test" "$BUNDLE/lib/python3.12/idlelib" \
       "$BUNDLE/lib/python3.12/turtledemo" "$BUNDLE/lib/python3.12/ensurepip"
RT_PY="$BUNDLE/bin/python3.12"   # the real binary (python3 is a symlink to it)

echo "[4/5] copying the engine verbatim (pinned SHA $ENGINE_SHA)…"
# The sidecar bootstraps sys.path at <bundle-of-file>/../src — so the bundle
# reproduces the engine's OWN src layout, and the sidecar file copied verbatim
# needs no mutation (mirage-sidecar.py:22-23 is the pinned bootstrap).
mkdir -p "$BUNDLE/src" "$BUNDLE/examples"
cp -R "$MIRAGE_HOME/src/miragev10" "$BUNDLE/src/miragev10"
cp "$MIRAGE_HOME/examples/mirage_sidecar.py" "$BUNDLE/examples/mirage_sidecar.py"

echo "[5/5] manifest + checksums…"
PY3_SHA="$(shasum -a 256 "$RT_PY" | awk '{print $1}')"
SIDECAR_SHA="$(shasum -a 256 "$BUNDLE/examples/mirage_sidecar.py" | awk '{print $1}')"
ENGINE_DIR_SHA="$(cd "$BUNDLE/src/miragev10" && find . -name '*.py' | sort | xargs shasum -a 256 | shasum -a 256 | awk '{print $1}')"
cat > "$BUNDLE/RUNTIME-MANIFEST.json" << EOF
{
  "engine_version": "MirageV1.0-$ENGINE_SHA",
  "engine_checkout_sha": "$ENGINE_SHA",
  "interpreter": "$PYBS_LABEL",
  "interpreter_sha256": "$PYBS_SHA256_ACTUAL",
  "bindings": {
    "bin/python3.12": "$PY3_SHA",
    "examples/mirage_sidecar.py": "$SIDECAR_SHA",
    "src/miragev10 (tree digest)": "$ENGINE_DIR_SHA"
  }
}
EOF
cat "$BUNDLE/RUNTIME-MANIFEST.json"

echo "STAGED OK: $BUNDLE"
