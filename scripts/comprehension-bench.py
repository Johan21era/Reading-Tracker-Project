#!/usr/bin/env python3
"""Cold-retrieval benchmark for this repository.

Every run is a fresh process with no memory of any prior session. It answers a
question bank twice:

  naive    grep the tree, rank candidates, read until the answer matches
  indexed  read docs/INDEX.md, follow the best-matching link, read that file

The point is not to score an LLM. It measures the work a competent, context-free
reader must do to reach a specific fact — search calls, files opened, bytes read,
and wall-clock time — which is exactly the cost that documentation structure can
remove. The indexed policy is only allowed to follow a link; it never contains
the answers itself (the bank is validated against the owning files, and the index
is never allowed to be the answer path).

Usage:
    python3 scripts/comprehension-bench.py --validate-only
    python3 scripts/comprehension-bench.py --mode facts --rep 3
    python3 scripts/comprehension-bench.py --mode all --json /tmp/bench.json

Exit status is 0 only when the calibrated gate passes.
"""

from __future__ import annotations

import argparse
import json
import re
import statistics
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BANK_PATH = ROOT / "scripts" / "comprehension-questions.json"
INDEX_PATH = ROOT / "docs" / "INDEX.md"

STOPWORDS = {
    "which", "what", "whats", "where", "when", "who", "why", "how", "many", "much",
    "the", "a", "an", "is", "are", "was", "were", "does", "do", "did", "be", "been",
    "of", "in", "on", "for", "to", "and", "or", "with", "by", "at", "as", "from",
    "into", "this", "that", "these", "those", "it", "its", "app", "project",
    "file", "files", "name", "names", "used", "use", "uses", "using", "current",
    "currently", "now", "version", "please", "find", "tell", "me", "you", "your",
    "about", "entire", "whole", "codebase", "code", "exists", "implemented",
    "implements", "called", "type", "types", "value", "values", "there", "their",
    "has", "have", "can", "could", "would", "should", "main", "local",
}

TEXT_SUFFIXES = {
    ".swift", ".md", ".yml", ".yaml", ".plist", ".sh", ".py", ".json", ".html",
    ".entitlements", ".pbxproj", ".xcconfig", ".txt", ".m", ".h",
}

EXCLUDE_GLOBS = [
    "!graphify-out/**",
    "!.mirage-runtime/**",
    "!.git/**",
    "!scripts/vendor/**",
    "!**/__pycache__/**",
]

MAX_FILE_BYTES = 150_000
NAIVE_MAX_READS = 6
REF_PATTERN = re.compile(
    r"`([^`#]+?\.(?:md|swift|py|sh|yml|yaml|json|plist|html|pbxproj|entitlements))"
    r"(?:#L(\d+)(?:-L(\d+))?)?`"
)
INDEX_MAX_LINES = 4
MAX_TERM_RESULTS = 400

# Calibrated gate — every number is a floor this repository must clear.
GATE = {
    "facts_accuracy": 1.0,
    "indexed_median_ms": 25.0,
    "indexed_median_files": 2.0,
    "facts_speedup": 4.0,
    "facts_byte_ratio": 0.5,
    "overview_coverage": 1.0,
    "overview_speedup": 5.0,
    "overview_byte_ratio": 0.2,
    "facts_no_fallback": 0,
}


def load_bank() -> dict:
    return json.loads(BANK_PATH.read_text(encoding="utf-8"))


def terms(question: str, limit: int = 5) -> list[str]:
    words = re.findall(r"[A-Za-z0-9][A-Za-z0-9\-]+", question.lower())
    picked: list[str] = []
    seen: set[str] = set()
    for word in words:
        word = word.strip("-")
        if len(word) < 3 and not word.isdigit():
            continue
        if word in STOPWORDS or word in seen:
            continue
        seen.add(word)
        picked.append(word)
        if len(picked) >= limit:
            break
    return picked


def grep_paths(term: str) -> list[str]:
    command = [
        "rg", "-l", "-i", "-F", "--no-messages",
        *[arg for glob in EXCLUDE_GLOBS for arg in ("-g", glob)],
        "--", term, ".",
    ]
    try:
        result = subprocess.run(
            command, cwd=ROOT, capture_output=True, text=True, timeout=15
        )
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return []
    paths = []
    for line in result.stdout.splitlines()[:MAX_TERM_RESULTS]:
        line = line.strip()
        if line.startswith("./"):
            line = line[2:]
        if line:
            paths.append(line)
    return paths


def read_capped(relative: str) -> tuple[str, int]:
    path = ROOT / relative
    try:
        raw = path.read_bytes()[:MAX_FILE_BYTES]
    except OSError:
        return "", 0
    return raw.decode("utf-8", errors="ignore"), len(raw)


def parse_ref(ref: str) -> tuple[str, int | None, int | None]:
    """Split `path#L12-L34` into path and a one-based line range."""
    if "#L" not in ref:
        return ref, None, None
    path, anchor = ref.split("#L", 1)
    if "-L" in anchor:
        start, end = anchor.split("-L", 1)
    else:
        start, end = anchor, anchor
    try:
        return path, int(start), int(end)
    except ValueError:
        return path, None, None


def read_ref(ref: str) -> tuple[str, int]:
    """Read a whole file, or only the indexed line range."""
    path, start, end = parse_ref(ref)
    if start is None:
        return read_capped(path)
    try:
        lines = (ROOT / path).read_text(encoding="utf-8", errors="ignore").splitlines()
    except OSError:
        return "", 0
    slice_ = "\n".join(lines[max(0, start - 1) : max(0, end)])
    return slice_, len(slice_.encode("utf-8"))


def matches(text: str, pattern: str) -> bool:
    return re.search(pattern, text, re.IGNORECASE | re.MULTILINE) is not None


def naive_lookup(question: str, answer: str, max_reads: int = NAIVE_MAX_READS) -> dict:
    started = time.perf_counter()
    scores: dict[str, float] = {}
    read_files: list[str] = []
    bytes_read = 0
    for term in terms(question):
        hits = grep_paths(term)
        weight = 1.0 / max(1, len(hits))
        for path in hits:
            scores[path] = scores.get(path, 0.0) + weight
    ranked = sorted(
        scores,
        key=lambda path: (-scores[path], path.count("/"), len(path), path),
    )
    found = False
    for path in ranked[:max_reads]:
        text, size = read_capped(path)
        read_files.append(path)
        bytes_read += size
        if matches(text, answer):
            found = True
            break
    return {
        "ok": found,
        "via": "grep",
        "files": read_files,
        "bytes": bytes_read,
        "ms": (time.perf_counter() - started) * 1000.0,
    }


def index_lines() -> list[str]:
    if not INDEX_PATH.exists():
        return []
    return INDEX_PATH.read_text(encoding="utf-8").splitlines()


def linked_paths(line: str) -> list[str]:
    return [match.group(0)[1:-1] for match in REF_PATTERN.finditer(line)]


def indexed_lookup(question: str, answer: str) -> dict:
    started = time.perf_counter()
    read_files: list[str] = []
    bytes_read = 0
    lines = index_lines()
    if lines:
        index_text = "\n".join(lines)
        bytes_read += len(index_text.encode("utf-8"))
        words = terms(question, limit=8)
        scored: list[tuple[float, int, str]] = []
        for position, line in enumerate(lines):
            lowered = line.lower()
            score = sum(len(word) for word in words if word in lowered)
            if score and linked_paths(line):
                scored.append((score, -position, line))
        scored.sort(reverse=True)
        tried: set[str] = set()
        for _, _, line in scored[:INDEX_MAX_LINES]:
            for path in linked_paths(line):
                if path in tried or path == "docs/INDEX.md":
                    continue
                tried.add(path)
                text, size = read_ref(path)
                read_files.append(path)
                bytes_read += size
                if matches(text, answer):
                    return {
                        "ok": True,
                        "via": "index",
                        "files": read_files,
                        "bytes": bytes_read,
                        "ms": (time.perf_counter() - started) * 1000.0,
                    }
    fallback = naive_lookup(question, answer)
    return {
        "ok": fallback["ok"],
        "via": "fallback",
        "files": read_files + fallback["files"],
        "bytes": bytes_read + fallback["bytes"],
        "ms": (time.perf_counter() - started) * 1000.0,
    }


def validate_index() -> list[str]:
    problems: list[str] = []
    for number, line in enumerate(index_lines(), start=1):
        for ref in linked_paths(line):
            path, start, end = parse_ref(ref)
            target = ROOT / path
            if not target.exists():
                problems.append(f"INDEX:{number}: missing target {path}")
                continue
            if start is not None:
                count = len(target.read_text(encoding="utf-8", errors="ignore").splitlines())
                if start < 1 or end is None or end > count:
                    problems.append(f"INDEX:{number}: anchor {ref} outside {path} ({count} lines)")
    return problems


def validate_bank(bank: dict) -> list[str]:
    problems: list[str] = []
    for entry in bank["facts"]:
        path = ROOT / entry["path"]
        if not path.exists():
            problems.append(f"{entry['id']}: missing answer path {entry['path']}")
            continue
        text, _ = read_capped(entry["path"])
        if not matches(text, entry["answer"]):
            problems.append(f"{entry['id']}: answer pattern not found in {entry['path']}")
        if entry["path"] == "docs/INDEX.md":
            problems.append(f"{entry['id']}: index may not be the answer path")
    for entry in bank["overview"]:
        if not any(matches(read_capped(path)[0], entry["answer"]) for path in entry["canonical"]):
            problems.append(f"{entry['id']}: overview pattern missing from canonical files")
    return problems


def median(values: list[float]) -> float:
    return statistics.median(values) if values else float("nan")


def run_facts(bank: dict, reps: int) -> dict:
    records: list[dict] = []
    for entry in bank["facts"]:
        naive_runs = [naive_lookup(entry["question"], entry["answer"]) for _ in range(reps)]
        indexed_runs = [indexed_lookup(entry["question"], entry["answer"]) for _ in range(reps)]
        records.append(
            {
                "id": entry["id"],
                "naive_ok": all(run["ok"] for run in naive_runs),
                "indexed_ok": all(run["ok"] for run in indexed_runs),
                "naive_ms": median([run["ms"] for run in naive_runs]),
                "indexed_ms": median([run["ms"] for run in indexed_runs]),
                "naive_bytes": median([run["bytes"] for run in naive_runs]),
                "indexed_bytes": median([run["bytes"] for run in indexed_runs]),
                "naive_files": median([len(run["files"]) for run in naive_runs]),
                "indexed_files": median([len(run["files"]) for run in indexed_runs]),
                "indexed_via": indexed_runs[0]["via"],
            }
        )
    return {"records": records}


def git_text_files() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files", "-z"], cwd=ROOT, capture_output=True, text=True
    )
    files: list[str] = []
    for path in result.stdout.split("\0"):
        if not path:
            continue
        if path.startswith("graphify-out/") or path.startswith(".mirage-runtime/"):
            continue
        if Path(path).suffix.lower() not in TEXT_SUFFIXES:
            continue
        files.append(path)
    return sorted(files)


def overview_naive(bank: dict) -> dict:
    started = time.perf_counter()
    pending = {entry["id"]: entry for entry in bank["overview"]}
    found: set[str] = set()
    files_read = 0
    bytes_read = 0
    for path in git_text_files():
        if not pending:
            break
        text, size = read_capped(path)
        files_read += 1
        bytes_read += size
        for identifier, entry in list(pending.items()):
            if matches(text, entry["answer"]):
                found.add(identifier)
                pending.pop(identifier)
    return {
        "coverage": len(found) / max(1, len(bank["overview"])),
        "files": files_read,
        "bytes": bytes_read,
        "ms": (time.perf_counter() - started) * 1000.0,
        "missing": sorted(pending),
    }


def overview_indexed(bank: dict) -> dict:
    started = time.perf_counter()
    entry_points = ["README.md", "docs/INDEX.md", "docs/registers/04-handoff.md", "docs/MILESTONES.md"]
    corpus = ""
    bytes_read = 0
    files_read = 0
    for path in entry_points:
        text, size = read_capped(path)
        corpus += "\n" + text
        bytes_read += size
        files_read += 1
    found = {entry["id"] for entry in bank["overview"] if matches(corpus, entry["answer"])}
    missing = [entry["id"] for entry in bank["overview"] if entry["id"] not in found]
    return {
        "coverage": len(found) / max(1, len(bank["overview"])),
        "files": files_read,
        "bytes": bytes_read,
        "ms": (time.perf_counter() - started) * 1000.0,
        "missing": missing,
    }


def fmt(value: float, suffix: str = "") -> str:
    if value != value:
        return "n/a"
    return f"{value:.1f}{suffix}"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--mode", choices=("facts", "overview", "all"), default="all")
    parser.add_argument("--rep", type=int, default=3)
    parser.add_argument("--json", type=Path)
    parser.add_argument("--validate-only", action="store_true")
    parser.add_argument("--no-gate", action="store_true")
    args = parser.parse_args(argv)

    bank = load_bank()
    problems = validate_bank(bank) + validate_index()
    if problems:
        print("BANK INVALID", file=sys.stderr)
        for problem in problems:
            print(f"  - {problem}", file=sys.stderr)
        return 2
    print(f"bank ok: {len(bank['facts'])} facts, {len(bank['overview'])} overview facts")
    if args.validate_only:
        return 0

    report: dict = {"gate": GATE, "reps": args.rep}
    failures: list[str] = []

    if args.mode in ("facts", "all"):
        facts = run_facts(bank, args.rep)
        naive_ms = median([row["naive_ms"] for row in facts["records"]])
        indexed_ms = median([row["indexed_ms"] for row in facts["records"]])
        naive_bytes = median([row["naive_bytes"] for row in facts["records"]])
        indexed_bytes = median([row["indexed_bytes"] for row in facts["records"]])
        accuracy = sum(1 for row in facts["records"] if row["indexed_ok"]) / len(facts["records"])
        fallbacks = sum(1 for row in facts["records"] if row["indexed_via"] != "index")
        speedup = naive_ms / indexed_ms if indexed_ms else float("inf")
        byte_ratio = indexed_bytes / naive_bytes if naive_bytes else float("inf")
        files_median = median([row["indexed_files"] for row in facts["records"]])
        print("\nFACTS")
        print(f"{'id':16} {'naive ms':>9} {'idx ms':>7} {'naive B':>9} {'idx B':>7} {'files':>5}  via")
        for row in facts["records"]:
            print(
                f"{row['id']:16} {fmt(row['naive_ms']):>9} {fmt(row['indexed_ms']):>7} "
                f"{fmt(row['naive_bytes']):>9} {fmt(row['indexed_bytes']):>7} "
                f"{row['indexed_files']:>5.0f}  {row['indexed_via']}"
                + ("" if row["indexed_ok"] else "  MISS")
            )
        print(
            f"median: naive {fmt(naive_ms, ' ms')} / {fmt(naive_bytes, ' B')} · "
            f"indexed {fmt(indexed_ms, ' ms')} / {fmt(indexed_bytes, ' B')} · "
            f"speedup {speedup:.1f}x · byte ratio {byte_ratio:.2f} · accuracy {accuracy:.0%} · "
            f"fallbacks {fallbacks}"
        )
        report["facts"] = {
            "rows": facts["records"],
            "accuracy": accuracy,
            "naive_ms": naive_ms,
            "indexed_ms": indexed_ms,
            "naive_bytes": naive_bytes,
            "indexed_bytes": indexed_bytes,
            "speedup": speedup,
            "byte_ratio": byte_ratio,
            "indexed_files": files_median,
            "fallbacks": fallbacks,
        }
        if accuracy < GATE["facts_accuracy"]:
            failures.append(f"facts accuracy {accuracy:.0%} < {GATE['facts_accuracy']:.0%}")
        if indexed_ms > GATE["indexed_median_ms"]:
            failures.append(f"indexed median {indexed_ms:.1f} ms > {GATE['indexed_median_ms']:.0f} ms")
        if files_median > GATE["indexed_median_files"]:
            failures.append(f"indexed median files {files_median:.1f} > {GATE['indexed_median_files']:.0f}")
        if speedup < GATE["facts_speedup"]:
            failures.append(f"facts speedup {speedup:.1f}x < {GATE['facts_speedup']:.1f}x")
        if byte_ratio > GATE["facts_byte_ratio"]:
            failures.append(f"facts byte ratio {byte_ratio:.2f} > {GATE['facts_byte_ratio']:.2f}")
        if fallbacks > GATE["facts_no_fallback"]:
            failures.append(f"{fallbacks} question(s) fell back to grep; index must answer all")

    if args.mode in ("overview", "all"):
        naive = overview_naive(bank)
        indexed = overview_indexed(bank)
        speedup = naive["ms"] / indexed["ms"] if indexed["ms"] else float("inf")
        byte_ratio = indexed["bytes"] / naive["bytes"] if naive["bytes"] else float("inf")
        print("\nOVERVIEW")
        print(
            f"naive   {naive['ms']:.1f} ms · {naive['bytes']:,} B · {naive['files']} files · "
            f"coverage {naive['coverage']:.0%}"
        )
        print(
            f"indexed {indexed['ms']:.1f} ms · {indexed['bytes']:,} B · {indexed['files']} files · "
            f"coverage {indexed['coverage']:.0%}"
        )
        print(f"speedup {speedup:.1f}x · byte ratio {byte_ratio:.2f}")
        report["overview"] = {
            "naive": naive,
            "indexed": indexed,
            "speedup": speedup,
            "byte_ratio": byte_ratio,
        }
        if indexed["coverage"] < GATE["overview_coverage"]:
            failures.append(f"overview coverage {indexed['coverage']:.0%} < {GATE['overview_coverage']:.0%}")
        if speedup < GATE["overview_speedup"]:
            failures.append(f"overview speedup {speedup:.1f}x < {GATE['overview_speedup']:.1f}x")
        if byte_ratio > GATE["overview_byte_ratio"]:
            failures.append(f"overview byte ratio {byte_ratio:.2f} > {GATE['overview_byte_ratio']:.2f}")

    if args.json:
        args.json.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print(f"\nreport: {args.json}")

    if failures and not args.no_gate:
        print("\nGATE FAILED")
        for failure in failures:
            print(f"  - {failure}")
        return 1
    print("\nGATE PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
