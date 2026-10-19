#!/usr/bin/env python3
"""TB-M0 observe-mode instrument (ADR-12 countersigned 2026-10-18; §22.19.1).

Verifies a Mirage generation's staged root against the REPO's canonical subset
manifest (docs/integration/tib/subset-manifest.gen-0001.json) and appends an
append-only row to observe-ledger.md. Observe only: no swap, no quarantine of
live material — tamper drills run on a sacrificial COPY.

Usage:
  scripts/tib/observe.py verify  <bundle-root>
  scripts/tib/observe.py tamper-drill <bundle-root>   # sacrificial, proves the red side

Exit codes: 0 verified-green • 20 drift/refusal • 21 missing piece • 22 drill FAILED
(an instrument that passes a tampered copy)."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CANONICAL = os.path.join(REPO, "docs", "integration", "tib", "subset-manifest.gen-0001.json")
LEDGER = os.path.join(REPO, "docs", "integration", "tib", "observe-ledger.md")

DRIFT, MISSING, DRILL_FAILED = 20, 21, 22
REQUIRED = ("bin/python3.12", "examples/mirage_sidecar.py", "src/miragev10", "RUNTIME-MANIFEST.json")
TREE_KEY = "src/miragev10 (tree digest)"
BIN_KEY = "bin/python3.12"
SIDE_KEY = "examples/mirage_sidecar.py"


def sha256(path: str) -> str:
    return subprocess.run(["shasum", "-a", "256", path], check=True, capture_output=True,
                          text=True).stdout.split()[0]


def tree_digest(src_dir: str) -> str:
    # The staging script's exact pipeline, reproduced as a subprocess so the
    # multi-file xargs-split behavior is identical by construction.
    cmd = (f'cd "{src_dir}" && find . -name "*.py" | sort | xargs shasum -a 256 '
           f'| shasum -a 256')
    return subprocess.run(["/bin/sh", "-c", cmd], check=True, capture_output=True,
                          text=True).stdout.split()[0]


def load_manifest(path: str) -> dict:
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def compute(bundle: str) -> dict[str, str]:
    return {
        BIN_KEY: sha256(os.path.join(bundle, BIN_KEY)),
        SIDE_KEY: sha256(os.path.join(bundle, SIDE_KEY)),
        TREE_KEY: tree_digest(os.path.join(bundle, "src/miragev10")),
    }


def check(bundle: str, live_manifest: dict) -> tuple[bool, list[str]]:
    notes: list[str] = []
    canonical = load_manifest(CANONICAL)
    if live_manifest != canonical:
        notes.append("LIVE MANIFEST != CANONICAL — generation drift or unfamiliar generation")
        return False, notes
    actual = compute(bundle)
    ok = True
    for key, value in canonical["bindings"].items():
        if key not in actual:
            continue  # interpreter_sha256 binds the DOWNLOADED archive (staging-side truth)
        if actual[key] != value:
            notes.append(f"binding mismatch {key}: manifest {value} != live {actual[key]}")
            ok = False
        else:
            notes.append(f"binding verified {key}: {value}")
    return ok, notes


def append_row(mode: str, bundle: str, live: dict, ok: bool, notes: list[str], forced: bool) -> None:
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    gen = live.get("engine_checkout_sha", "unknown")[:16]
    result = "GREEN" if ok else ("DRILL-EXPECTED-RED" if forced else "RED")
    line = (f"| {stamp} | {mode} | `{gen}` | {', '.join(notes) if notes else '—'} "
            f"| {result} |\n")
    if not os.path.exists(LEDGER):
        with open(LEDGER, "a", encoding="utf-8") as fh:
            fh.write("# TB-M0 observation ledger (§22.19.1: 7 days; 0 false-green; append-only)\n\n"
                     "| ISO stamp | mode | generation | bindings | verdict |\n|---|---|---|---|---|\n")
            fh.write(line)
    else:
        with open(LEDGER, "a", encoding="utf-8") as fh:
            fh.write(line)


def main() -> int:
    if len(sys.argv) != 3 or sys.argv[1] not in ("verify", "tamper-drill"):
        print(__doc__)
        return 2
    mode, bundle = sys.argv[1], os.path.abspath(sys.argv[2])
    if any(not os.path.exists(os.path.join(bundle, p)) for p in REQUIRED):
        print(f"MISSING: staged piece absent in {bundle} (need {', '.join(REQUIRED)})")
        return MISSING
    if mode == "verify":
        live = load_manifest(os.path.join(bundle, "RUNTIME-MANIFEST.json"))
        ok, notes = check(bundle, live)
        append_row("verify", bundle, live, ok, notes, forced=False)
        print("OBSERVE GREEN" if ok else "OBSERVE RED — typed refusal (Drift; no swap)")
        for note in notes:
            print("  -", note)
        return 0 if ok else DRIFT
    # tamper-drill: sacrificial copy, flip one byte in the interpreter, verify must refuse
    sacrificial = tempfile.mkdtemp(prefix="tib-tamper-drill-")
    copy = os.path.join(sacrificial, "mirage-runtime-tampered")
    try:
        shutil.copytree(bundle, copy)
        py = os.path.join(copy, BIN_KEY)
        with open(py, "rb") as fh:
            data = bytearray(fh.read())
        data[0] = (data[0] + 1) % 256
        with open(py, "wb") as fh:
            fh.write(data)
        live = load_manifest(os.path.join(bundle, "RUNTIME-MANIFEST.json"))  # same manifest
        ok, notes = check(copy, live)
        if ok:
            append_row("tamper-drill", copy, live, False, ["INSTRUMENT SURVIVED TAMPER"], forced=True)
            print("DRILL FAILED — the instrument PASSED a tampered copy (false-green)")
            return DRILL_FAILED
        append_row("tamper-drill", copy, live, True, notes + ["tamper refused, quarantine n/a (observe)"], forced=True)
        shutil.rmtree(copy, ignore_errors=True)
        print("DRILL OK — tampered copy refused; the red side is real")
        for note in notes:
            print("  -", note)
        return 0
    finally:
        shutil.rmtree(sacrificial, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())
