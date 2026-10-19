# §15.3 recovery rehearsal log — S15-ES-3 artifacts (2026-10-18 session)

Protocol: every rehearsal item produces this artifact — steps, timestamps, observed
outcomes, operator, commit SHA. Executor: integration agent (machine work under the
owner's "resume and continue" mandate); reviewer/counter-sign: owner at session close.

Default state at rehearsal start: branch `merge/integration` at `5945538` (PR-6 committed),
working tree = the 8 owner-dirty docs (untouched, verified item 5 below).

---

## R1 — Code rollback rehearsal (in vivo)

**Item executed:** revert-to-PR-5-state — the pre-PR-6 tree — with the full census run on
that tree (the rollback target-state RT-only behavior check).

- **Steps:** `git worktree add <temp>/rt-revert-rehearsal 0842b2b --detach` (the PR-5 tree,
  pre-PR-6); `xcodebuild test` full census in that worktree (a project path outside the
  iCloud Desktop stamp territory — the BUG-003 discipline); verdict read; `git worktree remove`.
- **Timestamps:** worktree created 21:07 UTC (2026-10-18); census completed 21:19:50.
- **Observed outcome:** `** TEST SUCCEEDED **`; zero failing test cases across all suites
  (console census of `failed on` patterns = 0); both UITest runners green; Swift Testing
  suites all green on the reverted tree. RT-only behavior verified — the reverted tree
  builds, tests, and its census is green without PR-6's surface.
- **Operator:** integration agent; commit SHA of the rehearsal target: `0842b2b`.
- **Evidence:** `/tmp/revert-rehearsal.log` (session-transient; verdict quoted above).

**R1 scope note (honest split):** S15-ES-3 names "revert PR-4 through PR-7 individually."
Tonight executed the PR-6→PR-5 target-state rehearsal with a live census. The remaining
individual rollbacks (PR-7→PR-6, PR-5→PR-4, PR-4→PR-3) are scheduled on the same protocol
(command shape recorded here: detached worktree at the prior commit + full census + verdict
record), to be executed ladder-tail-first as each PR closes. The protocol is NOT fictional —
it produced tonight's artifact — but the four-revert ladder itself is only 1/4 executed.

## R2 — Sidecar crash recovery (test-anchored, live receipt from tonight's census)

- **Named tests (census-green tonight):** `MirageSidecarLifecycleTests.crashOnRequestRaisesTypedEOF`
  (child killed ⇒ typed EOF, no silent retry); `.responseTimeoutFaultLeadsToRecovery`;
  `.neverRespondingChildTimesOutAndIsReaped` (reaping under a hung child);
  `.sigtermEscalatesToSigkillWhenIgnored` (escalation ladder); `.compliantChildShutdownHonorsSigterm`
  (graceful shutdown); `.oversizedLineRaisesTypedFaultAndKillsChild`; `.foreignPidGuardBlocksThenReleases`
  (foreign-pid guard releases). Real-engine kill-9-at-staged-points variants remain part of
  the opt-in real-engine ladder (single-lifecycle doctrine, M-024), scheduled with the
  remaining R1 rollbacks.
- **Operator:** integration agent; census receipt 2026-10-18 (see R4's census line).

## R3 — Failed initialization (corrupt/disabled state → contained posture)

- **Named tests (census-green tonight):** `MirageIdentityDriftTests.mapUnreadableBlocksImportFailClosed`
  (malformed map file ⇒ `.mapUnreadable`, fail-closed, no write);
  `MirageFeatureLifecycleTests.disabledFeatureNeverRunsTheStatusRunner` (disabled feature ⇒
  no spawn — the contained state).
- **Operator:** integration agent; same census receipt.

## R4 — Invalid mapping recovery (stale/mismatched fingerprint flow)

- **Named tests (census-green tonight):** `MirageIdentityDriftTests.bytesChangeOrphansEntryWithSourceChangedAndRefuses`
  (hash mismatch ⇒ typed refusal + `source-changed` orphaning persisted);
  `digestMismatchRefusesSilentMapping`; engine-verified absence ⇒ `edition-gone` orphaning
  (`MirageStatusSurfaceTests.absentInventoryRowOrphansAndCarriesNoCounts`), and the
  real-engine single-lifecycle proof re-ran all five proofs live this session (~2 s, green).
- **Operator:** integration agent; receipt: real-engine suite `MirageIdentityRealEngineImportTests`
  passed 21:0x UTC with `TEST_RUNNER_MIRAGE_REAL_ENGINE_DIR` + diagnostic flag.

## R5 — Documented data-backup restore (disposable data), SQLite discipline verified from source

- **Discipline verification (from engine source, not assumptions):** Mirage's approved backup
  path EXISTS: `Ledger.backup(destination)` — SQLite **online backup API** (`conn.backup`) +
  `PRAGMA integrity_check` (`src/miragev10/storage/ledger.py:2235-2252`, §14.4/§46 R3 of the
  engine's own docs). Engine's own content-level round-trip test
  (`tests/test_reversible_history.py::test_backup_round_trip_and_integrity`) re-pinned LIVE
  tonight: `Ran 1 test in 0.021s — OK`.
- **System-level restore rehearsal (this Mac, disposable data only):** python API rehearsal —
  fresh `Ledger` on a disposable path → `backup()` → integrity `ok` → reopen **from the backup
  copy** → schema version carried (`ledger@0.0.10`). NO live/hot file copies anywhere.
- **Documented gap (named policy):** the backup method is NOT exposed on the wire's 28-action
  set and NOT exposed via the engine CLI — so the system-level trigger remains engine-side
  (operator-led, from the engine process itself) until a countersigned wire amendment. Owner
  of that gap: J. (engine owner). RT must NEVER copy the live ledger file directly (policy
  restated here); RT-side policy triggered by nothing tonight.

---

## Census receipts for this scaffold

- Opt-in-engaged census (2026-10-18, this session, current tree `5945538` + PR-7 files):
  **186 passed / 0 failed / 0 skipped** (env flags engaged the two gated suites).
- Standing default census for the PR-7 commit: see M-027 (runs with no env gates; the two
  opt-in suites report as the standing skip nodes).
- Census grep gate (PR-6): Features/Reader carries Mirage references ONLY in
  `EPUBReaderScreen.swift`.

## R6 — Packaged-runtime staging + spawn-from-bundle (PR-8 / ADR-3, executed live)

- **Executed tonight:** `scripts/stage-mirage-runtime.sh` ran end-to-end — pinned
  python-build-standalone fetch (sha256 `5a9cdbb8…a875` recorded as the script's refusal
  pin), interpreter 3.12.7, engine tree copied VERBATIM at the pinned SHA
  (`81422613610701d81956394d9601bcb61e2938e9`), 47 MB bundle laid out with
  `RUNTIME-MANIFEST.json` checksums. Spawn smoke FROM the bundle, self-hosted with the
  bundle's own `bin/python3.12` driving the probe: banner `ready`, `version` and
  `books_list` exchanged, clean SIGTERM teardown (`exit -15` = terminated by design).
- **Fixture-fidelity note:** the sidecar bootstraps `sys.path` at `<script>/../src`
  (pinned `mirage_sidecar.py:22-23`), so the bundle reproduces the engine's OWN src
  layout (`src/miragev10/`) — the sidecar file stays byte-verbatim (never mutated).
- **Runtime-swap rehearsal procedure (recorded; executes once a second staged runtime
  exists):** stage the new bundle to a temp root → `mv` old→`.previous`, `mv` new→live
  (atomic on the same volume) → re-run the spawn smoke → default census → either
  confirm the swap or `mv` back. The app never mutates bundle contents except the
  whole-directory replacement (ADR-3 Decision 6).
- **App-embed status (honest):** the bundle is staging-root-proven tonight; embedding
  into a built `.app` (Resources/mirage-runtime + codesign of the piece + the locator's
  bundled channel consuming `Bundle.main`) is exercised by the CI run or an operator
  stage-into-app step — pending the owner's Actions toggle (ADR-3's machine-side-only
  prerequisite). The locator ladder + manifest verification are census-pinned already.

## Open items for the §15 ladder

1. R1 remaining rollbacks (PR-7/PR-5/PR-4 target-states) — scheduled per PR close.
2. Real-engine kill-staging R2 variants under the single-lifecycle harness — scheduled.
3. S15-ES-4 operational handoff bundle — PR-8 adds the runtime rows (staged/verified/
   manifest paths); final assembly once CI publishes its first receipt.
4. Content-level restore on a SEEDED ledger via the engine CLI once a backup surface exists
   (or a one-off engine-side operator run) — scheduled with the gap's owner decision.
5. R6's live runtime-swap execution — when a second staged runtime exists (procedure above).

