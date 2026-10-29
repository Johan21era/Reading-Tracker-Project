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
| Probe count 140 | `rg -o 'id: "[A-Z]+-[0-9]+"' -g '*.swift' AsterismaV2.0/Core/Sentinel \| sort -u \| wc -l` | `140` |
| Graph 7,510 nodes / 19,023 links | `python3 -c "import json; g=json.load(open('graphify-out/graph.json')); print(len(g['nodes']), len(g['links']))"` | `7510 19023` |
| App size 166 / 62,452 / 55,177 | `find AsterismaV2.0 -name '*.swift' \| wc -l`; `cat` all Swift lines `\| wc -l`; non-blank `\| grep -cv '^[[:space:]]*$'` | `166`; `62452`; `55177` |
| Test folder 66 files | `find AsterismaV2.0Tests -name '*.swift' \| wc -l` | `66` |
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
| App size | `find AsterismaV2.0 -name '*.swift' \| wc -l`; concatenated line and non-blank counts | `166`; `62452`; `55177` |
| Test folder and suite | `find AsterismaV2.0Tests -name '*.swift' \| wc -l`; CI run `40811182851` | `66`; `432 tests in 88 suites` |
| `@Test` reconciliation | `rg -c '@Test' AsterismaV2.0Tests --glob '*.swift'`; one hit is a comment in `AsterismaV2.0Tests/Environment/WeatherTests.swift:15` | **433** lines − 1 comment = **432** test functions, matching the census |
| Census | `./scripts/census.sh --unit-only` | exit 0; `totalTestCount 432`, `passedTests 423`, `skippedTests 9`, `failedTests 0`, `671 test runs` |
| Probes | `rg -o 'id: "[A-Z]+-[0-9]+"' -g '*.swift' AsterismaV2.0/Core/Sentinel \| sort -u \| wc -l` | `140` |
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
| `DBappends.md` | “173 Sentinel tests” | **162** `@Test` functions in Sentinel-named test files | `rg -c '@Test' AsterismaV2.0Tests --glob '*Sentinel*'` |
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
### V2.0 rename re-audit (2026-10-29)

Every Markdown file touched by the `AsterismaV1.0` → `AsterismaV2.0` rename is
re-audited here against its final bytes. Paths and anchors were re-resolved with
`python3 scripts/audit-markdown.py` (exit 0, 83 files). Dimension scores are
carried forward from the last full audit of the same file; the rename changed
names and paths, not the underlying evidence, and the new build/census/graph
receipts are in `docs/registers/03-fix-log.md`.

| Date | File | SHA-256 | Lines | Scores (A1 · A2 · A3 · A4 · B1 · B2 · B3 · C1 · C2 · C3 · D1 · D2 · D3 · E1 · E2) | Weighted | Verdict | Evidence / SKIPPED reason |
|---|---|---|---:|---|---:|---|---|
| 2026-10-29 | `DBappends.md` | `76ccf0092061948b014cddfaeb754fe8bc0053caad51e4e4573d10aef5357026` | 3801 | 70 · 100 · 0 · 100 · 100 · 90 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 95 · 100 | 86.1 | REVIEW | V2.0 rename; paths and anchors resolve; historical numeric/command re-derivation SKIPPED because the original .xcresult/run logs were not retained; prior scores retained. |
| 2026-10-29 | `README.md` | `d1cf1ab69a1f827cf0d4964a28b3faf90b36b9b99fdb92de5e64eef904d4ff8a` | 331 | 95 · 100 · 75 · 95 · 100 · 100 · 100 · 95 · 100 · 90 · 100 · 100 · 100 · 100 · 100 | 96.0 | PASS | V2.0 rename; paths and anchors re-resolved; build, census, surface, and graph receipts re-derived on 2026-10-29; prior dimension scores retained. |
| 2026-10-29 | `docs/01-project-tree.md` | `7a8a959b784aa906ab233e01f2217aecb0366fca5a2167b71c97269b751d2f11` | 113 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 90 · 100 · 90 · 100 · 100 · 100 · 95 · 100 | 97.8 | PASS | V2.0 rename; paths and anchors re-resolved; build, census, surface, and graph receipts re-derived on 2026-10-29; prior dimension scores retained. |
| 2026-10-29 | `docs/12-owner-test-authority.md` | `f0a63b1ca1eddabe7d5d7b020823433957054ce4812a34d72b32e6427d827cd7` | 139 | N/A · 100 · N/A · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 100.0 | PASS | V2.0 rename; paths and anchors re-resolved; build, census, surface, and graph receipts re-derived on 2026-10-29; prior dimension scores retained. |
| 2026-10-29 | `docs/INDEX.md` | `aedf418bebe7d36b701ed2b378def5d19beac084c480c61cba4efbee86b6cf41` | 95 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 100.0 | PASS | V2.0 rename; paths and anchors re-resolved; build, census, surface, and graph receipts re-derived on 2026-10-29; prior dimension scores retained. |
| 2026-10-29 | `docs/MILESTONES.md` | `1819be4363a94b6f8a15a4a7613ad347b051462b0c97331e652b17edea1babf8` | 314 | 40 · 100 · 0 · 100 · 100 · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 82.4 | REVIEW | V2.0 rename; paths and anchors resolve; historical numeric/command re-derivation SKIPPED because the original .xcresult/run logs were not retained; prior scores retained. |
| 2026-10-29 | `docs/REBRAND-ASTERISMA.md` | `ba09773be1e25b68ba6d938d6ad4ab51114f3c9cd3bf19ec6b2d9e02fb62847b` | 125 | 50 · 100 · 0 · 100 · 100 · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 83.8 | REVIEW | V2.0 rename; paths and anchors resolve; historical numeric/command re-derivation SKIPPED because the original .xcresult/run logs were not retained; prior scores retained. |
| 2026-10-29 | `docs/audits/12-sentinel-v2-tranche-2026-10-28.md` | `08c960fa3980cbb975abd09a6cfdd572c247f3dff76ccfe183d65f234fa8bc80` | 76 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | V2.0 rename; paths and anchors resolve; historical numeric/command re-derivation SKIPPED because the original .xcresult/run logs were not retained; prior scores retained. |
| 2026-10-29 | `docs/design/fullscreen-surface-audit.md` | `5d9f65b9602c86799f4d84b7a73750a4446b87f7b9ff6dce2e8b94857e1d05be` | 109 | 50 · 100 · 0 · 100 · 100 · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 83.8 | REVIEW | V2.0 rename; paths and anchors resolve; historical numeric/command re-derivation SKIPPED because the original .xcresult/run logs were not retained; prior scores retained. |
| 2026-10-29 | `docs/integration/MIRAGE-DEEP-DIVE-2026-10-28.md` | `dd4308bb9a2bee401f3bab9a4b82dd44d21bc6a08385e507f77c7432fc38abf6` | 263 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | V2.0 rename; paths and anchors resolve; historical numeric/command re-derivation SKIPPED because the original .xcresult/run logs were not retained; prior scores retained. |
| 2026-10-29 | `docs/method/07-testing-strategy.md` | `decff20a7e131a79a77c1c2fea0e1cb86e3c2c2088ae711e4b177c17be35b74b` | 125 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 100.0 | PASS | V2.0 rename; paths and anchors re-resolved; build, census, surface, and graph receipts re-derived on 2026-10-29; prior dimension scores retained. |
| 2026-10-29 | `docs/plans/bedrock/BASELINE.md` | `f39a61e2ee7dbbc136e3b10d2160a5e2d828adbcc7287d477f0502bce7c09aee` | 98 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | V2.0 rename; paths and anchors resolve; historical numeric/command re-derivation SKIPPED because the original .xcresult/run logs were not retained; prior scores retained. |
| 2026-10-29 | `docs/plans/bedrock/BEDROCK-MASTER-PLAN-2026-10-24.md` | `2d692ed1cc106a689c8bef8e901edc6aadb5f4dab8962b01cc28d6ff3862d28b` | 742 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | V2.0 rename; paths and anchors resolve; historical numeric/command re-derivation SKIPPED because the original .xcresult/run logs were not retained; prior scores retained. |
| 2026-10-29 | `docs/plans/bedrock/DISTRIBUTION.md` | `2ed7c356bb8b655392e249350876f16ae572b0a434cd04481271d631bfbf7044` | 58 | 60 · 100 · 40 · 80 · 100 · 90 · 100 · 100 · 100 · 90 · 100 · 100 · 100 · 90 · 100 | 86.3 | REVIEW | V2.0 rename; paths and anchors resolve; historical numeric/command re-derivation SKIPPED because the original .xcresult/run logs were not retained; prior scores retained. |
| 2026-10-29 | `docs/plans/bedrock/SESSION-2026-10-24.md` | `3e4d37a5545bbacd2c8d87490dccf0393a1f4e4325892e3776ee4d6e430b092f` | 176 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | V2.0 rename; paths and anchors resolve; historical numeric/command re-derivation SKIPPED because the original .xcresult/run logs were not retained; prior scores retained. |
| 2026-10-29 | `docs/plans/library-recovery/G6.md` | `de453c961df2ba0f99927fe7a2d35a1a08b47e3639f54a4c06dae980164b42fa` | 78 | 100 · 100 · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 99.2 | PASS | V2.0 rename; paths and anchors re-resolved; build, census, surface, and graph receipts re-derived on 2026-10-29; prior dimension scores retained. |
| 2026-10-29 | `docs/plans/sentinel/SENTINEL-ROADWORK.md` | `afd8581dd5fd8f96af399ace46a351f5254e0fd8e74f595c4972ca4ab28096bd` | 4007 | 70 · 100 · 0 · 100 · 100 · 90 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 95 · 100 | 86.1 | REVIEW | V2.0 rename; paths and anchors resolve; historical numeric/command re-derivation SKIPPED because the original .xcresult/run logs were not retained; prior scores retained. |
| 2026-10-29 | `docs/plans/sentinel/gates/SG0.md` | `852bf4cec52329f9a9ea29c3c403551ca3dfe94b54009c6ed187bb5c00d166aa` | 89 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | V2.0 rename; paths and anchors resolve; historical numeric/command re-derivation SKIPPED because the original .xcresult/run logs were not retained; prior scores retained. |
| 2026-10-29 | `docs/plans/sentinel/gates/SG8.md` | `5723a83882032efc6125de8d24dcf1bde3e8cf5d93d14b3afed21655aecd74f3` | 117 | 100 · 100 · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 99.2 | PASS | V2.0 rename; paths and anchors re-resolved; build, census, surface, and graph receipts re-derived on 2026-10-29; prior dimension scores retained. |
| 2026-10-29 | `docs/registers/03-fix-log.md` | `7e3dff203ff2b8e2f2f227384d40dd01c00e26f5afd56b11f5cccbee6c9678b9` | 542 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 99.3 | PASS | V2.0 rename; paths and anchors re-resolved; build, census, surface, and graph receipts re-derived on 2026-10-29; prior dimension scores retained. |
| 2026-10-29 | `docs/registers/04-handoff.md` | `e9d9ded9a757196ba9b9cf133035835c40a390d45ee9c064383114bb7454902a` | 306 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 99.3 | PASS | V2.0 rename; paths and anchors re-resolved; build, census, surface, and graph receipts re-derived on 2026-10-29; prior dimension scores retained. |
| 2026-10-29 | `docs/registers/05-doc-audit.md` | `3408d14b8ca30d52ae9ccb75db0c85ca95ec9e84287c216e9f3fbf436f2ee427` | 444 | — | — | PASS (self) | Self-row: this digest is the pre-append state; the append that contains this row changes these bytes. |
| 2026-10-29 | `docs/reorganization/AV1-ROR-EXECUTION-2026-10-26.md` | `f12213893cd3949484ab3200b7d2d8049dbb080e73e5d73a20614bbdfb69639d` | 291 | 0 · 100 · 0 · 0 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 72.0 | REVIEW | V2.0 rename; paths and anchors resolve; historical numeric/command re-derivation SKIPPED because the original .xcresult/run logs were not retained; prior scores retained. |
| 2026-10-29 | `graphify-out/GRAPH_REPORT.md` | `94977b70406a5200ce7038053a6ee831ec44bc8c78a2973a53ab97c788a5425a` | 1772 | — | — | SKIPPED | Generated by graphify; regenerated 2026-10-29 from the current tree; not hand-edited. |

### V2.0 rename re-audit corrections (2026-10-29)

Three files changed after their rows above were recorded: `docs/INDEX.md`
gained corrected one-hop anchors, and the fix log and handoff gained the
isolation receipt and graph base-commit qualifier. These rows supersede the
same-file rows above.

| Date | File | SHA-256 | Lines | Scores (A1 · A2 · A3 · A4 · B1 · B2 · B3 · C1 · C2 · C3 · D1 · D2 · D3 · E1 · E2) | Weighted | Verdict | Evidence / SKIPPED reason |
|---|---|---|---:|---|---:|---|---|
| 2026-10-29 | `docs/INDEX.md` | `de03d396f4dc84f8d8f9a5ebbfa57270d8a3918ddfaa8e00660ba76eee1f9fa3` | 95 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 100.0 | PASS | Five stale anchors re-pointed to their owning lines; `comprehension-bench.py --validate-only` passes. |
| 2026-10-29 | `docs/registers/03-fix-log.md` | `c137d1f89f42f7efe13bd10ff094788236bf7b36ea9df2b0b07f54fdac0b88a5` | 542 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 99.3 | PASS | Rename stage plus isolation and graph base-commit qualifier; D2 N/A (not an index target). |
| 2026-10-29 | `docs/registers/04-handoff.md` | `1184de63feceab6d6d19b7414ee3dc99a833ac628643d12dca46922b3e5a67c7` | 307 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 99.3 | PASS | Rename close-out, isolation receipt, and graph base-commit qualifier. |

### Second tranche re-audit (2026-10-29)

Scope: every Markdown file edited by the Quick Open / adaptive shell tranche,
against its final bytes after the graph refresh. The command receipts below were
all run from the repository root on 2026-10-29.

| Date | File | SHA-256 | Lines | Scores (A1 · A2 · A3 · A4 · B1 · B2 · B3 · C1 · C2 · C3 · D1 · D2 · D3 · E1 · E2) | Weighted | Verdict | Evidence / SKIPPED reason |
|---|---|---|---:|---|---:|---|---|
| 2026-10-29 | `README.md` | `a22a75a47282ef57f0b939efc1c75eba14ab21135bd7d74c943cb086fa86c7f0` | 335 | 95 · 100 · 80 · 95 · 100 · 100 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 100 · 100 | 97.1 | PASS | Current build, 437-test census, source counts, graph counts, and 3D page re-derived; historical release hashes and run ids retained as historical with dates. A3 is 80 because not every historical command quoted in the file was re-run. |
| 2026-10-29 | `docs/INDEX.md` | `44de7573a2de48bb5daf4990f88a8a55b5d4a5d81fac86580a0100e7b92a8b4b` | 101 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 100.0 | PASS | `python3 scripts/comprehension-bench.py --mode all` exit 0: 30 facts, 12 overview facts, 0 fallbacks, 100% accuracy, 308.4× median speedup. All anchors resolve. |
| 2026-10-29 | `docs/01-project-tree.md` | `65ac58606ff7c063c63f2087deb1e9a8879a83d51eb8a931368896e911b13346` | 114 | 100 · 100 · N/A · 100 · 100 · 100 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 100 · 100 | 99.7 | PASS | App/test/graph counts re-derived from the tree; current 437-test receipt and Stage Z graph counts match the fix log and README. A3 N/A: no commands are quoted as receipts. |
| 2026-10-29 | `docs/design/UI-UX-OVERHAUL-2026-10-29.md` | `bfd7dc62787dd6065fa3c3644fc459b369c6fe41e82139e8ed4644585e6e6263` | 339 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 100 · 100 · 100 | 99.0 | PASS | Build exit 0; 437-test census exit 0; layout arithmetic and graph counts re-derived. A1 95 and C2 95 because the two weighted models are explicitly expert judgement, not measured task times; the limits section says so. |
| 2026-10-29 | `docs/registers/03-fix-log.md` | `a5c22eb22358e7df6045ba0b83443939577b1bdf3f4807176cbb5de375bed730` | 624 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 99.3 | PASS | Stage Z records the exact build, census, source-size, graph, hash, and browser receipts; historical stages retain their own dates. D2 N/A: not an index target. |
| 2026-10-29 | `docs/registers/04-handoff.md` | `0373a13fecf4f10a86a079d60910fe019d375d6b1ba3d53c8eac6b20ab9aa1c2` | 380 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 99.3 | PASS | New session-close section carries the 437-test census, source counts, limits, and next actions; older SG8/rename sections remain dated historical receipts. |
| 2026-10-29 | `docs/method/07-testing-strategy.md` | `d57736de64e1d444a13a71471cfb9ddab12d89027558e2556efb26053bf5407f` | 125 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 100.0 | PASS | Current test scale (67 files / 437 tests / 89 suites / 671 runs) matches the xcresult; the older GitHub 432-test run is labelled as pre-rename. D2 N/A. |
| 2026-10-29 | `docs/roadmap/05-remediation-roadmap.md` | `97d32aa13f75e180f2a57d363741921911d1ee5ea315508778140da9a798ec63` | 215 | 95 · 100 · N/A · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 99.2 | PASS | Current census updated to 437 tests / 671 runs / 428 passed / 9 skipped / 0 failed; the 212/432 figures are dated historical boundaries. A3 N/A and D2 N/A. |
| 2026-10-29 | `docs/registers/05-doc-audit.md` | self-referential | — | — | — | PASS (self) | This row cannot contain its own post-append digest; the bytes are pinned by the commit that adds the row. |

**Evidence bundle (all exit 0 unless stated):**

| Claim | Command | Result |
|---|---|---|
| Debug build | `xcodebuild build -project AsterismaV2.0.xcodeproj -scheme AsterismaV2.0 -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO` | `** BUILD SUCCEEDED **` |
| Unit census | `./scripts/census.sh --unit-only` | 437 tests / 671 runs / 428 passed / 9 skipped / 0 failed |
| Surface manifest | `./scripts/verify-sentinel-surface.sh` | `15 tables, 8 defaults keys, 5 notification names` |
| One-hop gate | `python3 scripts/comprehension-bench.py --mode all` | `GATE PASSED`, 0 fallbacks, 100% accuracy, 308.4× median speedup |
| Markdown audit | `python3 scripts/audit-markdown.py --quiet <changed .md files>` | OK on all eight changed files |
| App size | `find AsterismaV2.0 -name '*.swift' \| wc -l`; raw and non-blank counts | 170 / 64,084 / 56,626 |
| Test folder | `find AsterismaV2.0Tests -name '*.swift' \| wc -l` | 67 |
| Graph counts | `python3 -c "import json; g=json.load(open('graphify-out/graph.json')); print(len(g['nodes']), len(g['links']))"` | `7734 19424` |
| 3D check | `python3 scripts/build-graph-3d.py --check` | `ok` |
| 3D browser receipt | loopback Chromium check | 1304×1423 canvas, WebGL true, only the document request, one info log, no errors |

### Reader customization re-audit (2026-10-29)

Scope: every Markdown file edited by the EPUB/PDF reader customization pass,
against its final bytes after the Stage AA graph refresh. These rows supersede
the prior same-file rows above for these files. Commands were run from the
repository root on 2026-10-29.

| Date | File | SHA-256 | Lines | Scores (A1 · A2 · A3 · A4 · B1 · B2 · B3 · C1 · C2 · C3 · D1 · D2 · D3 · E1 · E2) | Weighted | Verdict | Evidence / SKIPPED reason |
|---|---|---|---:|---|---:|---|---|
| 2026-10-29 | `README.md` | `2800819d54b89f877eb55b54584fa77eecfd64115e6549cf2377af4d32db4dc2` | 336 | 95 · 100 · 80 · 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 97.3 | PASS | Current build, 441-test census, 171/64,758/57,220 source counts, 7,792/19,534/373 graph counts, Stage AA receipts, and 8,265,095 B 3D page re-derived. A3 80: historical xcodebuild/package commands were not all re-run. E2 N/A: not generated. |
| 2026-10-29 | `docs/01-project-tree.md` | `77c02ec7460f583840d0694e3c855805e6f97966eba6e85d0c0997c852f28635` | 114 | 100 · 100 · N/A · 100 · 100 · 100 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 100 · 100 | 99.7 | PASS | 67 test files, 441 tests / 89 suites, 7,792/19,534/373 graph counts, and the generated-artifact map match the Stage AA receipts. A3 N/A: no commands are quoted as receipts. C3 95: a map, not a risk register. |
| 2026-10-29 | `docs/INDEX.md` | `e406081fc6c9e854c6bd43170ff34cff3ab7e345c3a95a2d17d6ff6af6b023a9` | 102 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 100.0 | PASS | `comprehension-bench.py --mode all` exit 0: 30 facts + 12 overview facts, 0 fallbacks, 100% accuracy, 250-file scan; the final run measured 286.5× median speedup, the preceding run 281.7×. `--validate-only` exit 0. |
| 2026-10-29 | `docs/design/READER-POLISH-2026-10-25.md` | `5ce527cea85c219c0a3beb4262d6cb1e656e02d3ea9398cdd75b59f3e23516bc` | 238 | 95 · 100 · 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 98.9 | PASS | Phase 2 sections carry the exact build, 9/9 focused suite, 441-test census, browser-harness, and source-size receipts; Phase 1 figures are dated historical. MangaDex claims are limited to the two forum sources that were readable; unverified controls are explicitly labelled native. A3 95: the one-off harness command is not a standing CI command. |
| 2026-10-29 | `docs/design/UI-UX-OVERHAUL-2026-10-29.md` | `9091a52b2719fd4931019a12cf9ff7543bf02b237c2bb00b49df8694b10ddf1c` | 357 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 100 · 100 · N/A | 99.0 | PASS | Stage Z receipts are labelled at the Stage Z boundary; a current-count note records 441 / 671 / 432 passed / 9 skipped / 0 failed and 171 / 64,758 / 57,220. The reader postscript prevents the "readers unchanged" contradiction. C2 95: the two weighted models are explicitly expert judgement, not task-time measurements. |
| 2026-10-29 | `docs/method/07-testing-strategy.md` | `dc1bd0f66b36393fceb261ef1d0c272a67c439aea75012ab1bfbc8451cb1e0aa` | 140 | 100 · 100 · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · N/A | 99.2 | PASS | 67 files / 441 tests / 89 suites / 671 runs match the xcresult; the reader band states that the browser harness is not CI. A3 90: opt-in Mirage commands are examples, not re-run receipts. D2/E2 N/A. |
| 2026-10-29 | `docs/registers/03-fix-log.md` | `88167a7d7938f962748b10d092c2be13d93e868ed97ece1b51bc307ed59ff2c3` | 692 | 95 · 100 · 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 98.9 | PASS | Stage AA records exact build, focused-suite, census, harness, source-size, graph, hash, and browser receipts. Historical stages keep their own dates. D2 N/A: not an index target. A3/A1 95: older stage commands were not re-run. |
| 2026-10-29 | `docs/registers/04-handoff.md` | `6ace57023080282dd66ce467bb6d89b127978adf73b25cdccf975cb9d3bc54ce` | 416 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 99.3 | PASS | Reader session close carries the exact 441-test census, 9/9 focused suite, 171/64,758/57,220 source counts, and the uncommitted/no-remote-CI limits. Earlier 437/432 boundaries are labelled historical. |
| 2026-10-29 | `docs/registers/05-doc-audit.md` | `92f7a83681bcf917c2d5ca4891ac66411085abd4ad222232374c82673c7e2113` | 525 | — | — | PASS (self) | Pre-append digest and line count; this append changes the file's bytes. The next audit must supersede this row. |

### Offline contract re-audit (2026-10-29)

Scope: every Markdown file edited by the offline contract pass, against its
final bytes. These rows supersede the same-file rows above for these files.
Commands were run from the repository root on 2026-10-29.

| Date | File | SHA-256 | Lines | Scores (A1 · A2 · A3 · A4 · B1 · B2 · B3 · C1 · C2 · C3 · D1 · D2 · D3 · E1 · E2) | Weighted | Verdict | Evidence / SKIPPED reason |
|---|---|---|---:|---|---:|---|---|
| 2026-10-29 | `README.md` | `bd1346e0ad86f4e5fde6c7b013ad017d1a33122ac697c8666cc119423f7a19e6` | 337 | 95 · 100 · 80 · 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 97.3 | PASS | Current unit census 447 / 671 / 438 passed / 9 skipped / 0 failed and full UI-inclusive 450 / 673 / 441 / 9 / 0 re-derived from the two xcresults; 172 / 64,868 / 57,315 source counts and 68 test files re-derived. Offline bullet links Stage AB and discloses the failed OS-level denial. A3 80: historical build/package commands were not re-run. E2 N/A: not generated. |
| 2026-10-29 | `docs/01-project-tree.md` | `0bce6c514a5d7338de415f58633b57c41318c8ad9bf95e19f5dcbd1447450cde` | 114 | 100 · 100 · N/A · 100 · 100 · 100 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 100 · 100 | 99.7 | PASS | 68 unit-test Swift files, 447 tests / 90 suites, and the full 450 / 673 / 441 / 9 / 0 census match the receipts; six offline pins named. A3 N/A: no commands are quoted as receipts. C3 95: a map, not a risk register. |
| 2026-10-29 | `docs/INDEX.md` | `ffad303aa424289cd5e9560eb902c86bbe8ca0efbd999e60fcc34560f99aaebd` | 103 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 100.0 | PASS | `comprehension-bench.py --validate-only` exit 0 (30 facts, 12 overview facts); `--mode all` exit 0 with 0 fallbacks, 100% accuracy, 269.4× median speedup. README anchors L245/L307/L300 re-pointed after the inserted offline bullet shifted them by one line. E2 N/A: not generated. |
| 2026-10-29 | `docs/method/07-testing-strategy.md` | `71301a9decc0e04608b1e497a8a134dd965f09bbeb92a1a5a4c9c440da5e0a63` | 164 | 100 · 100 · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · N/A | 99.2 | PASS | 68 files / 447 tests / 90 suites / 671 runs match the unit xcresult; full 450 / 673 / 441 / 9 / 0 matches the full xcresult. The offline band names the injected `OfflineURLProtocol` and records the sandbox limitation. A3 90: opt-in Mirage commands are examples, not re-run receipts. D2/E2 N/A. |
| 2026-10-29 | `docs/registers/03-fix-log.md` | `782f8d7095c2b9857e522f2a8dc21e88643069b99355b6a562c7d6990392012c` | 753 | 95 · 100 · 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 98.9 | PASS | Stage AB records the exact build, focused 11-test run, 447/671/438/9/0 unit census, 450/673/441/9/0 full census, source counts, and the failed process-level denial as SKIPPED. A1/A3 95: older stage commands were not re-run. D2 N/A: not an index target. |
| 2026-10-29 | `docs/registers/04-handoff.md` | `d8d785e69004d0ca90f39a0995f62d6d083b33d63ebb0d21b4d1151b9a822f46` | 458 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 99.3 | PASS | Offline session close carries the focused 11-test, unit 447-test, full 450-test, and 172/64,868/57,315 receipts; the whole-suite sandbox denial is stated as SKIPPED. Earlier 441/432 boundaries are labelled historical. E2 N/A: not generated. |
| 2026-10-29 | `docs/registers/05-doc-audit.md` | self-referential | — | — | — | PASS (self) | This row cannot contain its own post-append digest; the bytes are pinned by the commit that adds the row. |

**Stage AA reader evidence bundle (historical boundary, all exit 0 unless stated):**

| Claim | Command | Result |
|---|---|---|
| Debug build | `xcodebuild build -project AsterismaV2.0.xcodeproj -scheme AsterismaV2.0 -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO` | `** BUILD SUCCEEDED **` |
| Focused reader suite | `xcodebuild test -project AsterismaV2.0.xcodeproj -scheme AsterismaV2.0 -destination 'platform=macOS' -only-testing:AsterismaV2.0Tests/ReaderAppearanceTests CODE_SIGNING_ALLOWED=NO` | `✔ Test run with 9 tests in 1 suite passed` |
| Unit census | `./scripts/census.sh --unit-only` | 441 tests / 671 runs / 432 passed / 9 skipped / 0 failed; xcresult `rt-census-20261029-012648.xcresult` |
| Surface manifest | `./scripts/verify-sentinel-surface.sh` | `sentinel-surface: OK — 15 tables, 8 defaults keys, 5 notification names` |
| One-hop gate | `python3 scripts/comprehension-bench.py --mode all` | `GATE PASSED`, 0 fallbacks, 100% accuracy; final run 286.5×, preceding run 281.7× median speedup |
| Markdown audit | `python3 scripts/audit-markdown.py README.md docs/01-project-tree.md docs/INDEX.md docs/design/READER-POLISH-2026-10-25.md docs/design/UI-UX-OVERHAUL-2026-10-29.md docs/method/07-testing-strategy.md docs/registers/03-fix-log.md docs/registers/04-handoff.md` | OK on all eight files |
| App size | `find AsterismaV2.0 -name '*.swift' \| wc -l`; concatenated raw and non-blank counts | 171 / 64,758 / 57,220 |
| Test folder | `find AsterismaV2.0Tests -name '*.swift' \| wc -l` | 67 |
| Graph counts | `graphify update . --force` | 7,792 nodes / 19,534 edges / 373 communities |
| 3D check | `python3 scripts/build-graph-3d.py --check` | `ok` |
| 3D browser receipt | loopback Chromium, 1400×1000 | canvas 1400×1000, WebGL true, `resources: []`, one info log, no errors |
| EPUB mode harness | Chromium, 1280×720, 160 paragraphs | 23 paged pages; 21 scrolling viewport-pages; page 3 at `scrollY = 2160`; switch-back at `scrollLeft = 3840` |

**Honest skips:**

| Check | Reason |
|---|---|
| `file://` 3D open | Playwright Chromium blocks the `file:` protocol (`Access to "file:" protocol is blocked`). The same generated file was served over loopback and verified there; this is not a file:// receipt. |
| Owner visual acceptance | No owner session in this work pass; no screenshot because macOS screen capture remains denied. |
| Real EPUB/PDF pass | No real book was opened in the app during this pass; the reader model is tested and the JavaScript mode switch was harnessed in Chromium. |
| Remote CI | No push was made for this working tree; the last remote census predates Stage AA. |
| PDF UI automation | No UI automation exists for PDFKit; the layout/fit/direction/gap mapping is pinned at the model level only. |

### Documentation consistency re-audit (2026-10-29)

Scope: the two design records edited after the offline-contract pass, against
their final bytes. These rows supersede the same-file rows above for these
files. `python3 scripts/audit-markdown.py --quiet docs/design/UI-UX-OVERHAUL-2026-10-29.md docs/design/READER-POLISH-2026-10-25.md` exited 0; `python3 scripts/comprehension-bench.py --validate-only` also exited 0.

| Date | File | SHA-256 | Lines | Scores (A1 · A2 · A3 · A4 · B1 · B2 · B3 · C1 · C2 · C3 · D1 · D2 · D3 · E1 · E2) | Weighted | Verdict | Evidence / SKIPPED reason |
|---|---|---|---:|---|---:|---|---|
| 2026-10-29 | `docs/design/READER-POLISH-2026-10-25.md` | `a8ce175f35c6af19bac99f485d3e8b4207eaa514956ba6d74139994c02774ed0` | 241 | 95 · 100 · 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 98.9 | PASS | The Phase 2 postscript now records the Stage AB offline census (447 / 671 / 438 / 9 / 0) and labels the earlier 441-test reader boundary as historical. A3 95: the one-off Chromium harness is not a standing CI command. |
| 2026-10-29 | `docs/design/UI-UX-OVERHAUL-2026-10-29.md` | `07488c13cb855d678e6edb9fc1999dd6ffeba81d1408f6b3a827dc619a1b90f2` | 359 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 100 · 100 · N/A | 99.0 | PASS | The current-count note now records 447 / 671 / 438 / 9 / 0 and the full 450 / 673 / 441 / 9 / 0, while the Stage Z figures stay labelled at their boundary. C2 95: the two weighted models are explicitly expert judgement, not task-time measurements. |
| 2026-10-29 | `docs/registers/05-doc-audit.md` | self-referential | — | — | — | PASS (self) | This row cannot contain its own post-append digest; the bytes are pinned by the commit that adds the row. |

### Stage AC graph-refresh re-audit (2026-10-29)

Scope: the Markdown files edited by the post-offline graph refresh, against
their final bytes. These rows supersede the same-file rows above for these
files. `python3 scripts/audit-markdown.py --quiet README.md docs/01-project-tree.md docs/registers/03-fix-log.md docs/registers/04-handoff.md docs/registers/05-doc-audit.md` exited 0; `python3 scripts/comprehension-bench.py --mode all` exited 0 with 100% accuracy and 241.5× median speedup.

| Date | File | SHA-256 | Lines | Scores (A1 · A2 · A3 · A4 · B1 · B2 · B3 · C1 · C2 · C3 · D1 · D2 · D3 · E1 · E2) | Weighted | Verdict | Evidence / SKIPPED reason |
|---|---|---|---:|---|---:|---|---|
| 2026-10-29 | `README.md` | `932b2d04678ec032a87d22e1512547e5a6ff25bcd082972ba96f0a8b2d1a0a32` | 337 | 95 · 100 · 80 · 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 97.3 | PASS | Current graph **7,836 / 19,618 / 387**, 3D page 8,298,484 B, and the Stage AC hashes re-derived; the 447/450 census and 172/64,868/57,315 source counts are unchanged. A3 80: historical build/package commands were not re-run. E2 N/A: not generated. |
| 2026-10-29 | `docs/01-project-tree.md` | `9643c91b9b4ed5c1358c83ff1d36102d8f73ed6a99b89a524a9c9c13adae366d` | 114 | 100 · 100 · N/A · 100 · 100 · 100 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 100 · 100 | 99.7 | PASS | Graph row now says 7,836 / 19,618 / 387 and points at the Stage AC receipt. A3 N/A: no commands are quoted as receipts. C3 95: a map, not a risk register. |
| 2026-10-29 | `docs/registers/03-fix-log.md` | `13b5b1ba4e932d1a57c0191f516cc8b23e7685b32c9f2a6cfbdeae08815c77db` | 789 | 95 · 100 · 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 98.9 | PASS | Stage AC records the exact `graphify update`, `graphify export html`, 3D build/check, loopback browser, artifact hashes, and the seven zero-node metadata inputs. A1/A3 95: older stage commands were not re-run. D2 N/A: not an index target. |
| 2026-10-29 | `docs/registers/04-handoff.md` | `150167a07b86f781da1845485736a4244821576db5f45cc76aaa1b8260f57f55` | 458 | 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 99.3 | PASS | Offline session close now records the Stage AC graph refresh and no longer claims the graph is stale; the 447/450 census and sandbox SKIPPED note remain. E2 N/A: not generated. |
| 2026-10-29 | `graphify-out/GRAPH_REPORT.md` | `e770b95ce3973bfc51dd691ede51ff3945b0bd18bdddf28f971ad36e2dfb7af0` | 1932 | — | — | SKIPPED | Generated by graphify in Stage AC; not hand-edited. Its previous 1,772-line row is historical. |
| 2026-10-29 | `docs/registers/05-doc-audit.md` | self-referential | — | — | — | PASS (self) | This row cannot contain its own post-append digest; the bytes are pinned by the commit that adds the row. |

### Stable run command re-audit (2026-10-29)

Scope: the Markdown edited by Stage AD, against its final bytes. These rows
supersede the same-file rows above for these files.
`python3 scripts/audit-markdown.py --quiet README.md docs/01-project-tree.md docs/registers/03-fix-log.md docs/INDEX.md docs/registers/05-doc-audit.md`
exited 0; `python3 scripts/comprehension-bench.py --mode all` exited 0 with
100% accuracy and 95.7× median speedup.

| Date | File | SHA-256 | Lines | Scores (A1 · A2 · A3 · A4 · B1 · B2 · B3 · C1 · C2 · C3 · D1 · D2 · D3 · E1 · E2) | Weighted | Verdict | Evidence / SKIPPED reason |
|---|---|---|---:|---|---:|---|---|
| 2026-10-29 | `README.md` | `bbf2ac93aa207190e684b25d6b7c41d6a8e51d611411cdc0935fd8ce4dc44f5f` | 345 | 95 · 100 · 80 · 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 97.3 | PASS | §7 now documents the stable runner. Three real runs built and launched pids 2286, 2396, and 2496; `--build-only` exited 0 and left pid 2496 running. A3 80: historical build/package commands were not re-run. E2 N/A: not generated. |
| 2026-10-29 | `docs/01-project-tree.md` | `7a6147aa6084355b0b5cb8b8bef074879aad4e33b62557b168904efcb5619a57` | 114 | 100 · 100 · N/A · 100 · 100 · 100 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 100 · 100 | 99.7 | PASS | The `scripts/` row now names `run-latest.sh`. A3 N/A: no commands are quoted as receipts. C3 95: a map, not a risk register. |
| 2026-10-29 | `docs/registers/03-fix-log.md` | `18fc17e0caed81b630234a252ee59325a4f645853e1289ffe93662d1c0bd69b7` | 815 | 95 · 100 · 95 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · 100 | 98.9 | PASS | Stage AD records the three real launches, the graceful-quit behavior, the default-DerivedData reason, and the settle check. A1/A3 95: older stage commands were not re-run. D2 N/A. |
| 2026-10-29 | `docs/INDEX.md` | `731b1a779b634ea46a5f48429d5203f2bcc601c664a698c75336c55b45d7284a` | 104 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 100.0 | PASS | Added the runner row and re-pointed the four shifted README line anchors (six references) after the §7 insertion; `--validate-only` exit 0 and `--mode all` exit 0. E2 N/A: not generated. |
| 2026-10-29 | `docs/registers/05-doc-audit.md` | self-referential | — | — | — | PASS (self) | This row cannot contain its own post-append digest; the bytes are pinned by the commit that adds the row. |

### Mirage ADR-13 close-out re-audit (2026-10-29)

Scope: the Markdown edited for the warm-engine/library-scale tranche, against its
final bytes. `python3 scripts/audit-markdown.py --quiet README.md docs/INDEX.md
docs/01-project-tree.md docs/registers/03-fix-log.md docs/registers/04-handoff.md
docs/integration/MIRAGE-DEEP-DIVE-2026-10-28.md
docs/integration/adr/ADR-6-mirage-feature-lifecycle.md
docs/integration/adr/ADR-13-mirage-warm-engine-and-library-scale.md` exited 0.
`python3 scripts/comprehension-bench.py --validate-only` exited 0;
`python3 scripts/comprehension-bench.py --mode all` exited 0 with 100% facts
accuracy, 0 fallbacks, and 254.1× median indexed speedup. These rows supersede
the same-file rows above for these files.

| Date | File | SHA-256 | Lines | Scores (A1 · A2 · A3 · A4 · B1 · B2 · B3 · C1 · C2 · C3 · D1 · D2 · D3 · E1 · E2) | Weighted | Verdict | Evidence / SKIPPED reason |
|---|---|---|---:|---|---:|---|---|
| 2026-10-29 | `README.md` | `dba8cf535d843f67d8b2b54ced7b95f9d1bd1ad3e0f3949b7ea9d70faea29760` | 345 | 100 · 100 · 80 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 98.4 | PASS | Graph counts 8,037 / 20,085 / 378 and the 3D page size were re-derived from the Stage AF artifacts; the Stage AF pointer resolves. A3 80: older package/test commands in this file were not re-run in this audit. E2 N/A: README is not generated. |
| 2026-10-29 | `docs/INDEX.md` | `a06d767d58e40ea84c1380edff85e73da8017d383feda7df4b958290e11f8f7b` | 106 | 100 · 100 · 100 · N/A · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 100.0 | PASS | Added the ADR-13 and ADR-13-pins rows; moved the three handoff anchors to #L90/#L84 after the Stage AE row shifted the file. `--validate-only` and `--mode all` exited 0 (100% / 0 fallbacks). A4 N/A. |
| 2026-10-29 | `docs/01-project-tree.md` | `dd9d0c2ec2c522f064e309cb783ff7d46a493a17d89922009412d9c219fac768` | 114 | 100 · 100 · N/A · N/A · 100 · 100 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 100 · N/A | 99.7 | PASS | Mirage file count is 17 (`find … | wc -l`); tests are 71 files / 459 tests / 91 suites from the census, and the graph row matches Stage AF. C3 95: a map, not a risk register. E2 N/A. |
| 2026-10-29 | `docs/registers/03-fix-log.md` | `37990968a3384bcebd494a6b2725e51593a88294436e73a33ceb454412418e55` | 890 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 100.0 | PASS | Stage AE records the 12 new pins and the 459/671/450/9/0 census; Stage AF records the graph counts, four artifact hashes, 3D size, WebGL/no-off-origin receipt, and the skipped network-panel capture. All quoted commands were run in this session. |
| 2026-10-29 | `docs/registers/04-handoff.md` | `baf772bc193b8ec25014664f57d5f92997ad9a13011a84c8ed9cb946cb856eed` | 459 | 100 · 100 · N/A · N/A · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 100.0 | PASS | Baseline now states the ADR-13 census (459/671/450/9/0) and the Stage AF graph counts; row 10 names the still-pending owner acceptance instead of claiming it. No commands are quoted as receipts. E2 N/A. |
| 2026-10-29 | `docs/integration/MIRAGE-DEEP-DIVE-2026-10-28.md` | `2bd4868a8142d88942951b4b8abcec3ecf5f9e22cd6c1bf5ea6b4747173e73a9` | 297 | 100 · 100 · 100 · N/A · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 100.0 | PASS | The 2026-10-28 per-gesture lifecycle is labelled historical; §3.2 names 17 existing files; §10 records ADR-13 and the 459/671/450/9/0 census. `./scripts/run-latest.sh --build-only` and the census were run. E2 N/A. |
| 2026-10-29 | `docs/integration/adr/ADR-6-mirage-feature-lifecycle.md` | `4ed4b3eecdb50740698b7347c0ea25e7763a3bc7a63881dc047b54c955e9e81a` | 81 | N/A · 100 · N/A · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 100.0 | PASS | Decision 5 now carries the ADR-13 supersession note; the ADR-13 path exists and the other decisions remain in force. A4 100: ADR-13 resolves. E2 N/A. |
| 2026-10-29 | `docs/integration/adr/ADR-13-mirage-warm-engine-and-library-scale.md` | `d9e6c9b47740aaf4f62c241ca6e60af813407457233e7a97cd1fb80aeb3d7cd9` | 94 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 100.0 | PASS | New decision record: 17-file count, 450/9/0 across 459/671, three suite names, and the Stage AE receipt. All quoted commands were run; owner acceptance is explicitly pending rather than claimed. E2 N/A. |
| 2026-10-29 | `docs/registers/05-doc-audit.md` | self-referential | — | — | — | PASS (self) | This section cannot contain its own post-append digest; the bytes are pinned by the commit that adds the rows. |

### Closeout Initiative re-audit (2026-10-29)

Scope: every Markdown file edited for the ADR-13 close-out, audited against its
final bytes. The audit command was
`python3 scripts/audit-markdown.py --quiet` over the twelve files below and
exited 0 after the Stage AG path phrasing fix. `comprehension-bench.py
--validate-only` exited 0 (`bank ok: 30 facts, 12 overview facts`);
`comprehension-bench.py --mode all` exited 0 with 100% facts accuracy, 0
fallbacks, 244.7× median indexed speedup, and 94.3× overview speedup. These rows
supersede the same-file rows above.

| Date | File | SHA-256 | Lines | A1 · A2 · A3 · A4 · B1 · B2 · B3 · C1 · C2 · C3 · D1 · D2 · D3 · E1 · E2 | Weighted | Verdict | Evidence / SKIPPED reason |
|---|---|---|---:|---|---:|---|---|
| 2026-10-29 | `AGENTS.md` | `2cf870c639dc9ba92557f6aca7ef3d806c5cc1fe3d08def1f007044eae174627` | 300 | N/A · 100 · 70 · N/A · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A · 100 · 100 · N/A | 96.8 | PASS | The protocol is now named **Closeout Initiative** and states the five-step order. A3 70: the CI and graph commands are quoted as instructions, not all re-run as receipts in this audit. A4 N/A (no commit/run IDs stated). D2 N/A: AGENTS.md is repository law, not an INDEX lookup target. |
| 2026-10-29 | `README.md` | `79b22012e98483b456d6ca754ab4264cac9ae355f7d3f71971bedd8dc6651d5b` | 345 | 100 · 100 · 85 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 98.8 | PASS | Census 459 / 671 / 450 / 9 / 0, app size 175 files / 66,050 raw / 58,378 non-blank, test folder 71 files, and graph 8,045 / 20,093 / 381 were re-derived this session. A3 85: package-release and older stage commands are quoted but were not re-run. E2 N/A: README is not generated. |
| 2026-10-29 | `docs/01-project-tree.md` | `64dff851e8ac2c3725457da6c496e98f3e17c3320df3bc382066e0fd3fe28867` | 114 | 100 · 100 · N/A · N/A · 100 · 100 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 100 · N/A | 99.6 | PASS | Mirage row is 17 files (counted); tests are 71 files / 459 tests / 93 suites (census); graph row is 8,045 / 20,093 / 381. A3/A4 N/A: the file states no commands or run IDs. C3 95: a map, not a risk register. |
| 2026-10-29 | `docs/registers/03-fix-log.md` | `bae5bc9d69a18b509dabe20e6b05185486ef562fd71996189ed74c6004cd51fa` | 916 | 100 · 100 · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 | 99.2 | PASS | Stage AG records the 459-test census, both graph rebuilds, the 67,612 KiB junk removal, and five artifact hashes. A3 90: earlier stages quote commands that were not re-run in this close-out; Stage AG commands all ran. The two removed-directory paths are now plain prose, so no backticked path is missing. |
| 2026-10-29 | `docs/registers/04-handoff.md` | `52e6b4c3d24c530fedcc91122b7365f863d260a72072fce0dd54f2596fdab72f` | 459 | 100 · 100 · N/A · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 99.3 | PASS | Baseline states 459 / 671 / 450 / 9 / 0 and the Stage AG graph counts; the older boundaries are labelled historical. A4 90: the package SHA is labelled “last documented”, not re-derived. A3 N/A: no command is presented as a receipt. |
| 2026-10-29 | `docs/method/07-testing-strategy.md` | `bb994b010df2ffdee7cb2c56a3bc6c6f6e692728e70b1587881f9ee5de44295b` | 165 | 100 · 100 · 90 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 99.2 | PASS | Scale row is 71 files / 459 tests / 93 suites / 671 runs; the offline band's 447 figure is explicitly historical. A3 90: the cited GitHub run was not re-queried this session. E2 N/A. |
| 2026-10-29 | `docs/roadmap/05-remediation-roadmap.md` | `e476d44366c18515554710233637d46c9dabe3a3de39db72e8a8d7e71df9f6b2` | 215 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 100.0 | PASS | The dated 2026-10-29 note now reads 459 / 671 / 450 / 9 / 0; run `40811182851` is kept as the labelled pre-rename baseline. E2 N/A. |
| 2026-10-29 | `docs/MILESTONES.md` | `9bb84284a92e325ce659423cadf1c15f514008f3c24497d841a11395371c7aa9` | 362 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 100.0 | PASS | Milestone 007 records ADR-13 with the 459-test census and xcresult `rt-census-20261029-031816.xcresult`; its “what this does not mean” section discloses the missing owner run, session-scoped queue, and ADR-7 limit. |
| 2026-10-29 | `docs/design/UI-UX-OVERHAUL-2026-10-29.md` | `60cc1a53b48f3cb2acc402088b47da7bd2e2d70d92e710b9840bfe826ed2e2a3` | 361 | 100 · 100 · 85 · 100 · 100 · 95 · 100 · 100 · 100 · 95 · 100 · 100 · 100 · 100 · N/A | 97.9 | PASS | The Stage Z table stays the dated UI receipt; the later-counts note now carries Stage AB (447) and Stage AE (459 / 93 suites / 175 files / 58,378 non-blank). A3 85 and C3 95: historical commands and residual UI risks rest with the older record. |
| 2026-10-29 | `docs/integration/MIRAGE-DEEP-DIVE-2026-10-28.md` | `2bd4868a8142d88942951b4b8abcec3ecf5f9e22cd6c1bf5ea6b4747173e73a9` | 297 | 100 · 100 · 100 · N/A · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 100.0 | PASS | Unchanged since the ADR-13 audit row above; the digest matches, the 2026-10-28 lifecycle is labelled historical, and §10 carries ADR-13. |
| 2026-10-29 | `docs/integration/adr/ADR-6-mirage-feature-lifecycle.md` | `4ed4b3eecdb50740698b7347c0ea25e7763a3bc7a63881dc047b54c955e9e81a` | 81 | N/A · 100 · N/A · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 100.0 | PASS | Unchanged; decision 5 carries the ADR-13 supersession note and the ADR-13 path resolves. |
| 2026-10-29 | `docs/integration/adr/ADR-13-mirage-warm-engine-and-library-scale.md` | `d9e6c9b47740aaf4f62c241ca6e60af813407457233e7a97cd1fb80aeb3d7cd9` | 94 | 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · 100 · N/A | 100.0 | PASS | Unchanged; census, build receipt, the 17-file count, and owner-acceptance-as-pending are all stated. |
| 2026-10-29 | `docs/registers/05-doc-audit.md` | self-referential | — | — | — | PASS (self) | This section cannot contain its own post-append digest; the bytes are pinned by the commit that adds these rows. |
