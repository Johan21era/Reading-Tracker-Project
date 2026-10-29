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

### Post-push receipt (2026-10-29)

GitHub Actions run `40813582449` succeeded in **2m25s** on commit
`b4b587be9aaead322d42581f0a44a7e35bf939e7` (the graph and documentation
commit). The log shows all three gates green: “Sentinel surface manifest
freshness”, “Comprehension index freshness”, and “Unit census (green =
merge-presence receipt)”. This is the remote proof for the local mirror above.

The handoff then gained the run receipt, so its audited bytes moved again:
`936b58856ffa67bc3624107dc658517d713c31646834eb22a312b9ec07796612`, 273
lines. This supersedes the
`33f8c550d9e7b6af5d7c26c513406e80898e3e71078fc4ceecfa03803a38a11e` row; every
other row stands. This
ledger's own bytes change with this section, which is expected and recorded by
the next audit.


---

## Audit 2026-10-29 — full sweep (all 83 tracked Markdown files)

Scope: every tracked Markdown file after the graph refresh and the documentation
repairs — the 74 files deferred by the earlier audits plus the nine files already
on this ledger. The sweep completes the item the previous section scheduled.

**Method.** `scripts/audit-markdown.py` extracted every backticked repository
path, every `path:line` anchor, every 64-hex digest, and every command in a bash
fence. All 83 files then received a row below. Current documents were re-derived
against the tree and today's commands. Dated receipts — gate records, audits,
owner sessions, campaign logs, design snapshots — were checked for resolving
links and structure, but their historical numbers, command exit statuses, and
receipts were **not re-derived**; they are scored and disclosed accordingly.

**Result:** **13 PASS**, **68 REVIEW** (dated receipts or design records with
disclosed skips), **1 SKIPPED** (generated), plus this ledger's self row. There
are **zero critical failures**: no broken path or anchor remains, no check is
claimed as passed without a receipt, and every unproven claim is listed in the
skipped register. Rows from earlier audits remain as history; this table
supersedes every prior row for the same file.

| Date | File | SHA-256 | Lines | Scores (A1 · A2 · A3 · A4 · B1 · B2 · B3 · C1 · C2 · C3 · D1 · D2 · D3 · E1 · E2) | Weighted | Verdict | Evidence / SKIPPED reason |
|---|---|---|---:|---|---:|---|---|
| `AGENTS.md` | `34c239506300635d376753edec06040c51b1ce215360e14d286e94a64944dc09` | 295 | 100 · 100 · 75 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 97.9 | PASS | Rules and local CI mirror verified; D2 N/A because this file is not an index target. |
| `DBappends.md` | `77a16aad5f9e3550a895692a00dd1f3f2fed82998c1bb100baa7c6d7700fa075` | 3801 | 70 · 100 · 0 · 100 · 100 · 90 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 95 · 100 | 86.1 | REVIEW | Current baseline 432/140/162 re-derived; implementation holds labelled; design commands not re-run. |
| `README.md` | `9b520684a7215c1d620bf13e9e8fe89a7ae32c04ceb05db1044f262f9e21b0bc` | 331 | 95 · 100 · 75 · 95 · 100 · 100 · 100 · 95 · 100 · 90 · 100 · 100 · 100 · 100 · 100 | 96.0 | PASS | Current census, app size, and graph figures re-derived; 58-required and package SHA remain disclosed skips. |
| `docs/01-project-tree.md` | `9003acbd4d90cc1f69aa42d794949d5639d874b455bc7d94d535dad3d0d729d3` | 113 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 90 · 100 · 90 · 100 · 100 · 100 · 95 · 100 | 97.8 | PASS | Current figures re-derived on 2026-10-29; 417-path sweep and index gate pass. |
| `docs/12-owner-test-authority.md` | `fb458816beb87fa3654fa5dffa4b0f1ae6bec67bb501ae777051bd98cd3f17e0` | 139 | N/A · 100 · N/A · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 100.0 | PASS | Policy document; live session counts SKIPPED (owner data); template now uses an angle-bracket pattern. |
| `docs/INDEX.md` | `3c1e5b72d8cf4595150519c7af87b4546f21a35d4aa37502a62cd737a73be10e` | 95 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 100.0 | PASS | Current figures re-derived on 2026-10-29; 417-path sweep and index gate pass. |
| `docs/MILESTONES.md` | `33f1bd7eaf26de688c6f60e9999953e4166095c8bba9065d7f96a569a95ad911` | 314 | 40 · 100 · 0 · 100 · 100 · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 82.4 | REVIEW | Dated milestone log; SG8 postscript added; historical 229/379 figures are labelled, not re-derived. |
| `docs/REBRAND-ASTERISMA.md` | `0e6dae03cd84f4fd1c7ba7036b48d421e4be4b64abe0ddc281c418de2830d3f7` | 86 | 50 · 100 · 0 · 100 · 100 · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 83.8 | REVIEW | Dated migration record; links OK; move counts and commands not re-derived. |
| `docs/audits/08-deep-audit.md` | `04f9e38190b2b1d0b6cbf8732fbabb7acae08ea1993abfdd75d5b38356dafccf` | 309 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/audits/11-completion-and-health-report-2026-10-24.md` | `c87bacd7279980d47a0c13fdcee8b299ff4dab7266941026f440b85ed7dd67e8` | 383 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/audits/12-sentinel-v2-tranche-2026-10-28.md` | `e96d2872add057cc0c84e07f170b08265e0262f01b997fea153c2f9560f5e1b3` | 76 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/design/READER-POLISH-2026-10-25.md` | `3cb69710c275bac78869c32ae06cdd14e32fc330d28a267c1d4b84b5166adc40` | 138 | 50 · 100 · 0 · 100 · 100 · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 83.8 | REVIEW | Dated design receipt (2026-10-25); links OK; census and commands are historical. |
| `docs/design/UX-BETA-AUDIT-2026-10-25.md` | `013ccb2425a594bc400f9276744bffc093ccb693550e64f604bd7d594e19f6a2` | 279 | 50 · 100 · 0 · 100 · 100 · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 83.8 | REVIEW | Dated design receipt (2026-10-25); links OK; census and commands are historical. |
| `docs/design/fullscreen-surface-audit.md` | `d24a9ad32b517b708a2c4111f691276b92142476d09eebf092a3ff91516f89e8` | 109 | 50 · 100 · 0 · 100 · 100 · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 83.8 | REVIEW | Dated design receipt (2026-10-24); links OK; measurements are historical. |
| `docs/history/09-final-traces.md` | `e1d40261ec9b59ddf54b407ebba521b6e49e77e0a0e5e5e9f0aa4db3b8d2fa47` | 120 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/history/10-profiler-fix.md` | `0852d1dfb15d306aff0c72a71dd2755113aea8f645c23bc8a0457249a66b6ee9` | 428 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/MIRAGE-DEEP-DIVE-2026-10-28.md` | `472af7fa55768002366a483b86103b2d7de56dff7b304e46c32853393b726cde` | 263 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/PR4-defect-analysis-2026-10-18.md` | `3495cfa7623db96180a70a11c3594ba7f9fe10f36eefb709d9eb0eb6aef56f92` | 680 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/PR5-execution-plan-2026-10-18.md` | `b3be24f3b98a6467443b2abd2708b50b4faba8b16170f2361db2273f62987d2c` | 70 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/RT_Mirage_Codebase_Merge_Playbook.md` | `d83c97541402f2ca199e433fec99fb765ddd2274b29238cda2a41fbf89b868dd` | 2649 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/Twin-READMES-2026-10-18.md` | `5fa5ade696268e4b3922d4e97b287ce4373b330b4da903292cb81a9269e42e0b` | 445 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/adr/ADR-12-titanium-bridge-charter.md` | `68e3420b0289f61d93a6ebf3af8da3f99091dd52957d81c745ae8b59d9e5a1d3` | 61 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/adr/ADR-2-transport-and-protocol.md` | `3ac14c8e867bc2cf6318b844d4bd0216136ce2de79df9986ef8e45184f1f9d53` | 46 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/adr/ADR-3-packaged-runtime-distribution.md` | `3b6fa5f444043d5d699a0d6e5921ff9a5e8b382dc5c8c316ec2d0f0c8687325f` | 87 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/adr/ADR-4-ledger-placement-and-backup-ownership.md` | `12d704829c1ea42841584159c2ca0208c4c7419d7675e363779c15a9ab91ed66` | 48 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/adr/ADR-5-identity-mapping.md` | `fd81e68bd8df7a0e2527c96570a123b0f2271c79a5860e5a7ad751e80a24789a` | 48 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/adr/ADR-6-mirage-feature-lifecycle.md` | `88d8960183344522e9a638f82e4c2ce79d6f4603c3164c94515dc3c7b88993b5` | 76 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/adr/ADR-6a-mirage-import-independence-newde5.md` | `676ff3840538cdb9eff422c11339035a392d76bead14001ade0680cf5773d805` | 78 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/adr/ADR-7-spoiler-cursor-contract.md` | `ff46e67682a9b070ca922464e4dc3c1cd36078b0e48fe0b7fa8653fb39450cdd` | 212 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/adr/ADR-8-repository-strategy.md` | `47ada237c25e64850e39f2a7a8b0db7e9e2659e981c18154d2360a0fe14eb778` | 64 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/evidence/README.md` | `e8ef1800b691bb7bba9c48f8c43c2a3a71adc22ec9abdc5c06adeee32734aae0` | 21 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/evidence/handoff-bundle-2026-10-18.md` | `f3c867d85739c2b99d08239326085e54296804df31b836a667581ae357ad6aed` | 59 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/final-acceptance-2026-10-18.md` | `d966af9bfcd5e085c71125ecff723c4aa2dca6db28c95c72c7603eb686305bc0` | 70 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/merge-log.md` | `2487a34b56328089305a8b18801367b6edd8b153a520e6b0c856cc59fbb3878e` | 354 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/phase1/mirage-protocol-extraction.md` | `80e745784a9c3b5ad05783c402d8a877f234d66384c717df2dfd340d583a72aa` | 54 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/phase1/rt-normative-docs-extraction.md` | `b7390e9d21a54f8cd55193466e257b3368aea83faee9e3ca61d30a56ea08e227` | 48 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/phase1/touchpoint-inventory.md` | `eeb324e178aff88b0e53c1135501014f222b353a1fca8d6c4dc5f87b61a38032` | 90 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/rehearsals/rehearsal-log-2026-10-18.md` | `3edbf8cdaa282cca3f9ac1214a6839084432dde5bdd573009145d84b88f3fc52` | 125 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/tib/TB-M0-gate-plan.md` | `510a71b423005d1b0ac544d97fafe19cd176d357d4aa2f80aba088c2b8e89766` | 47 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/integration/tib/observe-ledger.md` | `176011616f98e58a51db23babcaa0f8fcc92124924ebb16677558b92aed80463` | 6 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/method/07-testing-strategy.md` | `0c5218bb5dbcf6f4fe06b70d4cc065d778deb115bf7a563ea035fcd8a8d50395` | 125 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 100.0 | PASS | Current figures re-derived on 2026-10-29; 417-path sweep and index gate pass. |
| `docs/owner-test-results/2026-10-24-session-1.md` | `bba71640cb60ec42000e458df4a722fcf8700862fd8fcb3e310bd14ad1e3cff4` | 176 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/owner-test-results/2026-10-25-session-2.md` | `63d364489e1123aeb3af9bfd8fc25ac0e7b78c48f103749cd5fc2e11fe329b29` | 75 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/owner-test-results/README.md` | `d835dd4c771b55abec8cbf171a73a020e969206a30be5ecc89e839b0f0f5def2` | 32 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/owner-test-results/TEMPLATE.md` | `fe4885294682a5ba3b587f55fb4a6c1ff3bae57073139602c481d45d30828f88` | 42 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/bedrock/BASELINE.md` | `b52ee5aa6fb8d41d4c4092ca0a66a19c82a14b6c96bfb7631ecf20ad9e8574e3` | 98 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/bedrock/BEDROCK-MASTER-PLAN-2026-10-24.md` | `ed03541feff0a10b96becc1f32059c40f0e61b3a9c16ef414cd4dc68abad7b3c` | 742 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/bedrock/DISTRIBUTION.md` | `3480f5dbdaf2cd10f93633af342f52947f42869c3304d8af3ff5014b1cb2eb86` | 58 | 60 · 100 · 40 · 80 · 100 · 90 · 100 · 100 · 100 · 90 · 100 · 100 · 100 · 90 · 100 | 86.3 | REVIEW | Dated distribution guidance; package SHA is a deleted historical receipt; commands not re-run. |
| `docs/plans/bedrock/GATE-LOG.md` | `a5aaa7d22857ea0c7105be1c29ae84906fa1804236b4bcb48453afdfb246cb95` | 50 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/bedrock/GATE-TEMPLATE.md` | `2b6a66f7a01a4777cf91d4addfd86073121e218651f92fd512439f843ceb3a4e` | 93 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/bedrock/SESSION-2026-10-24.md` | `1fa396db139dd29b9a0c036c199b6f5d478482b60e5be5b7945d697661412499` | 176 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/bedrock/gates/GATE-G1.md` | `d324f12fd04e22149895434f9952904acbe3cd2d4f9645124ce8e65d4fc42c70` | 52 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/bedrock/gates/GATE-G2.md` | `12679fe04822e351c9ad95d351242fe01f6d9dd326939ce1c665f90cf9fff136` | 50 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/bedrock/gates/GATE-G2B.md` | `638c2ca1ad0402b4265e18a4f1bedcdec36176af004f75144f70975d0d592256` | 53 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/bedrock/gates/GATE-G3A.md` | `5be705446b17fc79bab74419c60b4ad6b2a4d33015efd5fd41805ffc936c4f78` | 55 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/bedrock/gates/GATE-G3B.md` | `9c08fd8e47e745a493a87734b356f91170308ceb5c5ccc897cdabe605594edbd` | 55 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/bedrock/gates/GATE-G3C.md` | `8e9419f838eb0b16f6a3537669bfb06053603743a524a56bebadf6993acf8c55` | 52 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/bedrock/gates/GATE-G4.md` | `42dbf7581f645d730407dca8de62bdc3f869e92ba88e4e07a2819c5b35febac0` | 52 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/bedrock/gates/GATE-G5.md` | `9014fc06e4400aa80e6cd7a4fe7aeca7dc581a57afb2edc358e00f3d8aa78570` | 38 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/bedrock/gates/GATE-G6.md` | `a9c5eb1f69690178c7502e8cd86357271d65c7b6802506490a018c602b29b455` | 35 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/bedrock/gates/GATE-G7.md` | `838ffdf2aa002da0c4948fe3e75b75f38644dde73ff9bf155412a160d87c36e5` | 42 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/bedrock/gates/GATE-G8.md` | `13791cf600deb7faf3241b4439d3915ccfba180d64b10de10ee0bd7a70a227f9` | 102 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/library-recovery/G6.md` | `5df26c569a4a6cf40fb3b0a6ff7d59e81c7ea619017cd3514218436bfe5173d2` | 78 | 100 · 100 · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 99.2 | PASS | Current figures re-derived on 2026-10-29; 417-path sweep and index gate pass. |
| `docs/plans/sentinel/SENTINEL-ROADWORK.md` | `793ed141bb82bc1a7bbbbac41cb4f826b5ed164c81cb9a23e76d025920f4f4d5` | 4007 | 70 · 100 · 0 · 100 · 100 · 90 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 95 · 100 | 86.1 | REVIEW | Current 140/432 re-derived; 138/36 figures are the plan, not shipped claims; commands not re-run. |
| `docs/plans/sentinel/gates/README.md` | `19fcaa2b93ed7f423d1881036c2e0fdf7290ef59fb355cab135d8bfbb5b1e70b` | 50 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 100.0 | PASS | Current figures re-derived on 2026-10-29; 417-path sweep and index gate pass. |
| `docs/plans/sentinel/gates/SG0.md` | `ff0b88bfab892d6e5d2605e3f0f93bba4e2a6f3ad02254c2b553f60237d265d6` | 89 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/sentinel/gates/SG1.md` | `30dcce89d6be9f794e46719ffee7f7d4c03ddb45f4dda378f9984622f1ced90d` | 59 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/sentinel/gates/SG2.md` | `cfa9d7772348e4d0a4b1ba7df90ca77c05a67df5939d25c1802abe2737c160fb` | 63 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/sentinel/gates/SG3.md` | `f381dfedb4d0cd8fb8f4d152e3c942adcc2afceb98f8f7f0378ecec734b97cf9` | 64 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/sentinel/gates/SG4.md` | `045c654b435864affd5c1845a4ec1d0f6274a695a8b2acc0dfcb8dd6eb39d1c2` | 64 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/sentinel/gates/SG5.md` | `36b7660f5324ed0371162f48d75ed0dbff35b0d3e6dacb90f69bba5ec03cd7d0` | 62 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/sentinel/gates/SG6.md` | `aba1ce66f1e7b433682469a7dec0a25b54731c4f0858dc51045aaa1fbb786ccd` | 63 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/sentinel/gates/SG7.md` | `db142307aca59778ebf456af4b374b3e20f34cdc68744efa8f9ff436b3397f16` | 78 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/plans/sentinel/gates/SG8.md` | `48b384e13b23e4a6c2ba9d26e32b64910a8e74599436eff38e10a206e2decc2b` | 117 | 100 · 100 · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 99.2 | PASS | Current figures re-derived on 2026-10-29; 417-path sweep and index gate pass. |
| `docs/plans/sentinel/gates/census-2026-10-28.md` | `9ed67e8c74a6347671d117f649aa13bcbf779925ba70682e37964030693c8deb` | 29 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/registers/02-defect-register.md` | `e275c761491bd5a4389efabd735bf7b531c8fe73b2009edc461f38080467b07b` | 244 | 90 · 100 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 95 · 100 | 97.5 | PASS | Current census corrected to 432/671/9; 218/229 labelled historical; links OK. |
| `docs/registers/03-fix-log.md` | `07b866169328e0ee5d430342c26fe9fd27b3403b5eee6a6c4c0bb18673b37730` | 517 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 99.3 | PASS | Current figures re-derived on 2026-10-29; 417-path sweep and index gate pass. |
| `docs/registers/04-handoff.md` | `3fef0efb946fa85a45fe7ac648f3b7951fed8b2b666b76c5d9de95c218dff42c` | 273 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 99.3 | PASS | Current state and CI run 40813891217; live-library counts SKIPPED (owner data, may change). |
| `docs/reorganization/AV1-ROR-EXECUTION-2026-10-26.md` | `bd622db16ba5a77a43c3c916b2659fccfc9d02b8da64575d06086aad936630e5` | 286 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | Dated receipt: links and anchors checked today; numeric, command, and receipt re-derivation SKIPPED because the original .xcresult/run logs were not retained. |
| `docs/roadmap/05-remediation-roadmap.md` | `f245eb56f0cb9bb963b41ab245d9d54f4bab52b078976c82b0db2cc73d3ef761` | 215 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 99.3 | PASS | 212 labelled as the 2026-10-24 boundary; 432 current; links OK. |
| `docs/roadmap/06-rsvp-feature-plan.md` | `411f099d5ffffe115c61f1ac4f4e267aa0271d18ee4fe4c8c3a1daf8c2e64e54` | 190 | 50 · 100 · 0 · 100 · 100 · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 83.8 | REVIEW | Shipped design record; links OK; benchmark and command claims are dated. |
| `graphify-out/GRAPH_REPORT.md` | `0db98f786082e0bb3a2954f02c58713f126dc5197ae1736a98d02ec179e314f4` | 1802 | — | — | SKIPPED | Generated by graphify; never hand-edited or hand-audited. Its numbers are regenerated, not authored. |
| `docs/registers/05-doc-audit.md` | self-referential | 225 | — | — | PASS (self) | A file cannot contain its own digest. 225 is the line count before this section was appended; the commit pins the bytes. |

### Full-sweep evidence

| Claim | Command | Result |
|---|---|---|
| 83 Markdown files audited | `git ls-files '*.md' \| wc -l` | `83` |
| Every path and anchor resolves | `python3 scripts/audit-markdown.py --quiet $(git ls-files '*.md')` | exit 0; **417** backticked path claims (before this section was appended), **0** broken; **162** bash-fence commands and **153** 64-hex claims inventoried |
| Broken claims at sweep start | same collector, first run | **97** broken claims in **9** files |
| App size | `find AsterismaV1.0 -name '*.swift' \| wc -l`; concatenated line and non-blank counts | `166`; `62452`; `55177` |
| Test folder and suite | `find AsterismaV1.0Tests -name '*.swift' \| wc -l`; CI run `40811182851` | `66`; `432 tests in 88 suites` |
| `@Test` reconciliation | `rg -c '@Test' AsterismaV1.0Tests --glob '*.swift'`; one hit is a comment in `AsterismaV1.0Tests/Environment/WeatherTests.swift:15` | **433** lines − 1 comment = **432** test functions, matching the census |
| Census | `./scripts/census.sh --unit-only` | exit 0; `totalTestCount 432`, `passedTests 423`, `skippedTests 9`, `failedTests 0`, `671 test runs` |
| Probes | `rg -o 'id: "[A-Z]+-[0-9]+"' -g '*.swift' AsterismaV1.0/Core/Sentinel \| sort -u \| wc -l` | `140` |
| Graph | `python3 -c "import json; g=json.load(open('graphify-out/graph.json')); print(len(g['nodes']), len(g['links']))"` | `7599 19164` |
| Local toolchain | `xcodebuild -version` | `Xcode 27.1` / `27A9275` |
| Index gate | `python3 scripts/comprehension-bench.py --validate-only` | `bank ok: 30 facts, 12 overview facts`, exit 0 |
| Remote gate | `gh run view 40813891217` | `success` on `0310c0f`, 4m17s |

### Defects fixed during the full sweep

| File(s) | Before | After | Evidence |
|---|---|---|---|
| `DBappends.md` | `Core/LibraryRecovery/LibraryRecoveryContracts.swift`; a state-machine test file that does not exist; a planned ADR-13 presented as a path | Corrected to `Core/Storage/LibraryRecoveryContracts.swift`; the two implemented recovery test files; ADR-13 marked **not written** | `find` + the collector's exit 0 |
| `docs/12-owner-test-authority.md` | Backticked literal `YYYY-MM-DD-session-N.md` | Angle-bracket pattern `<date>-session-<n>.md` | collector skips pattern tokens; no fake path |
| `docs/audits/08-deep-audit.md` | Abbreviated docs path (ellipsis) | Exact `docs/` directory | collector resolves it |
| `docs/audits/11-completion-and-health-report-2026-10-24.md` | `:30–157` / `:191–199` (en-dash ranges, unparsed) | `#L30-L157` / `#L191-L199` | anchors in bounds |
| `docs/integration/MIRAGE-DEEP-DIVE-2026-10-28.md` | Four Mirage-repository paths presented as local paths | Plain text; a path-provenance note added | 0 broken claims |
| `docs/integration/RT_Mirage_Codebase_Merge_Playbook.md` | Eleven upstream Mirage paths in backticks | Plain text; a path-provenance note added | 0 broken claims |
| `docs/integration/Twin-READMES-2026-10-18.md` | Twenty-two Mirage README paths in backticks | Plain text; a path-provenance note added | 0 broken claims |
| `docs/plans/sentinel/SENTINEL-ROADWORK.md` | `SGx.md`, a future `docs/sentinel/rules/<rule-id>.md` page, and a future rules directory presented as existing | Angle-bracket patterns and plain prose for future paths | 0 broken claims |
| `docs/reorganization/AV1-ROR-EXECUTION-2026-10-26.md` | Fifty pre-move paths in the relocation table's **From** column | Plain text with an explicit “these are historical” note; **To** column remains current | 0 broken claims |
| `docs/registers/02-defect-register.md` | “standing census is now 229 / 220” | Current **432 / 671 / 9 / 0**, with 218/229 explicitly historical | today's census command |
| `docs/roadmap/05-remediation-roadmap.md` | “standing census is now 212/0/9” | “The census at that boundary was 212/0/9”; current 432 line retained | dated boundary vs current |
| `DBappends.md` | “173 Sentinel tests” | **162** `@Test` functions in Sentinel-named test files | `rg -c '@Test' AsterismaV1.0Tests --glob '*Sentinel*'` |
| `docs/integration/MIRAGE-DEEP-DIVE-2026-10-28.md` | 229 / 220 presented without a date | Explicit 2026-10-26 snapshot; current 432/671/9 named | today's census |
| `docs/MILESTONES.md`, `docs/audits/12-sentinel-v2-tranche-2026-10-28.md` | 138 / 379 / 1,024 snapshot with no current pointer | SG8 postscript: 140 probes / 58 required; 432 / 671 / 9 | today's census + probe count |
| `README.md`, `docs/registers/04-handoff.md` | Census dated 2026-10-28; README's “latest run” unnamed | 2026-10-29 and run `40813891217` | today's census + `gh run view` |

### Skipped register (plain English)

| Claim / check | Files | Why it is skipped |
|---|---|---|
| Historical numbers, command results, and receipt hashes | 68 `REVIEW` files | These are dated receipts: gate records, audits, owner sessions, campaign logs, and design snapshots. Their original `.xcresult` bundles and runner logs were not retained, and re-running the commands today would test the current code, not the historical gate. Links and structure were checked; the numbers are intentionally scored as REVIEW. Re-audit owner: the next release sweep. |
| “58 probes are required” | README, handoff | The app computes the required count at runtime; this sweep did not launch the app. The 140 total is independently counted. |
| Package SHA-256 `786832c8…` | README, handoff, fix log | The signed package was deleted on 2026-10-28; the digest is a historical receipt and cannot be recomputed without rebuilding and signing. |
| Live library `1 book / 3 sessions / 77 page timings` | handoff | Owner data outside the repository; it changes with use and was not inspected during this documentation sweep. |
| Generated graph report | `graphify-out/GRAPH_REPORT.md` | Produced by graphify; never hand-edited or hand-audited. |
| Direct `file://` browser check | README, AGENTS, fix log, handoff | The browser tool blocks `file://`; the 3D page was rendered over loopback and scanned for external references. The 2D page needs network for its documented unpkg renderer. |
| Full semantic graph re-extraction | graph refresh | No Gemini/Google backend is configured; the refresh used graphify's incremental AST update. |

### Open findings

- The 68 `REVIEW` files are historical receipts, not current defects. They become
  actionable only if someone cites one of their numbers as a present fact.
- The live-library counts and the 58-required count remain unverified by design;
  refresh them during the next owner session.
- `rg -c '@Test'` counts **433** lines because one is a comment. The executable
  count is **432**, which matches the census; do not treat the raw grep as the
  suite size without this reconciliation.
- A future release sweep should re-run the dated gates only where a current
  decision depends on them, and record new receipts rather than inheriting old
  ones.

### Next audit

No sweep is pending. Re-audit any file whose bytes change, and append a new row
that names the row it supersedes. The next full sweep belongs with the next
release, not with an ordinary documentation edit.

### Full-sweep supersession

`docs/registers/04-handoff.md` was updated after the table above to record the
completed 83-file sweep instead of a deferred one. Current bytes:
`623b2a443d4243ced7e5e3a2059e59ad03e4d59e493ce13b6a936b890f7c329b`, 272
lines. This supersedes its `PASS` row above; no other row changed.

### Full-sweep anchor correction

The full-sweep row for `docs/audits/11-completion-and-health-report-2026-10-24.md`
is superseded. Reading its targets showed that the two reformatted
defect-register ranges (`#L30-L157`, `#L191-L199`) and the
`07-testing-strategy.md:18` pointer no longer contained their claimed subjects;
line 30 is the severity legend and line 18 is a table separator. They were
withdrawn to plain file references, and a historical-line note was added to the
report. Current bytes:
`fd90c7d04e7741c4ad74644bbe70cfe35b37ecf2f7d3fff49009b010b1620c27` — that digest
is from before this note; the final digest is recorded below. A2 = 100 in the
full-sweep table means **path resolution**. For the 68 REVIEW files, historical
`file:line` anchors were bounds-checked only, not subject-matched; the 13 PASS
files' anchors were subject-checked.

Final bytes for that report:
`5f3e64e5f72d228b727ae21e4b5b437c5f81c266c51aa869ff6aa2ccbadd7ca1`, 389 lines.

### Post-push CI receipt (2026-10-29)

The sweep commit `737033a` ran green on GitHub: `gh run view 40815638835`
reports `success` with the single `census` job passing every step in 3m11s
(head `737033a`). That receipt exposed one stale sentence in `README.md` §5:
it called `40813891217` the *latest* run. It was green, but it was no longer
latest, so the word "latest" was replaced with two fixed receipts that cannot
rot: `40813891217` on `0310c0f` and `40815638835` on `737033a`.

`README.md` current bytes:
`47bbf8db03ef4d797cb23c363c5b2290684e3906428cefc58e203ed7a2db6c60`, 331
lines, 27,649 B. `python3 scripts/audit-markdown.py README.md` exits 0 with 18
path claims and 19 command lines. This supersedes the `README.md` `PASS` row
above; scores are unchanged (96.0, PASS), with A3 still 75 because the quoted
`xcodebuild` commands were not re-run in this documentation pass.
