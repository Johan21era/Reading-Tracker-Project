#!/usr/bin/env python3
"""Clean-machine spawn smoke (PR-8 / ADR-3 rehearsal discipline).

Boots the sidecar FROM the staged bundle with the bundle's OWN interpreter,
exchanges version + books_list on the pinned NDJSON wire, and tears the child
down cleanly (SIGTERM → escalate SIGKILL). Disposable ledger only — the real
ledger is never touched. Usage: bundle_smoke.py <mirage-runtime-root>."""

from __future__ import annotations

import json
import os
import shutil
import signal
import subprocess
import sys
import tempfile

def fail(message: str) -> int:
    print(json.dumps({"ok": False, "error": {"code": "BUNDLE-SMOKE", "message": message}}))
    return 1

def main() -> int:
    if len(sys.argv) != 2:
        return fail("usage: bundle_smoke.py <mirage-runtime-root>")
    stage = os.path.abspath(sys.argv[1])
    python = os.path.join(stage, "bin", "python3.12")
    sidecar = os.path.join(stage, "examples", "mirage_sidecar.py")
    for required in (python, sidecar):
        if not os.path.exists(required):
            return fail(f"missing staged piece: {required}")

    work = tempfile.mkdtemp(prefix="bundle-smoke-")
    proc = None
    try:
        env = dict(os.environ)
        env["PYTHONDONTWRITEBYTECODE"] = "1"
        proc = subprocess.Popen(
            [python, "-B", sidecar, os.path.join(work, "smoke.sqlite3")],
            cwd=stage, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, text=True, bufsize=1, env=env)
        banner = proc.stdout.readline().strip()
        if not banner:
            stderr = proc.stderr.read()
            return fail(f"no banner from the staged sidecar; stderr: {stderr[:400]}")
        check = json.loads(banner)
        if check.get("status") != "ready":
            return fail(f"banner not ready: {banner[:200]}")

        def send(action: str) -> str:
            line = json.dumps({"action": action, "payload": {}, "id": "smoke-1"},
                              separators=(",", ":"))
            proc.stdin.write(line + "\n")
            proc.stdin.flush()
            return proc.stdout.readline().strip()

        version = json.loads(send("version"))
        books = json.loads(send("books_list"))
        if not version.get("ok") or not books.get("ok"):
            return fail(f"probe exchange refused: {version} / {books}")
        print("BANNER:", banner)
        print("VERSION:", json.dumps(version, sort_keys=True))
        print("BOOKS:", json.dumps(books, sort_keys=True))
        proc.send_signal(signal.SIGTERM)
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.send_signal(signal.SIGKILL)
            proc.wait(timeout=5)
        graceful = proc.returncode == 0 or proc.returncode == -15
        if not graceful:
            return fail(f"unclean teardown, exit {proc.returncode}")
        print("BUNDLE SMOKE OK")
        return 0
    finally:
        if proc is not None and proc.poll() is None:
            proc.send_signal(signal.SIGKILL)
        shutil.rmtree(work, ignore_errors=True)

if __name__ == "__main__":
    raise SystemExit(main())
