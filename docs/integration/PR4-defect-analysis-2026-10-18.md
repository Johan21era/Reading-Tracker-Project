# PR-4 Current-State Defect Analysis — Real Sidecar Lifecycle

| | |
|---|---|
| **Document ID** | PR4-DEF-ANALYSIS-2026-10-18 |
| **Status** | Active analysis of the current execution state; supersedes no prior record, feeds M-019/M-020 |
| **Governing documents** | `RT_Mirage_Codebase_Merge_Playbook.md` (S16-ES-1 PR ladder, S8-ES-5 house test standard); master merge log `merge-log.md` (M-001…M-018) |
| **Branch under analysis** | `merge/integration` (repo root `/Users/johanrembeci/Desktop/Reading Tracker Main /`) |
| **Author / date** | Engineering investigation session, 2026-10-18 |
| **Evidence-class legend** | **[V]** = verified today by inspection/artifact on disk · **[S]** = session-phase observation from today's debugging cycles (log or artifact *not retained*; repeatable by procedure) · **[U]** = unverified hypothesis/unknown |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Investigation Scope and Current-State Snapshot](#2-investigation-scope-and-current-state-snapshot)
3. [Environment and Reproduction Context](#3-environment-and-reproduction-context)
4. [Current Defect Inventory](#4-current-defect-inventory)
5. [Individual Defect Reports](#5-individual-defect-reports)
6. [Branching Root-Cause Analysis](#6-branching-root-cause-analysis)
7. [Cross-Defect Dependencies and Shared Failure Patterns](#7-cross-defect-dependencies-and-shared-failure-patterns)
8. [External Research and Source Evaluation](#8-external-research-and-source-evaluation)
9. [GitHub Issues, Pull Requests, Commits, and Relevant Changes](#9-github-issues-pull-requests-commits-and-relevant-changes)
10. [Candidate Solutions and Technical Feasibility](#10-candidate-solutions-and-technical-feasibility)
11. [Recommended Remediation Plan](#11-recommended-remediation-plan)
12. [Regression Testing and Verification Criteria](#12-regression-testing-and-verification-criteria)
13. [Unresolved Questions, Blockers, and Evidence Gaps](#13-unresolved-questions-blockers-and-evidence-gaps)
14. [Prioritized Next Actions](#14-prioritized-next-actions)
15. [References and Source Links](#15-references-and-source-links)
- [Appendix A — Corrected forensic probe (temporary; never commit)](#appendix-a--corrected-forensic-probe-temponly-never-commit)

---

## 1. Executive Summary

The merge is executing the PR ladder on `merge/integration`. PR-1..PR-3 are **committed and gates-evidenced** (`ef198c5`, `13ad970`, `56bf5d8`; census 147/0 at PR-3). PR-4 ("real sidecar lifecycle") runtime and test code is complete on disk (~17.8 KB of runtime code across three files + four test suites), building green as of its last full build, but **PR-4 cannot close** because of one confirmed, intermittently reproducible defect plus a cluster of closeout-procedural items.

**The single active blocking defect (BUG-001):** stub-engine children that stay alive (loop on `stdin.readline()` after printing their first-line banner) *sometimes* — deterministically per-run, nondeterministically across runs — have their flushed stdout never observed by the parent transport, in **multi-test batch contexts only**. Same children, same launcher, same stub script deliver their bytes 100% of the time in isolated and several combined-run contexts, in single-test bodies *some* of the time (today's in-test reproduction shows the poison is **transient**: after one silent wedge, subsequent cycles in the same test body delivered normally). Status: **under investigation**; kernel-level discriminator experiment designed but not yet executed.

**A dissolved alarm:** mid-analysis, a suspected data-loss condition ("39 legitimate covers appear replaced by stub debris") was **falsified by verification** — `library.json` references zero `.jpg` files; all 39 files in `covers/` are unreferenced test debris from an Aug-26-era presupuesto dev cycle (mtimes all 2026-08-26 06:42–06:59), hashed exactly against the three known stub-cover hashes (13 copies of each). Disposition remains owner-gated per M-013 doctrine; no library references are missing.

**What actually works right now:** locator validation-by-execution, SIGPIPE shielding, isRunning-gated forceKill, pendingBytes framing policy, EOF-ordered teardown, cooperative-pool starvation elimination (all proven on the *earlier* failure layers today), full 147-test regression baseline, all isolation/combined-run guarantees for the PR-4 suites that do NOT reach the wedge condition.

**Best-supported path:** run the one designed kernel-level discriminator (Appendix A probe; ~15 min), then apply the outcome-directed fix or the environment-interim fix (per-suite runner isolation), then complete the PR-4 closeout checklist (census, covers disposition, M-019/M-020, commit). Everything else in the PR ladder is unstarted-but-clean.

---

## 2. Investigation Scope and Current-State Snapshot

### 2.1 Scope boundaries

- **In scope:** only defects/unexpected behavior in the *current PR-4 execution state* on branch `merge/integration`, as standing now; plus remediation procedure defects that block correct execution of the current task (test infrastructure, artifacts, hygiene).
- **Out of scope (excluded per owner decisions / applicability):** NEW-DE punch-list defects (queued for a separate session by owner instruction); historical resolved incident layers (pool starvation, SIGPIPE deaths, PID-reuse cross-kill, shim xcrun sandbox refusal) — each is cited **only** as supporting context where the contributed mechanism is still load-bearing in present code; ADR-1 (Class Ω, parked); ADR-3/ADR-7 (future gates, no present defect).

### 2.2 Repository snapshot (verified 2026-10-18 ~18:0x Eastern)

```
branch:            merge/integration
HEAD:              56bf5d8 (PR-3) — parent 13ad970 (PR-2) — parent ef198c5 (PR-1)
remote:            origin https://github.com/Johan21era/Reading-Tracker-Project.git
modified (owner-locked, D1):  README.md, docs/01-project-tree.md,
                  docs/method/07-testing-strategy.md, docs/registers/{02-defect-register,03-fix-log,04-handoff}.md,
                  docs/roadmap/{05-remediation-roadmap,06-rsvp-feature-plan}.md   [8 files, byte-untouched rule]
untracked (PR-4):  Reading Tracker/Features/Mirage/{MirageProtocolConstants, MirageChildProcess, MirageSidecarSupervisor}.swift
untracked (tests): Reading TrackerTests/{MirageStubSidecarSupport, MirageHandshakePinTests,
                  MirageSidecarLifecycleTests, MirageRealEngineSmokeTests}.swift
untracked (diag):  Reading TrackerTests/MirageReproProbeTests.swift          ← BUG-005, delete before commit
untracked (dd):    .rt-dd/ (DerivedData for test campaigns; never commit) — **REMOVED 2026-10-18 eve**: 449 MB build debris deleted after evidence externalization (see postscript §R0)
```

Commits (verified via `git show --stat`): PR-1 6 files/360 insertions (docs+evidence only), PR-2 4 files/164 (ADRs PROPOSED + log refresh), PR-3 8 files/454 (3 runtime files, 1 test file, 3 ADR flips ACCEPTED, log refresh). No branch modifications performed during this investigation; remote state not inspected or pushed.

### 2.3 Merge-distance snapshot (management estimate, unchanged from session)

| Unit | Pct complete | Basis |
|---|---|---|
| Overall merge (8 PRs) | ≈48% | 37.5 committed + ~10.6 current-PR credit |
| Integration spine (PR-1..4) | ≈93% (code) | runtime complete; acceptance run blocked by BUG-001 |
| PR-4 itself | ~85% | code+build 100%; single-run full-suite green pending; census/covers/log pending |

---

## 3. Environment and Reproduction Context

| Item | Verified value | Source |
|---|---|---|
| OS / build | macOS 26.6.1 (Build 25G76), device "My Mac" (arm64) | [V] `sw_vers`, xcresult device metadata |
| Toolchain | Xcode 27.1 (27A9275) | [V] `xcodebuild -version` |
| Test runner | Swift Testing (bundled), suites marked `.serialized` for PR-4 (process-spawning suites decode children) | [V] source inspection |
| Host app posture | App-Sandbox-signed test host ("Sign to Run Locally", entitlements) | [V] build log CodeSign step |
| Interpreter | Python 3.14.8 at `/opt/homebrew/bin/python3` (Homebrew; zero-arg validated via `MiragePythonLocator` execution-probe, memoized ~1 s first call) | [V] locator code + runtime behavior |
| Build/test command form | `xcodebuild build-for-testing` + `test-without-building` against the **default DerivedData** (amended 2026-10-18 eve — `-derivedDataPath .rt-dd` on the iCloud-synced Desktop provokes BUG-003; see postscript §R0); suites selected via `-only-testing:"Reading TrackerTests/<Suite>"` (note the **space** in the target name) | [V] session workflow |
| Stub transport knobs (tests) | bannerTimeout 6 s · responseTimeout 1.5 s · lineSizeLimit 120 B · backoff injected `[0.05,0.05,0.05]` · teardown grace 0.3 s | [V] `MirageStubSidecarSupport.swift:124-144` |
| Production knobs | banner 10 s default, response 20 s, backoff `[2,4,8]`, inter-attempt sleeps `backoff[0..<count-1]` | [V] `MirageSidecarSupervisor.swift:46-59,116-118` |

**Reproduction condition summary (BUG-001):**

1. A runner session (one `xcodebuild test*` invocation) executes **more than one** test that spawns live stub children.
2. Somewhere **after earlier children were spawned, exchanged, and torn down**, a later spawn performs `print(..., flush=True)` of the ready banner and then enters `sys.stdin.readline()` — and stays **alive and blocked forever**, while the integrating parent's own pipe read also blocks (banner timeout: `responseTimeout(seconds: 6.0)` at 6 s stub config; 18.1 s = 3 × 6 s + backoff at supervisor ladder level).
3. **Does not occur** for: children that print and exit (junk/nostatus/exit-after-banner), first-child-in-run launches, suite-less single spawn+read cycles without a prior teardown, and — per today's probe — the *subsequent* cycles after one wedge.

**Newest verified repro (today):** `/Users/johanrembeci/Desktop/Merge Phase/evidence/BUG-001-repro-2026-10-18_17-51-51.xcresult` (externalized from `.rt-dd` same evening — see postscript §R0) — single test body `MirageReproProbeTests/poisoningSequence()` (temporary probe, BUG-005's predecessor v1/v2 lineage), **1 failed / 0 passed**, wall time 36.2 s:
`Issue recorded: B: banner lost after bare-junk teardown: .responseTimeout(seconds: 6.0)` — i.e., a *bare* `MirageProcessTransport` junk-child cycle (banner fault → `teardown(grace: 0.3)`, NO supervisor) poisoned the immediately-following direct drift-child banner read; phases C (junk supervisor) and D (drift supervisor, `counter==1`) that came after passed. This localizes the poisoning trigger to the **immediately **post-teardown window** and proves it is **not** an effect of xcodebuild test-boundary machinery.

---

## 4. Current Defect Inventory

Triage table (columns kept narrow; full detail in §5):

| ID | Title | Status | Severity | Priority | Component |
|---|---|---|---|---|---|
| BUG-001 | Batch-context silent stdout from long-lived stub children | Under investigation | High | P1 | `MirageProcessLauncher` / `MirageProcessTransport` / Python interp layer |
| BUG-002 | Runner abort (exit 0) when interpreter resolves to Python.app binary directly | Avoided; awaiting verification | Medium | P2 | `MiragePythonLocator` candidate list |
| BUG-003 | CodeSign failure from xattr detritus in build products | Resolved today; recurrence procedure undocumented | Medium | P2 | Build/test infrastructure |
| BUG-004 | `timeout` command does not exist on host; chained test steps abort silently (rc 127) | Confirmed environment footgun | Low | P3 | Test procedure |
| BUG-005 | PR-4 probe artifact in working tree never compiled; contains a wrong-pipe-index defect | Confirmed (inspection) | Low | P3 | Working-tree hygiene |

Open process items (not defects; tracked for closeout):

| ID | Item | Owner gate |
|---|---|---|
| OPE-001 | Stub-cover debris corpus: 39 files (13× each of 3 known hashes), all Aug-26-era, 0 references, 0 missing — delete-before-commit plan expanded from "3 pinned files" to "hash-family cleanup" | Owner countersign (Class Δ precedent M-013) |
| OPE-002 | Merge-log entries M-019/M-020 not yet written | Author (<root>, during closeout) |
| OPE-003 | PR-4 census not taken; single full-runner green acceptance not achieved | Gate-exit step |
| OPE-004 | Real-engine opt-in smoke never executed (env-gated; `MirageV1.0` path + disposable temp DB only) | Owner optional |

---

## 5. Individual Defect Reports

### BUG-001 — Batch-context silent stdout from long-lived stub children

| Field | Content |
|---|---|
| **Status** | Under investigation (reproduced; mechanism not yet verified) |
| **Severity / Priority** | High (blocks PR-4 acceptance → every downstream PR's gate evidence differs from the recorded standard) / P1 |
| **Affected component** | PR-4 pipe transport chain: `MirageProcessLauncher.launch()` (`MirageChildProcess.swift:138-214`), `MirageProcessTransport.readCommandLine/bridgedReadLine/blockingReadLine` (`:305-387`), `MirageProcessTransport.teardown` (`:276-291`), Homebrew Python 3.14.8 spawn bootstrap, Swift Testing `.serialized` suite context, sandboxed test host |
| **Observed behavior** | Banner line flushed by a live stub child never reaches the parent's blocking read; parent times out at the banner deadline; child killed at teardown; subsequent cycles may deliver normally. Kernel-level pairing appeared correct in the one inspected wedge |
| **Expected behavior** | Every child prints its banner into fd 1 and the parent reads it within the banner timeout, in every context, including multi-test batches |
| **Reproduction procedure** | (1) Build for testing; (2) run a suite containing ≥2 process-spawning tests in one runner session; (3) repeat enough times to hit the wedge (pin-batch shows junk/nostatus pass then drift/ready wedge; lif-batch shows wedge after the first supervisor exhaustion cycle). Alternative single deterministic form: the temporary probe phases (Appendix A) — junk bare cycle → direct drift read, N repetitions |
| **Observed error output** | `MirageTransportFailure.responseTimeout(seconds: 6.0)` (banner) / supervisor `permanentDown` after 3 ladder attempts (18.1 s wall); xcresult 17-51-51 `Issue recorded: B: banner lost after bare-junk teardown: .responseTimeout(seconds: 6.0)` |
| **Execution context** | Sandbox-entitled test host; macOS 26.6.1/25G76; Xcode 27.1/27A9275; Python 3.14.8 Homebrew (posix_spawn bootstrap → `Python.app/Contents/MacOS/Python` — double-spawn verified via `otool` [S]); `-u` unbuffered stdio flag passed [V code] |
| **Reproducibility** | Intermittent across runs, deterministic within a run's failure mode; isolated single-suite runs (pin-2, lif-5 subsets, 5-direct batch) reliably green |
| **Dependencies** | Teardown sequence shape (`closeWrite` before/after kill — currently kill→closeWrite ordering inside `teardown`); prior-child reap completeness; Bootstrap-inherited fds; Foundation `Process`/`Pipe` internal fd accounting; test-host sandbox |
| **Existing evidence** | Runtime files (untracked, disk); probe xcresult 17-51-51 [V]; session-phase wedge artifacts: `sample` showed child blocked in `_textiowrapper_readline` after its `print` had executed; `lsof` showed child fd1 ↔ parent read-end pairing (fd1↔fd17) — **but no `lsof -o` byte offsets captured, and artifact not retained** [S] |
| **Current hypothesis** | See §6-D: three candidate mechanisms (H1 ghost/self-consuming reader state; H2 read-object mis-wiring (weakened by pairing evidence); H3 child's bytes never entered the surviving pipe (fd1 identity anomaly deeper in the bootstrap chain)) — all **unverified**; a single `lsof -o` combo discriminates all three |
| **Next diagnostic step** | Execute Appendix A probe v4 (corrected, in-test, kernel-level offsets on **both** the launcher pid and its python grandchild); classify per outcome table in §10 |

### BUG-002 — Runner abort when interpreter candidate points at Python.app binary

| Field | Content |
|---|---|
| **Status** | Avoided (candidate order reverted); **verification of the avoidance state = trivial (locator passes `bin/python3` first again, validated each brand-new process) — formal re-check folds into the next full build** |
| **Severity / Priority** | Medium / P2 |
| **Affected component** | `MiragePythonLocator` candidate ordering (`MirageChildProcess.swift:60-71`) |
| **Observed behavior** | When the locator was briefly pointed *directly* at `Python.app/Contents/MacOS/Python`, the entire test runner died mid-suite: xcresult recorded "The test runner exited with code 0 before finishing running tests" [S] |
| **Expected behavior** | Locator never selects an entry that terminates the host |
| **Reproduction** | (Do not reproduce absent owner need): reorder candidates to Python.app-first; run a spawning suite |
| **Error output** | [S] xcresult message quoted in session history; probe artifact not retained |
| **Context** | Same sandboxed host; LS-activation semantics suspected (bundle-registered interpreter) |
| **Reproducibility** | Deterministic in that configuration [S]; configuration no longer selectable by default |
| **Hypothesis** | Bundle-interpreter activation path ends the process group of the test runner (unverified; consistent with "exit code 0" signature and LS semantics, and with the note left in code) |
| **Evidence on disk** | Code comment NOTE (PR-4 evidence) at `:61-64` stating the finding; candidate order reverted to `bin/python3`-first |
| **Next step** | Keep the anti-pattern documented; if interpreter is ever re-baselined, test Python.app-direct in a disposable runner first |

### BUG-003 — CodeSign xattr detritus breaks build-for-testing

| Field | Content |
|---|---|
| **Status** | Resolved today (cleanup applied); **awaiting recurrence-procedure codification** |
| **Severity / Priority** | Medium / P2 |
| **Affected component** | `.rt-dd` build products; repo working tree extended attributes |
| **Observed behavior** | `CodeSign …Reading TrackerTests.xctest` failed: "resource fork, Finder information, or similar detritus not allowed" [V session log text captured today] |
| **Expected behavior** | Build+sign succeeds; build products free of quarantine/FinderInfo xattrs |
| **Reproduction** | Any test-touched file inside the bundle carrying such an xattr (source of the attt pattern unknown this instance) |
| **Resolution applied today** | `xattr -cr` over `.rt-dd/`, over the repo tree; AppleDouble `._*` and `.DS_Store` removal; rebuild → `** TEST BUILD SUCCEEDED **` [V] |
| **Repo impact of cleanup** | Tracked-file content unchanged (xattrs are not content); 8 owner-locked files verified still-status `M` only [V `git status`] |
| **Residual risk** | Recurrence possible; no committed scriptable prevention; not a code defect of PR-4 itself |
| **Next step** | Record procedure as a merge-log rule for future test campaigns (operations note, no code) |

### BUG-004 — macOS host lacks `timeout`; chained verification aborts silently

| Field | Content |
|---|---|
| **Status** | Confirmed (environment), no product impact |
| **Severity / Priority** | Low / P3 |
| **Component** | Test-session procedure |
| **Observed** | `timeout`-prefixed shell steps returned rc 127 and prevented later `&&`-chained verification steps from running; several diagnostic cycles appeared to "hang"/fail for this trivial reason [S] |
| **Expected** | Reliable step chaining during test campaigns |
| **Resolution** | Discipline only: never use `timeout` on this host; rely on xcodebuild's own timeouts and the tool-runner timeout parameter (documented in workflow instructions) |

### BUG-005 — PR-4 probe artifact in tree: never compiled; contains wrong-pipe-index defect

| Field | Content |
|---|---|
| **Status** | Confirmed (inspection) — delete before any commit |
| **Severity / Priority** | Low / P3 |
| **Component** | `Reading TrackerTests/MirageReproProbeTests.swift` (5,993 B, mtime 17:48:43 [V]) |
| **Observed defect inside the probe** | v3 returns `(p, inPipe, outPipe)` from `rawSpawn` but the call sites call `rawReadLine(junk.1)` / `rawReadLine(drift.1)` — i.e., they read the **stdin** pipe, not the stdout pipe; any execution would misreport silence regardless of the transport [V code inspection] |
| **Expected** | Probe reads `outPipe.fileHandleForReading.fileDescriptor` |
| **Also true** | The file has never been compiled/run (last TEST BUILD SUCCEEDED predates its write); the v1 lineage probe achieved only one verified result before evolution (xcresult 17-51-51) |
| **Resolution** | Delete the file; if the §10 experiments proceed, insert the Appendix A corrected probe instead — temporarily only |

### OPE-001 — Stub-cover debris corpus (expanded cleanup, Class Δ owner gate)

Verified today [V]:

- `covers/` holds **39 `.jpg` files + 1 `.DS_Store`**; every `.jpg` is unreferenced by `library.json` (audit: 0 values containing ".jpg" in the entire JSON tree; books' key set has no cover-filename field).
- Hash census (full SHA-256, verified): 13 × `fc16d7dcee9cae83ef3923222a81ccd8fe96c9d25fdb7f504d66f1011e0cd870` (6 B), 13 × `6e568e1f67fba258184c78181539e5e8fdee447e49bb706fc0ea34fbf12336a5` (3 B), 13 × `99b620c1896533dc67076b7f98d781fd242702d0e02f78f19370e9f7588a1f76` (7,323 B).
- **All 39 mtimes: 2026-08-26 06:42–06:59** — none written today. The three "today trio" reported in M-011/M-013 were deleted earlier today; today's PR-4 campaigns did *not* run `CoverStorePinsTests` (only Mirage suites were selected), so no recreation occurred.
- **Dissolved alarm:** initial reading suggested legit covers were consumed by test debris. Falsified: the library has no filesystem cover references; zero referenced-and-missing. No data loss.

Disposition requirement (owner): expand the deletion protocol from "3 pinned files" to "hash-family cleanup — delete every file whose sha256 equals one of the three pinned stub hashes; retain `.DS_Store` or remove by owner preference; container re-count after cleanup." Per M-013 precedent this is a shell-atomic, hash-verified, countersigned operation.

### OPE-002 / OPE-003 / OPE-004 — closeout process items

- **OPE-002:** merge-log entries **M-019** (PR-4 implementation record: runtime + tests + launch invariants: `-u`, SIGPIPE shield, locator execution-prove, detached-thread readers, pendingBytes leftover policy, isRunning-gated forceKill, EOF-ordered teardown) and **M-020** (PR-4 verification/census + BUG-001 evidence trail + cover-disposition) remain unwritten. This document is the intended evidentiary input.
- **OPE-003:** No full-PR-4 census exists. Do the arithmetic: 147 (PR-3 full-suite census) + 6 pin-suite + 8 lifecycle-suite = **161 expected executed / 0 failed** default run, smoke suite gated out of the count (its skipped-count behavior under `.enabled(if:)` is to be observed at the census run, not assumed).
- **OPE-004:** `MirageRealEngineSmokeTests.realEngineHandshakeAndHealth` has never executed (`mirageRealEngineEnabled` never set). Command template recorded in test file docs; disposable temp DB only; owner decision whether to spend a cycle before PR-4 closeout.

---

## 6. Branching Root-Cause Analysis

### 6.1 BUG-001

**A. Defect semantics and impact.**
The failure violates the transport contract stated inside `MirageProcessTransport` itself: "Blocking reads must NEVER run… / line reader over the byte stream" — the invariant broken is *"bytes written by a live child with flushed stdout eventually become observable at the parent's read fd, or EOF when all write ends close."* What is degraded: PR-4's acceptance (single full-runner suite green) and any realistic supervisory behavior on this host context under batch load. Nothing in RT shipping runtime is exposed yet (no RT UI wiring exists pre-PR-5), so customer-impact scope is currently test-infrastructure only — but the same mechanism would affect production sidecar supervision if it lives outside the test context; verifying mechanism class (H1/H2/H3) decides that.

**B. Origin and trigger conditions.**
- Trigger window [V/S combined]: occurs **after** at least one prior child has completed an exchange cycle *and* been torn down, inside one runner session; requires the *next* child to be a print-then-stay-alive posture.
- Sequencing evidence: pin-batch (junk→nostatus→drift✗→ready✗), lif-batch (permanentDown→recovery✗→…, subsequently even direct tests ✗), probe-batch (junk-bare→drift✗, then junk✓, drift✓). The probe result **[V]** is the strongest: the wedge self-heals within the same test body after ~7 s of post-wedge activity, so "transient window", not cumulative state.
- Failure is NOT during init (child is alive, banner `print` executed per `sample` [S]); NOT during error handling (no exceptions involved on the wedge path yet — the wedge *is* the pre-fault state).

**C. Isolation vs. cross-context recurrence.**
Cross-context facts table:

| Context | Print+exit children | Long-lived children |
|---|---|---|
| Isolated suite runs [V, this session] | deliver | deliver |
| 5-direct-test batch (no supervisor) [V] | deliver | deliver (5/5) |
| pin-2 (two supervisor children) [V] | — | deliver (2/2) |
| pin-full (2 exit-children + 2 supervisor children) [S] | deliver | wedge (both) |
| lif-full [S] | deliver (first) | wedge afterwards |
| probe single-test A→B→C→D [V] | deliver | wedge once, then deliver |
| **Common to every wedge** | **a preceding teardown cycle in the same runner** | **child stays alive in reads** |

The common dependency connecting all occurrences is the **(spawn → exchange → teardown) cycle executed at least once before the wedge launch** — not parallelism, not test count, not suite boundaries ([V] probe did it inside ONE test). Whether one mechanism underlies both "elementary" (first-wedge) and "latched" (subsequent-everything ✗) signatures from earlier batches is **unresolved**: earlier batch latched permanently for the rest of the runner; today's probe did not latch. Distinguish via the same probe extended with an N-cycle matrix (recorded as an evidence gap in §13; Experiment E2).

Isolation evidence is sufficient to exclude: kernel pipe pairing, launcher-level SPI masking, Swift-concurrency pool involvement, stub-script posture variance. None are *proven* causes; each was falsified for its layer [S session-phase experiments].

**D. Root-cause hypotheses and verification procedure.**

```
Symptom → Trigger → Path → Mechanism → Hypothesis → Experiment
```

- **H1 — A "ghost" second consumer exists on the child's stdout pipe read end** (stale `FileHandle`/dispatch-source/fd-number reuse from a prior epoch's channels), consuming the banner bytes so the *transport's own* reader blocks forever while genuinely reading an empty object/mechanism. *Supporting:* bytes vanish exactly once at a boundary between infinite objects (speculative); teardown retains open read handles until dealloc (verified [V code] — `teardown` never closes the *stdout reading* side; only `closeWrite`!). *Contradicting:* print+exit children deliver in wedge-adjacent contexts (a persistent ghost would starve them too — a time-windowed ghost is required, unexplained). *Verification:* **E1 (Appendix A)** — at wedge, capture `lsof -o -O` of both child pids *and* the parent; a second read-end fd on the same pipe with a non-zero advancing offset while our read stays at 0 = H1 CONSISTENT; if two fds exist and ours never moves, expected result = confirm. If no second fd: H1 FALSIFIED.
- **H2 — The transport's read object is mis-wired (reads an fd that is not this pipe's read end)** (e.g., stale/dup'd handle object). *Supporting:* nothing positive beyond "sympomms appear in one specific object"; *Contradicting:* pairing lsof matched fd1↔fd17 in the inspected wedge [S]. *Verification:* same E1: our read fd's device/pipe-identifier vs child's write end (lsof `SIZE/OFF` + NODE on `-o -O` output); disagree = H2 CONSISTENT. Expected-if-wrong: rows match → H2 FALSIFIED.
- **H3 — The bytes never entered the pipe** (child-side fd1 was not the pipe at print time — Homebrew bootstrap double-spawn performed an intermediate fd remap, or Python's `sys.stdout` did not flush into fd 1 in the wedge instance). *Supporting:* "flush executed but nothing landed" is otherwise impossible at kernel level; double-spawn bootstrap proven [S otool] and Python.app-direct unsafe proven [S BUG-002]; child alive in `_textiowrapper_readline` both compatible with any fd1. *Contradicting:* the one pairing lsof [S] appeared to match fd1→pipe at wedge. BUT that lsof may have inspect the launcher pid, not the python grandchild (unclassed). *Verification:* E1 child-side: capture write-end offset at wedge; compare against the grandchild (`pgrep -P <launcher-pid>`). If launcher-pid fd1 offset == 0 while grandchild shows fd1→(our pipe) with offset 0 → the interpreter itself hasn't flushed; if grandchild's fd1 is a different dvice object → H3 CONFIRMED and locator is the battleground. Plus E1b: child writes its own `fstat(fd1)` identity (`st_dev,st_ino, S_IF*`) to **stderr** (diagnostic channel, byte-untouched stdout) — parent cross-checks with the pipe's `stat` identity — the cleanest possible "whose pipe am I writing to" proof.
- **H4 — Runner-level interference with child stdout pipes** (Swift Testing/xctest machinery attaching to fds). Disposition: REJECTED for now [no positive evidence; xcodebuild runner was present in all green contexts too].

E1 outcome→fix mapping is in §10/§11. E1 is designed to run in ~10-15 minutes with zero repo-state change (probe in test target, delete after).

### 6.2 BUG-002

**A. Semantics:** locator's own contract ("validation is by EXECUTION … never by trusting paths") held up — execution validation passed — but the *shock effect* (runner death at a later stage, not at validation) invalidates the candidate-selection approach for this entry: validation must predict runner-liveness too. **B. Trigger:** candidate list ordering directly at Python.app — present in one short-lived build; **C. Isolation:** singular, configuration-bound; **D. Hypothesis:** LS activation semantics of bundle-registeriem interpreters (unverified); **Verification procedure:** not scheduled; avoidance verified by reordering; documented. Classification: **resolved-by-avoidance, hypothesis unverified**.

### 6.3 BUG-003

**A. Semantics:** build infrastructure defect (xattr contamination), unrelated to PR-4 code. **B. Trigger:** file(s) inside the product bundle carrying resource-fork/FinderInfo xattrs at signed test build time (source of the particular file untraced [U]). **C. Isolation:** environmental; unrepeated after cleanup (single posterior build clean [V]). **D. Hypothesis:** none deeper needed: codesign refuses signatures on files with those attributes (documented by macOS). **Verification procedure:** only needed if recurrence begins: trace via `xattr -l` walk over bundle contents before the sign step.

### 6.4 BUG-004

Confirmed environmental; root cause is the operating system itself (host lacks the tool `timeout`); remediation is procedural only (see BUG card). Not applicable for branching depth beyond this statement.

### 6.5 BUG-005

Defect inside a diagnostic artifact — from inspection alone: rawSpawn's tuple returns `(p, inPipe, outPipe)` while every read call uses index `1` (= `inPipe`). Any probe run would read an fd with no writer at all, making "silence" results unfalsifiable. Resolution: delete (or replace with Appendix A, which fixes the index and adds offsets/grandchild coverage). This artifact previously sampled wedge evidence improperly? No: the v3 form was never run; the v1/v2 lineage that DID run lacks this defect.

---

## 7. Cross-Defect Dependencies and Shared Failure Patterns

1. **Shared environmental/interpreter chain:** BUG-001 (H3 limb) and BUG-002 both live inside the two-hop Python launch chain (bin/python3 bootstrap → Python.app interpreter). RIGHT NOW this whole subsystem is treated as a single evidence domain: any candidate change to interpreter resolution must re-run both a wedge-context falsification AND the runner-liveness check (Python.app-direct precedent).
2. **Shared tooling-procedure pattern:** BUG-003, BUG-004, and BUG-005 are all *procedural integrity* issues (build-cache hygiene, toolchain assumptions, diagnostic artifact hygiene). Pattern remediation = a "test-campaign protocol" list (xattr clean; no `timeout`; delete probes; keep probe lineages versioned) applied before every verification session.
3. **Shared acceptance-gate dependency:** BUG-001 blocks OPE-003 (census) → blocks PR-4 commit → blocks OPE-002 final content; OPE-001 is the only closeout item executably independent of BUG-001's progress (already enumerated and hash-pinned [V]).
4. **NOT related (explicit reject)**: the historical fixed layers (shim xcrun sandbox write, SIGPIPE deaths, pool starvation, PID reuse) — no active component contributed by them today; they are recorded as load-bearing PROVEN fixes inside the committed code, which is supporting context, not active defect.

---

## 8. External Research and Source Evaluation

Searched today across: Foundation`Process` internal spawn path, `Pipe`/`FileHandle` EOF-handler semantics, posix_spawn file_actions docs, Python subprocess buffers, lsof, Subprocess adoption. Findings graded by relevance: **The only authoritative-verified fact chain** is procedural; no exact-match reported bug was found. All relevant sources below were retrieved via search on 2026-10-18 and are linked in §15.

### 8.1 Foundation Process `fd` accounting (addclose race) — top-rated hit

| Aspect | Assessment |
|---|---|
| **Source** | Swift Forums "Meet SwiftCommand…" — cites `apple/swift-corelibs-foundation` `Process.swift` ~L930-938: `findMaximumOpenFD()` + AddClose is "not atomic; file descriptors may be opened after findMaximumOpenFD() returns but before the process executes (the corresponding AddClose won't be called and the fd will remain open)." |
| **Provenance** | Community showcase + primary source citation; corelibs code is authoritative for POSIX-side implementation but **Darwin's Foundation is the closed-source variant that actually executes in our test host** — parity not guaranteed. Label accordingly |
| **Applicability to BUG-001** | Partial: the mechanism can leave *extra inherited fds* inside the spawned child (and possibly leak) — which explains EOF-not-propagating / inherited-fd noise, but alone doesn't explain *silent stdout for live children* while exit-children deliver in the same batch. **Conditionally relevant as a corroborating mechanism for H1/H2** the fd space described in E1 (Table of open fds at wedge) — E1 measures exactly that. Verdict: **Conditionally recommended evidence target**, no direct fix |
| **Synergy** | One of the hits explicitly notes `read(upToCount:)`+`Pipe` API design confusion — argues for E1 instrumentation and maybe moving past `Pipe` entirely |

### 8.2 SR-12080 — stderr `readabilityHandler` EOF race (swiftlang/swift-corelibs-foundation #3275)

- Open issue; maintainer/regular discussion; **Linux-labeled** ("macOS works fine") — macOS-specific applicability weak; but maintainer principle extracted: *"use waitUntilExit to know there is no more data; last data can arrive after termination; no doc guarantee"* — a race between Process termination and pipe data being delivered.
- Applicability: our launcher's stderr drain self-clears at EOF [V], matches this entropy surface; if Darwin behaves similarly under repeated quick child lifetimes, the *stderr* handler may keep its fd armed/nil'd at the wrong time — a candidate sub-component of H1's ghost. However this alone does not produce silent stdout.
- **Verdict: Supportive for E1/H1 surface, not root cause itself.** Also honestly notes that our launcher already avoids the strongest form of this bug (courses separate read paths between stderr handler and stdout blocking reads [V]).

### 8.3 The Subprocess package (swiftlang/swift-subprocess) — replacement track

- **Authoritative:** official Foundation project; pitch `0007-swift-subprocess` explicitly criticizes `Process` (Any-typed standard IO properties, Pipe ambiguity), and states brep package "would eventually replace `Process`"; macOS 13+ per troz migration report; WWDC26 announced v1.0 (third-party post; official release notes not verified here).
- **Applicability to BUG-001:** the package wraps posix_spawn directly with a cleaner fd/pipe contract and offers `preSpawnProcessConfigurator` on macOS (per README) — a modern alternative mechanism if the defect persists **outside the test host**.
- **Constraints:** new dependency in RT (an architectural/additive decision requiring owner delta ADJ precedent), min-macOS policy implications, PR-scope discipline (a PR-4-blocking swap would be a scope violation unless owner countersigns). **Verdict: Conditionally recommended — future PR candidate only, not the PR-4 fix.** Track `swift-subprocess` under ADR-2 amendment protocol if ever adopted.

### 8.4 Generic poison reports — rejected matches

| Source | Claim | Verdict |
|---|---|---|
| swift-corelibs-foundation #5197 "Async Process IO hangs 100% on Linux; fails on SECOND invocation" | Linux-only domain; author re-ran and confirmed second invocation failing | **Rejected as root cause** for macOS BUG-001; cited as genre-analog of "second spawn" pattern; do not assume same mechanism |
| Node.js issue #9413 "Second child process doesn't receive data" | Python multiprocessing stream buffering caused it (our root-cause surface is Swift-side; also different library) | **Rejected** |
| Forum 71261 "Trouble reading new data from standard output pipe" | Generic symptom (bytes not visible until process finish) | **Rejected** (buffering-of-C-runtime family; our children are already `-u` unbuffered [V code]); documents genre only |
| Apple Forums 690310 — "piping stdin/stdout is surprisingly tricky" | Apple-supported forum thread; general caution | Genre only |

### 8.5 posix_spawn/macOS man pages — semantics anchors [V-authoritative]

`posix_spawn_file_actions_adddup2` description (keith.github.io xcode-man-pages mirror + Arch/IBM/QNX pages): file actions transform the child's fds pre-exec; `addinherit_np` *clears FD_CLOEXEC* in the new image. Two load-bearing conclusions for our code: (1) dup2'ed pipe write ends survive exec; (2) CLOEXEC flags on *new* descriptors matter, and our launcher doesn't add/close or set inheritance explicitly beyond Foundation's defaults, meaning behavior depends on Foundation's `Pipe` CLOEXEC policy [U — measured only by Experiment E1's fd list].

### 8.6 Python sidecar buffering literature (luca.dev, tbrink.science, docs.python.org, realpython)

Supports our launcher's `-u` choice and the readline-vs-iteration guidance engraved into the stub script (line-buffered, flush-per-line) [V code]. **Verified as implemented; no bug.** Python sidecar-side behavior was already pinned in our conf suite; no practice changes recommended.

---

## 9. GitHub Issues, Pull Requests, Commits, and Relevant Changes

**From our repository (no remote-state changes during this investigation; origin is recorded but nothing was pushed or fetched):**

| Ref | Establishes | Does NOT establish |
|---|---|---|
| commit `56bf5d8` (PR-3) | 8 files, 454 insertions: `MirageWireTypes.swift` (129 lines, 28-action set/JSONValue/envelope), `MirageTransport.swift` (21), `MirageClient.swift` (76), `MirageProtocolConformanceTests.swift` (193), 3 ADR flips to ACCEPTED, merge-log refresh | Nothing about PR-4 runtime or its bug: PR-4 files are all untracked/uncommitted |
| commit `13ad970` (PR-2) | ADR-2/4/5 drafts + log refresh | — |
| commit `ef198c5` (PR-1) | Merge governance scaffold, baselines, evidence | — |
| Untracked working tree (the failing surface) | `MirageChildProcess.swift` (17,776 B, mtime 15:47:04 today), `MirageSidecarSupervisor.swift`, `MirageProtocolConstants.swift`, 4 test suites + probe | Cannot diff against a commit: it exists only in the working tree; there IS no historical regression boundary for BUG-001 (component is new) |
| `docs/integration/` (committed copies: merge-log.md, adr/, phase1/) | repo-internal evidence contract (committed snapshot) | Working master merge-log lives outside repo (`Merge Phase/merge-log.md`) by design — the snapshot must be refreshed in the PR-4 commit |
| BUG-001 repro xcresult | externalized 2026-10-18 eve: `Merge Phase/evidence/BUG-001-repro-2026-10-18_17-51-51.xcresult` (+ LogStoreManifest copy); the empty 17:51:31/17:51:39 companions were not retained | .rt-dd debris deleted after the move [V] |

**Upstream (reuse-potential) project GitHub surface:** `swiftlang/swift-corelibs-foundation` #3275 (open, Linux-labeled, EOF-race), `swiftlang/swift-foundation` proposal `0007-swift-subprocess` (accepted-track design note; real package at `swiftlang/swift-subprocess`). No upstream issue matches our macOS batch wedge symptom exactly → this remains an environment-specific instance (searched, not proven absent).

---

## 10. Candidate Solutions and Technical Feasibility

Candidates ranked per the directive's criteria (root-cause alignment > evidence > compatibility > implementation/risk > conclusion strength).

**C1 — Kernel-level discriminator first (E1, Appendix A) → outcome-directed fix.** *Verdict: Recommended (next step).* Root-cause alignment: it executes no fix; measures H1/H2/H3 at kernel offsets. Complexity: minimal (temporary probe, no production change). Risk: none outside `.rt-dd` if used before any census; probe deleted after. Compatibility: unchanged codebase. This is the only path that converts current unknowns into deterministic classification; every other candidate is keyed off it.

**C2 —_IF E1 ⇒ bytes-in-pipe (H1/H2 class)_ — reader/ownership hardening in `MirageChildProcess.swift`:** replace the FileHandle-mediated blocking read (`read(upToCount:)`) with a bare `read(2)` on an explicitly held `fileDescriptor` obtained once at launch; explicitly `close(stdoutRead)` + `close(stderrRead)` at teardown *before* the transport deallocates (today only `closeWrite` happens — [V code]); never nil the stderr handler at EOF *before* draining finished (SR-12080's principle reversed: use `waitUntilExit()`-budgeted grace to rule out late data [maintainer-sourced principle]; simplest: keep the current guarantee but add the close-before-dealloc). *Verdict: Conditionally recommended* — small, root-cause-shaped if E1 confirms H1/H2; regression test required (the existing 14 PR-4 tests already exercise every lane; plus strict full-batch cycl).

**C3 — _IF E1 ⇒ bytes-never-landed (H3 class)_ — interpreter/launch-path re-baseline:** switch locator target to a *non-bundle-bootstrap* interpreter posture (Homebrew's cellared plain install or a managed copy), re-validating against both BUG-002's runner-liveness trap and the sandbox. *Verdict: Experimental.* Root-cause alignment: only conditional on H3; doubles as a way to decouple from the Python.app bootstrap double-spawn entirely. Risk: environment re-baseline; MUST not adopt Python.app-direct (BUG-002).

**C4 — Split-spawning suites into per-suite isolated runner invocations** (PR-4 verification runs each spawning suite under its own `xcodebuild test-without-building` select list, or collapse testing to 2-3 consolidated spawning test bodies as today's probe demonstrated is possible). *Verdict: Recommended as the PR-4 interim acceptance path* (already session-proven: all isolated/combined-green contexts stayed green); weakens batch-order guarantees if adopted as permanent practice — acceptable interim, documented as environment finding. Root-cause alignment: none (bypass); evidence for behavior in production contexts absent (H3 unclassified) — that barrier still requires E1.

**C5 — Adopt `swift-subprocess` package for the child-process layer.** *Verdict: Conditionally recommended — future PR only* (needs owner countersign + macOS 13+ dependency posture + regression test cutover); improves long-term maintainability by moving off `Process`+`Pipe` internals; **not** the PR-4 fix; record under ADR-2 amendment protocol.
   - *Rejected variant:* Node-style "collect after exit" reading patterns — incompatible with this engine's framing/timeout contract [V design].

**C6 — Commit PR-4 immediately with the anomaly documented as environment finding (skip E1).** *Verdict: Rejected as the sole path* (root cause unclassified, assures no production-side closure; the acceptance note would carry an unresolved High defect); **Conditionally acceptable** ONLY after E1 runs and produces a written classification, per the directive's own standard — i.e., sequence = C1 → C4/one of C2/C3 → closeout.

---

## 11. Recommended Remediation Plan

Ordered, each step with verification and acceptance criteria.

**R1 — Execute E1 (kernel discriminator)** *(owner: engineering; est. 15 min)*
- Steps: insert Appendix A probe (temporarily) → build-for-testing → run the probe suite twice (first run warms locator; second run measures N cycles) → parse outputs into the classification table.
- Acceptance: a written classification row for each wedge occurrence: `{fdPairliness, secondReader?, ourOffsetR, childWriteOffset, grandchildIdentity}` → verdict H1/H2/H3 per §10 mapping.
- If a wedge doesn't reproduce in 3 probe cycles → re-run the established batch repro (pin-full style) and capture E1 inside the *real* failing suite context via the probe's `lsof` tracer invoked by whichever cycle wedges.
- Post-experiment: DELETE the probe file (BUG-005 rule).

**R2 — Apply the outcome-directed fix**
- If H1/H2: implement C2 changes in `MirageChildProcess.swift` only; no API change; keep `MirageChildChannels` seams intact; re-run all 14 PR-4 tests + 147 baseline.
- If H3: implement C3 (locator re-baseline with validated execution AND runner-liveness checks; no Python.app-direct); re-pin snapshots in the merge log; re-check BUG-002's avoidance precondition remains satisfied.
- Acceptance: full batch (pin + lifecycle suites in one runner) green; census recorded.

**R3 — PR-4 closeout (executable regardless of BUG-001's final mechanism, once full-batch green):**
1. Delete `MirageReproProbeTests.swift` (BUG-005).
2. Census run: `xcodebuild test` full suite → record executed/failed/skipped (expect 161/0, smoke accounting per M-017 precedent).
3. Stub-cover cleanup (OPE-001): execute the hash-family deletion with per-file re-verification (Class Δ, owner countersign); container check → final count recorded in M-020; keep `.DS_Store` unless owner says otherwise.
4. Optional owner-approved: real-engine smoke (OPE-004) with disposable temp DB.
5. Merge-log entries M-019/M-020 (runtime, invariants, BUG-001 evidence trail, cleanup results); refresh committed copy `docs/integration/merge-log.md` per M-012 doctrine.
6. Commit PR-4 on `merge/integration` (runtime + tests + log refresh; 8 dirty owner files untouched).
7. Then proceed to PR-5 pipeline (identity map + one-book import per S16-ES-1); ADR-7+S10-ES-3 draft remains a pre-PR-6 owner review item; ADR-3 gates PR-8.

**R4 — Test-campaign protocol codification (BUG-003/BUG-004/BUG-005 hygiene):** a small "session protocol" block to be included in M-019/M-020 and repeated before future verification sessions: (a) `xattr -cr` build products if CodeSign trips; (b) never `timeout` on this host; (c) no diagnostic probe file may exist at commit time; probe lineages version-controlled under `evidence/` when they produce a written result.

**R5 — Regression prevention for BUG-001 if the fix is C2:** the committed suites already pin: banner framing, junk/nostatus masking, version drift, ladder exhaustion, typed faults, SIGTERM escalation, pid guard. Add one consolidation batch test (temporary during the fix branch) asserting a 20-cycle spawn-exchange-teardown loop raises zero `responseTimeout` wedges — retiring it at closeout would risk reintroducing batch-fragility; keeping it costs runtime (each cycle ~1 s). Mark as a **time-budget regression** to run explicitly (not in every census) unless fragility re-surfaces.

**R6 — Process-level regression test for BUG-002:** add pin assertions that `MiragePythonLocator`'s candidate list does **not** include `Python.app/Contents/MacOS/Python` (cheap static pin; protects the avoidance). *Owner approval to add a test-file line is implied by PR-4 scope; note it in M-019.*

---

## 12. Regression Testing and Verification Criteria

| ID | Criterion | Method | Status now |
|---|---|---|---|
| RT-A | PR-3 regression baseline | Full suite ≥147/0 unchanged | Holds [V M-017] |
| RT-B | PR-4 isolation green | Each spawning suite green individually | Holds [V session] |
| RT-C | PR-4 batch green | pin + lifecycle in ONE runner, 0 failures | **BLOCKED by BUG-001 until R1/R2** |
| RT-D | Census arithmetic | executed count == 133+6+8 (+1 smoke if enabled), failed == 0 | Pending OPE-003 |
| RT-E | Cover hygiene | Container covers census recorded; cleanup executed under countersign; library references unchanged | Census done [V]; cleanup pending owner |
| RT-F | Anti-regression pads | BUG-002 static pin (R6); optional 20-cycle batch loop (R5) | Pending after R1/R2 |
| RT-G | Smoke disposal per run | Real-engine smoke DB is disposable; prod DB never touched | Design enforced by suite [V code]; never executed (OPE-004) |
| RT-H | Merge-log discipline | M-019/M-020 written before commit; ante/post census in both | Pending |

Deliberately *not* fixed to claim: "selectively-passing batch" runs count toward RT-B/RT-C equivalently — they only satisfy RT-B; a full-runner RT-C evidence row is still required to close the PR-4 gate under S8-ES-5/S16-ES-1 language.

---

## 13. Unresolved Questions, Blockers, and Evidence Gaps

| # | Question / Gap | Evidence status | If resolved |
|---|---|---|---|
| 1 | Root cause of BUG-001 (H1 vs H2 vs H3) | **Unclassified** — E1 designed but not run | Unblocks R2 fix choice |
| 2 | Wedge-event `lsof -o` offset data (was captured for none of the historical wed per) | Missing [artifacts not retained] | Provided by E1 going forward |
| 3 | Whetherwedged child's fds belong to launcher pid or python grandchild | Unknown (single earlier pairing session-phase unverified which pid) | E1 enumerates both |
| 4 | Whether the "latched" (post-permanentDown everything ✗) and "elementary" (single-wedge) signatures are one mechanism | Unverified | E1 N-cycle matrix |
| 5 | Whether the wedge persists OUTSIDE the test-host/sandbox context (production posture) | Untested (no production path wired) | Post-fix soak under PR-5 wiring |
| 6 | Foundation Darwin parity for `addclose` fd race effect (section 8.1) | Unverified (closed-source Darwin) | Indirect measurement via E1 fd census; no upstream fix to wait for |
| 7 | `.enabled(if:)` census semantics (smoke counted as skipped?) under Swift Testing | Unverified | Observed during RT-D census |
| 8 | Earlier campaigns' pre-`.rt-dd` xcresult artifacts | Retrievable in default DerivedData; low value | Optional archaeology only |
| 9 | Run-time app behavior with 39 orphan covers + `.DS_Store` (app-side cleanup behavior) | Out of this task's scope | NEW-DE-12 session |

Blockers: only BUG-001 (needs R1) — everything else is procedural.

---

## 14. Prioritized Next Actions

1. **P0 — R1 (Appendix A probe, two runs)**; classify per §6.1-D; delete probe after.
2. **P0 — R2 fix tier chosen by R1 outcome; re-run batch (RT-C).**
3. **P1 — R3 closeout chain** (RT-A/B/D/E/H): delete probe file, census, OPE-001 cleanup under owner countersign, M-019/M-020, repo snapshot refresh, PR-4 commit.
4. **P1.5 — owner-gated in parallel:** OPE-001 countersign; OPE-004 optional real-engine smoke; decision whether R5/R6 regression pads enter the commit.
5. **P2 — PR-5 development begins** (identity map stratum + one-book import; nothing import-critical depends on BUG-001's mechanism once RT-C green).
6. **P2 — attach the research links** (§15) into the permanent evidentiary record (M-019/M-020 as URLs with dates).

---

## 15. References and Source Links

Primary technical (retrieved 2026-10-18 via web search):

1. swift-command + Foundation `findMaximumOpenFD`/`AddClose` non-atomicity discussion: <https://forums.swift.org/t/meet-swiftcommand-a-new-swift-package-that-makes-creating-child-processes-very-easy/59701>
2. SR-12080 stderr readabilityHandler EOF race (swiftlang/swift-corelibs-foundation #3275): <https://github.com/swiftlang/swift-corelibs-foundation/issues/3275>
3. Async Process IO hangs (incl. "second invocation") — Linux context: <https://github.com/swiftlang/swift-corelibs-foundation/issues/5197>
4. Subprocess pitch (Foundation project) `0007-swift-subprocess`: <https://github.com/swiftlang/swift-foundation/blob/main/Proposals/0007-swift-subprocess.md>
5. `swiftlang/swift-subprocess` repo: <https://github.com/swiftlang/swift-subprocess>
6. Windows-analog standard-output deadlocks (genre only): <https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.process.standardoutput>
7. posix_spawn family semantics: Arch man3 mirror <https://man.archlinux.org/man/posix_spawn.3.en>; macOS adddup2/addclose/addinherit_np (keith mirror): <https://keith.github.io/xcode-man-pages/posix_spawn_file_actions_addopen.3.html>
8. Apple official `FileHandle` ownership/dealloc contract: <https://developer.apple.com/documentation/foundation/filehandle>
9. Apple `Process.standardOutput` API contract (Any-typed): <https://developer.apple.com/documentation/foundation/process/standardoutput>
10. Apple forums caution child stdio piping: <https://developer.apple.com/forums/thread/690310>
11. Generic "no data until exit" symptom reports (genre only): <https://forums.swift.org/t/trouble-reading-new-data-from-standard-output-pipe/71261>
12. Python subprocess buffering doctrine: <https://docs.python.org/3/library/subprocess.html>, <https://lucadrf.dev/blog/python-subprocess-buffers>, <https://tbrink.science/blog/2017/04/30/processing-the-output-of-a-subprocess-with-python-in-realtime>
13. Subprocess adoption reports / migration notes: <https://troz.net/post/2025/process-subprocess>, <https://mjtsai.com/blog/2025/10/30/swift-6-2-subprocess/>
14. lsof usage for pipe identification (Linux-genre; macOS port to verify in E1): <https://superuser.com/questions/401066/find-what-process-is-on-the-other-end-of-a-pipe>
15. Node.js analogous-but-rejected issue: <https://github.com/nodejs/node/issues/9413>

Internal (this repo / merge phase):

16. `Merge Phase/merge-log.md` (M-001…M-018) — governance + per-PR evidence chains.
17. `Merge Phase/RT_Mirage_Codebase_Merge_Playbook.md` — §16 S16-ES-1 PR ladder; §8 S8-ES-5 house suite standard; §5.2 acceptance criteria.
18. `Reading Tracker/Features/Mirage/MirageChildProcess.swift`, `MirageSidecarSupervisor.swift`, `MirageProtocolConstants.swift` (untracked PR-4 runtime).
19. `Reading TrackerTests/MirageStubSidecarSupport.swift`, `MirageHandshakePinTests.swift`, `MirageSidecarLifecycleTests.swift`, `MirageRealEngineSmokeTests.swift` (untracked PR-4 tests).
20. `.rt-dd/Logs/Test/Test-Reading Tracker-2026.10.18_17-51-51--0400.xcresult` — BUG-001 repro artifact.

---

## Appendix A — Corrected forensic probe (temp-only; never commit)

Purpose: classify H1/H2/H3 per §6.1-D. Replace `MirageReproProbeTests.swift` with this content temporarily, run the suite **twice**, then DELETE the file. Writes full `lsof -o -O` dumps for the launcher pid, its python grandchild, and the test host into `/tmp/mirage-probe-forensics-<date>.txt` plus condensed `Issue.record` evidence.

```swift
import Foundation
import Testing
@testable import Reading_Tracker

// TEMPORARY PR-4 forensic probe (DELETE BEFORE COMMIT; not for the suite):
// raw Foundation spawns only — zero RT transport machinery; discrimitates
// BUG-001's H1 (ghost reader) / H2 (mis-wired read fd) / H3 (bytes never
// landed) via `lsof -o -O` byte-offsets on ALL relevant pids while a wedge
// holds. Children: banner-junk (print+exit) then version-drift (print+alive)
// then version-drift control, N=3 repetitions.
@Suite("Mirage Forensic Probe (TEMP - delete)")
@MainActor
struct MirageForensicProbeTests {
    @Test func wedgeClassification() async throws {
        let outPath = "/tmp/mirage-probe-forensics-\(Date().timeIntervalSince1970).txt"
        var report = ""
        var procs: [Process] = []
        defer { for p in procs where p.isRunning { p.terminate() } }
        let python = try MiragePythonLocator.shared.executableURL()

        func rawSpawn(_ mode: String) throws -> (Process, Pipe, Pipe) {
            let p = Process()
            p.executableURL = python
            p.arguments = ["-u", "-c", StubSidecarScript.source, mode]
            let inPipe = Pipe(), outPipe = Pipe(), errPipe = Pipe()
            p.standardInput = inPipe; p.standardOutput = outPipe; p.standardError = errPipe
            try p.run(); procs.append(p)
            return (p, inPipe, outPipe)
        }
        // deferred close of MY write side to give the child EOF at death
        // Close OUR stdin write end — ONLY after the read verdict: closing
        // early would EOF the child's readline() and extinguish the wedge
        // state this probe exists to capture.
        func shim(_ child: (Process, Pipe, Pipe)) {
            try? child.1.fileHandleForWriting.closeFile()
        }
        func readChunkRaw(_ outPipe: Pipe, seconds: Double, box: ThreadSafeBox<Data?>) {
            let fd = outPipe.fileHandleForReading.fileDescriptor
            Thread.detachNewThread {
                var buf = [UInt8](repeating: 0, count: 256)
                let n = read(fd, &buf, buf.count)   // Darwin read(2): real kernel object
                box.set(n > 0 ? Data(bytes: buf, count: min(n, buf.count)) : (n == 0 ? Data() : nil))
            }
        }
        func awaitRead(_ box: ThreadSafeBox<Data?>, seconds: Double) -> Data? {
            for _ in 0..<Int(seconds * 20) {
                if let v = box.get() { return v.isEmpty ? nil : v }
                Thread.sleep(forTimeInterval: 0.05)
            }
            return nil
        }
        func lsof(_ pid: Int32) -> String {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
            p.arguments = ["-o", "-O", "-p", String(pid)]
            let out = Pipe(); p.standardOutput = out; p.standardError = Pipe()
            do { try p.run() } catch { return "spawn-failed \(error)" }
            let d = out.fileHandleForReading.readDataToEndOfFile()
            p.waitUntilExit()
            return "### lsof pid=\(pid) rc=\(p.terminationStatus)\n" + String(decoding: d, as: UTF8.self)
        }

        for cycle in 0..<3 {
            // (1) junk cycle (print+exit child) — the established poison trigger
            let junk = try rawSpawn("banner-junk")
            let junkBox = ThreadSafeBox<Data?>()
            readChunkRaw(junk.2, seconds: 3, box: junkBox)
            let junkLine = awaitRead(junkBox, seconds: 3)
            report += "cycle \(cycle) A junk n=\(junkLine?.count ?? -1) '\(junkLine.map { String(decoding: $0, as: UTF8.self) } ?? "SILENT")'\n"
            shim(junk)
            for _ in 0..<40 where junk.0.isRunning { Thread.sleep(forTimeInterval: 0.05) }

            // (2) drift child (print+alive) — candidate wedge; full forensics if silent
            let drift = try rawSpawn("version-drift")
            let dBox = ThreadSafeBox<Data?>()
            readChunkRaw(drift.2, seconds: 3, box: dBox)
            let banner = awaitRead(dBox, seconds: 3)
            report += "cycle \(cycle) B drift n=\(banner?.count ?? -1)\n"
            if banner == nil {
                let launcherPid = drift.0.processIdentifier
                var grands = ""
                let q = Process()
                q.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
                q.arguments = ["-P", String(launcherPid)]
                let qOut = Pipe(); q.standardOutput = qOut; q.standardError = Pipe()
                if (try? q.run()) != nil {
                    let d = qOut.fileHandleForReading.readDataToEndOfFile(); q.waitUntilExit()
                    grands = String(decoding: d, as: UTF8.self).split(separator: "\n").map(String.init).filter { !$0.isEmpty }
                }
                report += lsof(launcherPid) + "\n"
                for g in grands { report += lsof(Int32(g) ?? -1) + "\n" }
                report += lsof(Int32(ProcessInfo.processInfo.processIdentifier)) + "\n"
                report += "MY-STDOUT-READ-FD=\(drift.2.fileHandleForReading.fileDescriptor)\n"
                Issue.record("WEDGE cycle \(cycle): see \(outPath)")
                drift.0.terminate()
                for _ in 0..<40 where drift.0.isRunning { Thread.sleep(forTimeInterval: 0.05) }
            } else {
                shim(drift)
                drift.0.terminate()
                for _ in 0..<40 where drift.0.isRunning { Thread.sleep(forTimeInterval: 0.05) }
                try? drift.2.fileHandleForReading.closeFile()
            }

            // (3) drift2 control (heals-write-off after wedge)
            let drift2 = try rawSpawn("version-drift")
            let d2Box = ThreadSafeBox<Data?>()
            readChunkRaw(drift2.2, seconds: 3, box: d2Box)
            let banner2 = awaitRead(d2Box, seconds: 3)
            report += "cycle \(cycle) C control n=\(banner2?.count ?? -1)\n"
            try? drift2.2.fileHandleForReading.closeFile()
            shim(drift2)
            drift2.0.terminate()
            for _ in 0..<40 where drift2.0.isRunning { Thread.sleep(forTimeInterval: 0.05) }
        }
        try? report.write(toFile: outPath, atomically: true, encoding: .utf8)
        Issue.record("probe report file: \(outPath)")
    }
}

/// Minimal thread-safe cell for crossing detached-thread boundaries.
nonisolated final class ThreadSafeBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: T?
    func set(_ v: T) { lock.lock(); value = v; lock.unlock() }
    func get() -> T? { lock.lock(); defer { lock.unlock() }; return value }
}
```

Expected classification from its outputs:

| Observation at wedge | ⇒ Mechanism |
|---|---|
| Two fds on the same pipe in the parent, the foreign one's offset advancing while ours is 0 | **H1 confirmed** (ghost consumer) → implement C2 |
| Only ours exists, our offset stays 0 while the child's write-end offset is > 0 (or a grandchild's fd1 points at our pipe with bytes) | **H2-class ("in the pipe unread", our reader mis-wired or genuinely stuck)** → implement C2 |
| Child (or grandchild) fd1 does NOT resolve to our pipe device/object, or all offsets are 0 with the child in readline | **H3 confirmed** (bytes never landed) → implement C3 (interpreter re-baseline) |
| Repeatability column: does the control drift cycle (phase C) deliver? (In the earlier session higher cycles delivered after the wedge — expect it to hold) | Anchor for transient-window semantics |

*End of main body.*

---

## Postscript · Resolution executed same evening (2026-10-18) — §R0–§R5

### §R0 Environment rectifications (BUG-003, BUG-005)

- **BUG-003 root cause refined:** the CodeSign "detritus" is stamped by **iCloud File Provider** — `com.apple.fileprovider.fpfs#P` + `com.apple.FinderInfo` on Desktop-synced paths; `.rt-dd` (inside the repo, on Desktop) gets re-stamped between cleanup and codesign. Fix: build against the **default DerivedData** (outside fileprovider monitoring) — `TEST BUILD SUCCEEDED` repeatedly without any xattr dance. The R4 protocol's message stays the same (don't build test products under the iCloud-synced repo dir).
- `.rt-dd` (449 MB build debris) **deleted from the repo** after evidence externalization: BUG-001 repro xcresult now lives at `Merge Phase/evidence/BUG-001-repro-2026-10-18_17-51-51.xcresult` (+ LogStoreManifest copy). Repo tree back to 8 dirty docs + 7 untracked Mirage files.
- **BUG-005 resolved:** the probe file was deleted before any commit (its v3 lineage was never compiled; it was superseded same-day by the corrected forensic probe below).

### §R1 Probe executed — BUG-001 classified (E1, Appendix A corrected probe)

Provenance: probe temporarily replaced the v3 file; suite `MirageForensicProbeTests/wedgeClassification()`; 3 cycles × 4 phases per run; evidence = the forensic text file issue-recorded per run (`/tmp` → app-container tmp). Run A = pre-fix, run B = post-fix.

Run A (pre-fix) — the previously intermittent wedge became **deterministic**:

| Cycle | A mach-junk | B raw-drift `read(2)` | C mach-drift (FileHandle path) | D raw-control |
|---|---|---|---|---|
| 0 | `fault:notJSON` ✓ | **delivered n=20** | **`responseTimeout(6.0)` WEDGE** | delivered n=20 |
| 1 | `fault:notJSON` ✓ | delivered | WEDGE | delivered |
| 2 | `fault:notJSON` ✓ | delivered | WEDGE | delivered |

Classification per Appendix A's table:

- **H3 falsified** — bytes land in the pipe: the raw reader received the banner during every cycle (children behave identically at the kernel level).
- **H1 falsified** — the *same pipe object* delivers to a raw reader inside the wedge cycle; nothing eats the stream (no ghost consumer).
- **H2 confirmed, machinery-local** — the wedge lives in *our read path*: Foundation's `FileHandle.read(upToCount:)` on a launcher-cycled pipe wedges forever while bare `read(2)` on the same-shaped pipe is immune. `lsof -o` offsets were never needed — the B/C split discriminates directly.

### §R2 C2 fix applied (`MirageChildProcess.swift`)

1. `readChunk` = **one raw `read(2)`** on the descriptor captured once at launch (EINTR retry; `n==0` → empty Data = EOF; `n<0` → typed `pipeReadFailed(errno)`). No FileHandle read API remains on the child-pipe transport path (the locator's one-shot validator `readToEnd` is intentionally untouched).
2. `closeRead` = idempotent epoch disposal (`MirageOnceCloser`): nil the stderr `readabilityHandler` **first**, then close our stdout+stderr read handles; called at all three end-of-epoch sites (teardown / exchange-catch / reader-timeout), always after kill+reap, guaranteed reader-free by the group-join discipline.

Post-fix probe (run B): **all phases delivered 3/3** — the deterministic wedge was eliminated (A/B/D unchanged healthy; C now `delivered` every cycle).

### §R3 Two deeper census failures surfaced by C2 — both fixed

| Census failure | Root cause | Fix |
|---|---|---|
| `oversizedLineRaisesTypedFaultAndKillsChild` — "expected oversizedLine" | The per-line cap was masked by Foundation chunk boundaries: with raw `read(2)` the whole 201-byte line (x's + LF) arrived in **one** chunk, so the newline branch returned it before the no-LF stream-cap check ever fired | `blockingReadLine` now enforces the cap on the **complete line** when a newline is found (unbounded no-LF growth check retained) — a line over the limit faults even when its LF rides in the same chunk |
| `pinnedVersionHandshakesToReadyAndServes` — `fields.isEmpty` | The test's own comment ("echoes an empty result") contradicted the stub it actually drives: mode `version-ok` answers **every** line with `result {"api_version":"1.0.0"}`; handshake, round-trip and correlation all passed — only the payload expectation was wrong | Assertion aligned to the stub contract verbatim: `fields == ["api_version": "1.0.0"]`; the pin's protective behaviors (acquire → ready → serve → pid-file guard → shutdown) unchanged |

### §R4 Verification + closeout (full record in merge log M-019/M-020)

- PR-4 suites green in **one runner** (pin 6 + lifecycle 8, `.serialized`): `TEST EXECUTE SUCCEEDED`.
- Full default census: `TEST SUCCEEDED`, result **Passed** — **138 executed passed / 0 failed / 1 skipped** (the skip is `MirageRealEngineSmokeTests`, env-gated `.enabled(if:)`); suite level: conformance 14/14, pin 6/6, lifecycle 8/8; plan total 139 nodes (incl. UI-target tests).
- **Census arithmetic note:** M-017's "133 baseline + 14 = 147" predates the current plan selection (the committed phase-1 log carries no test counts); today's per-suite breakdown is the pinned record henceforth. Zero failures across every suite in the current selection.
- Real-engine smoke **not run** (env-gated; owner decision pending — OPE-004).
- Covers after census: **45 files = 15×3 stub-hash family** (pre-run 39 = 13×3; +6 from today's two full runs via `CoverStorePinsTests` stub pins — standing note NEW-DE-12 holds). OPE-001 deletion (now the 45-file hash family) remains **owner-gated** (Class Δ, M-013 precedent).

### §R5 New standing discipline

- No FileHandle read APIs on long-lived child-pipe transports in this codebase (candidate ADR-2 amendment §—; C5 `swift-subprocess` adoption remains a countersigned future PR).

*End of document.*
