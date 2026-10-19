# §18 Final acceptance checklist — receipts (2026-10-18, ladder complete)

Branch `merge/integration`, HEAD `0aa4ed8` (PR-8). Census (default, standing):
**191 passed / 0 failed / 4 skipped** (skips = the three opt-in suites' gates — real-engine
identity, real-engine smoke, boot diagnostic). Owner review round pending at session close.
Evidence = one pointer per item; the merge log (docs/integration/merge-log.md, M-014…M-028)
is the campaign of record.

## Product and architecture

- [x] RT parent; Mirage optional — ADR-6 (feature lifecycle; `mirage.enabled` switch); PR-7.
- [x] RT works without Mirage — decoupling census gates (M-023/M-024; onboarding-facade zero-refs gate held); ADR-6a (import-independence); disabled state starts nothing.
- [x] Mirage-owned ledger/analysis/spoiler rules — corrections-never-truth (PR-5 mount); spoiler contract ADR-7 (detail surfaces disabled until verified calibration).
- [x] Typed, versioned, SwiftUI-independent boundary — `MirageWireTypes`/`MirageClient`/conformance suite (PR-3; 28-action register); views consume typed outcomes only.
- [x] Transport + packaging ADRs approved — ADR-2 (transport, countersigned) + ADR-3 (packaging, direction countersigned tonight; implementation acceptance requested).
- [x] No undocumented second shell/hidden network service — the single sidecar spawn path; no network entitlements (grep-gated); the only new process machinery is the documented supervisor.

## Data safety and correctness

- [x] Separately-owned persistence — ADR-4 stratum; RT store zero refs from Mirage runtime (census gates).
- [x] Explicit identity mapping — ADR-5 identity map from validated receipts only.
- [x] Ambiguity does not silently map — ADR-5 duplicate rule; drift tests.
- [x] Cursor mapping source-verified + edition-aware — ADR-7 + Annex A: NO unverified cursor is EVER produced (no-conversion doctrine; detail surfaces disabled).
- [x] Missing/stale/mismatched cursor evidence fails closed — `MirageCursorGate` typed refusals (CURSOR-MISSING / SPOILER-CURSOR-UNVERIFIED / SPOILER-PROBE-REJECTED); spoiler-probe refusals test-pinned + transport tripwire.
- [x] Page turns never trigger analysis — S10-ES-4 pin suite + census gate (Reader carries no Mirage machinery outside the sheet mount).
- [x] Series candidates require user decision — engine-side candidates only (service.py:664-696 proposals); RT links nothing automatically (ADR-5; no series wire mutations from RT).
- [x] Corrections never silently become book truth — analyzed stories supersede without overwriting; provenance labels everywhere (PR-6 receipts).
- [x] No blind retry after ambiguous timeout — S9-ES-5 registry: typed faults, no auto-retry across the boundary; supervisor restart ladder is spawn-side only.
- [x] Backup/recovery independent per system — R5 receipts: Mirage `Ledger.backup()` online API verified from source (engine's own round-trip test re-pinned live); RT Sentinel/rotation untouched; the wiring gap (no wire/CLI backup surface) documented with named owner.

## Stability, testing, performance

- [x] RT baseline/census green — 191/0/4 standing receipt (this session, every PR closes on a green census).
- [x] Mirage Python tests pass — engine suite re-pinned live (backup round-trip `OK` 0.021 s; module imports verified through every real-engine proof).
- [x] Mirage RUST tests — N/A by selected build policy: the integration contract is the Python sidecar; the `crates/` native-core track is parked (ADR-3 Direction-3 note).
- [x] Contract + real-sidecar smoke — conformance suite + two real-engine proofs green tonight (single-lifecycle identity proof ~2 s, incl. PR-6's detail-free status phase).
- [x] Failure/timeout/malformed/cancellation/shutdown tests — MirageSidecarLifecycleTests band (EOF, timeouts, reaping, SIGTERM/SIGKILL escalation, malformed lines, foreign guard).
- [x] UI flows + accessibility — sheet states copy-tested; Settings uses native Form/Toggle constructs; unavailable states honest (PR-7).
- [x] Large/real-library robustness — canonical procedure referenced; large-library fixtures beyond tonight's receipts are a §20-next-items entry (delta).
- [x] MainActor bounded / UI responsive — no long work on main actor: transport work is background threads + async IO (PR-4), sheet states are value updates.
- [x] Performance baselines — spawn cost measured (banner ≈ 1 s cold; per-exchange ≈ ms); no Mirage-introduced regression receipts. A dedicated perf-budget report is §20-next (delta, not acceptance-blocking: no new hot paths added — status refresh = one read-only books_list per explicit gesture).
- [x] No unexplained regression or skipped required test — census receipts per PR; skipped = opt-in gates only, by design.

## Security, privacy, release

- [x] Runtime executable controlled + version-checked — PR-8: pinned pybs fetch (sha256 refusal pin), verified manifest, staging script drift-readable.
- [x] File access authorized/constrained — engine reads only the user's EPUB (user-granted resolveURL); writes confined to its stratum dir.
- [x] Logs bounded/redacted — bounded stderr tails in fault reports (PR-4 pins); no content logging on the wire path.
- [x] No network/telemetry — engine stdlib-local only; no network entitlements (grep-gated).
- [x] Clean-machine packaging — `scripts/verify-clean-machine.sh` (3-stage refusal gate) + live staging receipts tonight (app-embed step = CI/operator, owner-toggle pending — the documented delta).
- [x] Signing/sandbox/entitlements — existing app signature; bundle entities signer-confined per ADR-3 Decision 4; iCloud-stamp pathology avoided by the BUG-003 DerivedData discipline tonight (rehearsal R1 ran OUTSIDE the stamped tree, green).
- [x] CI gates visible — `census.yml` (RT census receipt); Mirage/integration gates named in the workflow plan — full three-ring CI lands with the TiB era (TB-M0+).
- [x] RT release blockers — none introduced by this integration; existing §21 known issues ride their own registers (NEW-DE-12 stub-cover regeneration stands).
- [x] Rollback/restore rehearsed — R1 (live PR-6→PR-5 worktree census green) + R5 backup-restore + R6 staging/swap procedure; remaining individual rollbacks scheduled per protocol.
- [x] Owner approvals — pending tonight's review round (owner ratifies the exact commits: `0842b2b` → `9a78947` → `0aa4ed8`).

## Repository governance

- [x] Strategy documented — §20 item 12's decision record + ADR-3; original repos recoverable (Mirage checkout untouched at pinned SHA; RT history intact).
- [x] No implicit archive/deletion — all deletions were owner-countersigned Class Δ (OPE-001, with archived list).
- [x] Migration refs/history — no repo-migration executed (none required by the ladder; consolidation decision record stands as §20 item 12's pending owner item).
- [x] Canonical location — communicated at session close (push authorization round).

## Honest deltas (not acceptance-blocking, ledgered)

1. App-embed of the staged runtime (Resources + codesign) exercised via CI/operator — owner toggle pending.
2. R1's remaining three individual rollbacks — protocol recorded, execution scheduled per PR close.
3. Backup surface on the wire/CLI — gap with named owner (J.), engine-side duty meanwhile.
4. Dedicated Mirage perf-budget report — §20-next; no regression receipts known.
5. Large-library soak beyond fixtures — §20-next.
