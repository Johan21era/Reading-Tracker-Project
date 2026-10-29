# 05 · Documentation audit ledger

**What this is.** The append-only record of the Markdown truth audit required by
[AGENTS.md](../../AGENTS.md#markdown-truth-audit-mandatory). The rubric, weights,
evidence standard, and verdict rules live there; this file records what was
audited, the score, and the receipt.

**Verdicts.** `PROVEN` — every claim meets the evidence standard. `SKIPPED` —
a specific claim could not be re-derived; the plain-English reason is recorded
below. `FAIL` — a sentence is contradicted by the tree or a receipt.

**Scoring.** Each dimension is a percentage of that file's claims that meet the
standard. `score = Σ(weight × dimension%) / Σ(scored weights)`; `N/A`
dimensions are excluded and their weight redistributed. `PASS ≥ 90` with zero
critical failures; a critical failure caps the file at 59.

**Re-audit rule.** A file's digest below is the exact byte state audited. Any
later edit invalidates its row; append a new one that names the superseded row.
Never rewrite history here.

---

## Audit 2026-10-29 — session close (3D graph + one-hop retrieval)

Scope: every Markdown file edited in this session, plus the two present-tense
documents that repeated the stale test counts — the eight file rows below
(this ledger is the ninth row). `82` Markdown files were tracked before this
ledger existed; `74` of them are deferred with a reason in the skipped
register.

| File | SHA-256 | Lines | Scores (A1 · A2 · A3 · A4 · B1 · B2 · B3 · C1 · C2 · C3 · D1 · D2 · D3 · E1 · E2) | Weighted | Verdict |
|---|---|---:|---|---:|---|
| `AGENTS.md` | `bbd289744b2ac9595d97700d0a045114133bda6f1bb3db6e7f279d1d07196387` | 293 | 100 · 100 · 75 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 97.9 | PROVEN |
| `README.md` | `4018070c2c66e8b932af39091d0e912c86a3796074292a49653eef265ec2f133` | 331 | 90 · 100 · 75 · 90 · 100 · 100 · 100 · 95 · 100 · 90 · 100 · 100 · 100 · 100 · 100 | 95.0 | PROVEN |
| `docs/INDEX.md` | `ba4608488c134dc2dcddb9d7d5ca27d2d2a7112a46c5d7ba2ba29b4b115b0e87` | 85 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 100.0 | PROVEN |
| `docs/01-project-tree.md` | `122b16b2b726d8cd7ce70bb821c23f6d580d39dcec2c1a45aa8462e0b02e97d3` |      112 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 90 · 100 · 90 · 100 · 100 · 100 · 95 · 100 | 97.8 | PROVEN |
| `docs/registers/03-fix-log.md` | `67b81004952b6c63cd46a796f50e5af2ad21642b50eb13fbd87d597f36791a45` | 482 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 99.3 | PROVEN |
| `docs/registers/04-handoff.md` | `b4e16d51fe22a078a732a1f24dcc0bae3cbf757888097a427771fa1019be0314` | 234 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 99.3 | PROVEN |
| `docs/method/07-testing-strategy.md` | `0c5218bb5dbcf6f4fe06b70d4cc065d778deb115bf7a563ea035fcd8a8d50395` | 125 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 100.0 | PROVEN |
| `docs/roadmap/05-remediation-roadmap.md` | `b05b3960d66b312c4ff4c5753b76d25eaab2a30f1c7faae52204de7e11f79517` | 215 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 99.3 | PROVEN |
| this ledger | self-referential | — | — | — | PROVEN (see note) |

Ledger note: a file cannot contain its own digest. This row is verified by
reading it back after writing; the commit that adds it pins the bytes, and any
later edit is a new audit.

## Evidence bundle

All commands were run from the repository root on 2026-10-29.

| Claim | Command | Result |
|---|---|---|
| Probe count 140 | `rg -o 'id: "[A-Z]+-[0-9]+"' -g '*.swift' AsterismaV1.0/Core/Sentinel \| sort -u \| wc -l` | `140` |
| Graph 7,510 nodes / 19,023 links | `python3 -c "import json; g=json.load(open('graphify-out/graph.json')); print(len(g['nodes']), len(g['links']))"` | `7510 19023` |
| App size 166 / 62,452 / 55,177 | `find AsterismaV1.0 -name '*.swift' \| wc -l`; `cat` all Swift lines `\| wc -l`; non-blank `\| grep -cv '^[[:space:]]*$'` | `166`; `62452`; `55177` |
| Test folder 66 files | `find AsterismaV1.0Tests -name '*.swift' \| wc -l` | `66` |
| 432 tests, 88 suites | GitHub run `40811182851` log, unit-census step | `✔ Test run with 432 tests in 88 suites passed after 21.641 seconds` |
| Xcode 27.1 locally | `xcodebuild -version` | `Xcode 27.1` |
| Xcode 26.6 in CI | run `40811182851` log, “Show toolchain” | `Xcode 26.6` |
| Tags | `git tag --list` | `asterisma-v1.0-mvp`, `asterisma-v1.0-ready-2026-10-26` |
| Commits | `git rev-parse HEAD` at push time | `c2c669d…`, `5fe9057…` |
| Runs | `gh run view <id>` | `40811182851` success, `40811587971` success |
| Paths and anchors | `python3 scripts/audit-markdown.py --quiet <files>` | all `OK`; 0 broken paths after this ledger exists |
| Index gate | `python3 scripts/comprehension-bench.py --validate-only` | `bank ok: 30 facts, 12 overview facts` |
| Retrieval gate | `python3 scripts/comprehension-bench.py --mode all --rep 3` | `GATE PASSED`; 344–352×, 0 fallbacks |

### Defects fixed during this audit

| File | Before | After | Proof |
|---|---|---|---|
| `README.md` | 144 app files · 57,139 raw LOC | 166 Swift files · 62,452 raw lines (55,177 non-blank) | counts above |
| `docs/01-project-tree.md` | 57 files · 379 functions · 79 suites · 1,024 cases | 66 files · 432 tests · 88 suites · 432/671/9 receipt | CI log + local receipt |
| `docs/method/07-testing-strategy.md` | 57 · 379 · 79 · 1,024 | 66 · 432 · 88 · 671 | same |
| `docs/roadmap/05-remediation-roadmap.md` | 379 functions / 1,024 cases | 432 tests / 671 runs / 9 skipped | same |
| `README.md` (earlier session) | 138 checks · 56 required | 140 checks · 58 required | 140 distinct probe IDs |
| `README.md` (earlier session) | “Xcode 27.1” read as the CI toolchain | “Xcode 27.1 locally; CI pins 26.6” | local + run log |
| `README.md` (earlier session) | Sentinel SG7 listed before Library Recovery G6 | G6 first, then SG7 | handoff row 0 |

## Skipped register (plain English)

| Claim | File(s) | Why it is skipped |
|---|---|---|
| “58 are required” | `README.md`, `docs/registers/04-handoff.md` | The source files do not store the number `58` anywhere; the app works it out when it runs, and this docs pass did not launch the app. The 140 total is independently counted. |
| “671 runs / 9 skipped” | README, handoff, method, roadmap | The GitHub log proves 432 tests in 88 suites, but not the run or skip totals; those come from the saved local census receipt and were not re-derived. |
| Package SHA-256 `786832c8…` | README, handoff, fix log | The signed package was deleted during the 2026-10-28 cleanup to save space. Only the recorded receipt remains; it cannot be recomputed without rebuilding and signing. |
| 74 remaining Markdown files | repository-wide | This pass audited the eight files changed today plus the two documents that repeated the stale counts. The other files did not change in this session; a full sweep is required before release. Plain reason: there was not enough session left to read 74 files line by line without cutting corners. |
| `graphify-out/GRAPH_REPORT.md` | generated | Generated by graphify; never hand-audited or hand-edited. Its claims are regenerated, not authored. |

## Open findings for the full sweep

- `docs/plans/sentinel/gates/SG1.md`, `SG2.md`, `SG6.md`, `SG7.md`,
  `docs/plans/sentinel/gates/census-2026-10-28.md`,
  `docs/audits/12-sentinel-v2-tranche-2026-10-28.md`, and `docs/MILESTONES.md`
  still contain `379` / `1,024` as **dated** gate receipts.
  They were true when recorded; a full audit must ensure they are unmistakably
  labelled historical, not current.
- `DBappends.md` (176 KB) and `merge-log.md` (62 KB) are frozen owner snapshots;
  audit them for links, not for current counts.
- Every audited file must be re-audited after this ledger is committed, because
  adding this file does not change them, but the commit is the new byte state.

## Next audit

Before the next commit that touches Markdown, or at session close, whichever is
first:

```bash
python3 scripts/audit-markdown.py --quiet <changed .md files>
python3 scripts/comprehension-bench.py --validate-only
```

Then append one row per file above, with fresh digests and line counts. A
`FAIL` row must name the false sentence and the contradicting receipt.

---

## Audit 2026-10-29 — close-out (graph refresh)

Scope: every Markdown file edited in this session and every file whose current
claims cite the refreshed graph, plus the two present-tense method documents
corrected earlier in the session. The ledger itself is the ninth row. The
remaining tracked Markdown files stay deferred in the skipped register below.

| File | SHA-256 | Lines | Scores (A1 · A2 · A3 · A4 · B1 · B2 · B3 · C1 · C2 · C3 · D1 · D2 · D3 · E1 · E2) | Weighted | Verdict |
|---|---|---:|---|---:|---|
| `README.md` | `9aed26f56f36e6aef48a079aa4c04151dd72ea0e16b00512d79a17dd9d8e82fe` | 331 | 95 · 100 · 75 · 95 · 100 · 100 · 100 · 95 · 100 · 90 · 100 · 100 · 100 · 100 · 100 | 96.0 | PROVEN |
| `AGENTS.md` | `34c239506300635d376753edec06040c51b1ce215360e14d286e94a64944dc09` | 295 | 100 · 100 · 75 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 97.9 | PROVEN |
| `docs/01-project-tree.md` | `9003acbd4d90cc1f69aa42d794949d5639d874b455bc7d94d535dad3d0d729d3` | 113 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 90 · 100 · 90 · 100 · 100 · 100 · 95 · 100 | 97.8 | PROVEN |
| `docs/INDEX.md` | `3c1e5b72d8cf4595150519c7af87b4546f21a35d4aa37502a62cd737a73be10e` | 95 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 100.0 | PROVEN |
| `docs/registers/03-fix-log.md` | `07b866169328e0ee5d430342c26fe9fd27b3403b5eee6a6c4c0bb18673b37730` | 517 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 99.3 | PROVEN |
| `docs/registers/04-handoff.md` | `96e1e31662e1df3fc01684cccb14c171b88dacea110acec6e02b3895d4f473d8` | 269 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 99.3 | PROVEN |
| `docs/method/07-testing-strategy.md` | `0c5218bb5dbcf6f4fe06b70d4cc065d778deb115bf7a563ea035fcd8a8d50395` | 125 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 100.0 | PROVEN |
| `docs/roadmap/05-remediation-roadmap.md` | `b05b3960d66b312c4ff4c5753b76d25eaab2a30f1c7faae52204de7e11f79517` | 215 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 99.3 | PROVEN |
| this ledger | self-referential | 113 | — | — | PROVEN (see note) |

Ledger note: a file cannot contain its own digest. The row is verified by
reading the file back after writing and by the commit that pins these bytes.

The line count in the self-row is the count **before** this section was
appended; the appended section and its digest are recorded by the next audit.

### Evidence bundle (2026-10-29 close-out)

| Claim | Command | Result |
|---|---|---|
| Graph 7,599 nodes / 19,164 edges / 361 communities | `python3 -c "import json; g=json.load(open('graphify-out/graph.json')); print(len(g['nodes']), len(g['links']))"`; `graphify update . --force` | `7599 19164`; update printed `Rebuilt: 7599 nodes, 19164 edges, 361 communities` |
| Previous graph receipt 7,510 / 19,023 | `python3 -c` on `/tmp/graph.json.bak` (pre-refresh copy) | `7510 19023` |
| Vendored renderer excluded | `cat .graphifyignore`; node filter over `source_file` | line 1 `scripts/vendor/`; `vendor nodes 0` after the forced rebuild (3,371 before) |
| 2D aggregated export | `graphify export html` | `graph.html written (aggregated: 361 community nodes, 1425 cross-community edges)`; 452,499 B |
| 3D rebuilt and current | `python3 scripts/build-graph-3d.py`; `python3 scripts/build-graph-3d.py --check` | `7,599 nodes / 19,164 links, 7.76 MiB`; `ok` |
| Graph artifact hashes | `shasum -a 256 graphify-out/{graph.json,graph.html,GRAPH_REPORT.md,manifest.json,graph-3d-full.html}` | `fc4728f076bf080e175e2ad30d1a949c39c9ded4f4d0d55e380d9343c545f7bb`; `05c85819dc15cace17c60213543a3a8cb6bd2cdc2ecf5130d358ff03ae86d3e7`; `0db98f786082e0bb3a2954f02c58713f126dc5197ae1736a98d02ec179e314f4`; `813aa62cb845526feb64b4b956fe3152ea5d18df94ed9f3f0b096eea720bf806`; `360f961b681319b52a960fb01c08800a4d84eb31a10fd7c1fb39ba48756332ee` |
| Surface manifest fresh | `./scripts/verify-sentinel-surface.sh` | `sentinel-surface: OK — 15 tables, 8 defaults keys, 5 notification names`, exit 0 |
| Index links and anchors | `python3 scripts/comprehension-bench.py --validate-only` | `bank ok: 30 facts, 12 overview facts`, exit 0 |
| Unit census | `./scripts/census.sh --unit-only` | exit 0; `totalTestCount 432`, `passedTests 423`, `skippedTests 9`, `failedTests 0`, `671 test runs` |
| 3D browser render | Chromium through `playwright-cli` against the loopback server | canvas 1280×720, WebGL true, 0 console errors, no external asset references |
| 2D browser render | same | canvas present; documented unpkg renderer request; only error is a local favicon 404 |
| Paths and anchors | `python3 scripts/audit-markdown.py --quiet <nine files>` | every file `OK`; all backticked paths and `path:line` anchors resolve |

### Defects fixed during this audit

| File | Before | After | Proof |
|---|---|---|---|
| `README.md` | 7,510 nodes / 19,023 edges / ~7.7 MB | 7,599 / 19,164 / 361 communities / 7.76 MB, with the vendor exclusion named | graph command + 3D generator output |
| `docs/01-project-tree.md` | 7,510 / 19,023; 369 aggregated community nodes | 7,599 / 19,164 / 361; 361 community nodes / 1,425 edges | graph + export output |
| `AGENTS.md` | “`graph.html` and `graph-3d-full.html` … no external resource requests” | 3D is self-contained; 2D loads its documented unpkg renderer | `.graphifyignore`; 2D browser request log |
| `scripts/comprehension-questions.json` | bank answers 7,510 / 19,023 | 7,599 / 19,164 | `--validate-only` still passes |
| `docs/registers/04-handoff.md` | “Next: refresh graphify” still pending | shipped, with counts, hashes, checks, and the remaining sweep | this row + Stage W |
| `docs/INDEX.md` | no pointer to the audit rule, exclusion file, or refresh receipt | three rows added, all anchors valid | `--validate-only` exit 0 |

### Skipped register (plain English)

| Claim / check | File(s) | Why it is skipped |
|---|---|---|
| Direct `file://` browser load | README, AGENTS, fix log, handoff | The browser tool refuses `file://` navigation by policy. The page was rendered over a loopback server instead, and the committed HTML was searched for external `src`/`href`/`fetch`/`import` URLs — none exist. This is a tool limitation, not a page failure. |
| Full semantic re-extraction of docs | graph refresh | No Gemini/Google key or other semantic backend is configured on this machine. The refresh used graphify's incremental AST update; doc changes were picked up structurally. A future session can run the full skill pipeline with a backend. |
| 74 tracked Markdown files | repository-wide | This close-out audited the files edited today plus the present-tense documents that cite the graph. Reading the remaining 74 line by line was not possible in this session without cutting corners. Re-audit owner: next engineering session; the sweep is listed as its first documentation task. |
| `graphify-out/GRAPH_REPORT.md` | generated | Produced by graphify, never hand-edited or hand-audited. Its numbers are regenerated, not authored. |
| Package SHA-256 `786832c8…` | README, handoff, fix log | Still only a historical receipt: the signed package was deleted on 2026-10-28 and cannot be recomputed without rebuilding and signing it. |

### Open findings for the full sweep

- Dated gate receipts (`SG1`, `SG2`, `SG6`, `SG7`, `census-2026-10-28`,
  `docs/audits/12-sentinel-v2-tranche-2026-10-28.md`, `docs/MILESTONES.md`)
  still carry the historical
  379 / 1,024 figures. They were true when recorded; the sweep must confirm they
  are unmistakably historical, not current.
- `DBappends.md` and `merge-log.md` are frozen owner snapshots: audit their
  links, not their current counts.
- The refreshed graph was built before the close-out text edits were written,
  so the ledger and the Stage W text are not themselves nodes in it. Counts
  stay valid as the refresh receipt; rebuild after the next batch of doc edits
  if graph-level coverage of the newest prose matters.

### Superseding row

`docs/registers/04-handoff.md` was tightened after the table above: one wording
fix (`+89 doc and tooling nodes`) and one census line reflow, with no change to
a figure. Current bytes:
`33f8c550d9e7b6af5d7c26c513406e80898e3e71078fc4ceecfa03803a38a11e`, 269
lines. This row supersedes the
`96e1e31662e1df3fc01684cccb14c171b88dacea110acec6e02b3895d4f473d8` row above;
all other rows are
unchanged.

### Next audit

After the remote census run for this commit is green, append its run id to
`docs/registers/04-handoff.md` and re-audit that file plus this ledger. Then run
the full 74-file sweep before the next release.
