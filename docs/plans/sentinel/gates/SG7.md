# Gate SG7 — Hardening and Release sweep

**Date:** 2026-10-28
**Branch:** `main`
**Base commit:** `6099e4e`
**Tree state:** committed in `16d6d16`; GitHub `census` green at `bed710a`

**Decision:** HOLD — executable gates are green, but two required criteria are not met. Owner decision required; do not call this gate passed.

---

## Delivered

| SG7 deliverable | State | Evidence |
|---|---|---|
| First-tranche test depth | Met by executed cases | 151 Sentinel test functions; 414 parameterized probe-contract cases alone |
| Deterministic harness | Done | injected clock/root/defaults/capacity; no wall-clock assertions |
| Probe contract tests | Done | clean, deterministic, privacy per descriptor |
| Repair contract tests | Done | executor matrix + runtime repair path |
| Chaos/fault injection | Partial | throwing probe, timeout, snapshot failure, failed verification/rollback, torn journal line, corrupt state, unreadable payload |
| Test isolation | Verified | `verify-test-isolation.sh`: byte-identical real App Support tree |
| Release compile | Verified | `xcodebuild build -configuration Release` exit 0 |
| No Debug-only Release path in the Health Center | Verified | Window/commands outside `#if DEBUG` |
| Redacted diagnostics bundle | Done | `SentinelDiagnostics` + export test |
| v1 journal migration | Done | persistence tests |
| Privacy pins | Done | journal, notice, diagnostics, probe safe output |

---

## Verification

| Check | Command | Result |
|---|---|---|
| Full unit census | `./scripts/census.sh --unit-only` | **379 test functions; 1,024 passed cases; 9 skipped; 0 failed** |
| Test isolation | `./scripts/verify-test-isolation.sh` | **OK — real app-support data byte-identical** |
| Release build | `xcodebuild build -configuration Release` | **exit 0** |
| Fast pass | `fastPassBudget` on 70 books | **1.31 ms** (< 50 ms) |
| Census artifact | — | `census-2026-10-28.md` (temporary `.xcresult` not retained) |

The 9 skipped tests are pre-existing environment-gated tests (system integrations), not Sentinel coverage skips; the census reports 0 failures.

---

## Gate criteria that are NOT met

1. **"v1 removed."** `SentinelEngine` and its old bridge remain, used only by the Debug Developer Console and SG0/Pins tests. The active app path uses `SentinelRuntime`, but the old engine has not been deleted.
2. **Localization.** All copy is English-only; no String Catalog extraction or translations.

Two further deltas are recorded rather than claimed:

- **Menu bar surface absent.** Implemented, then removed because `MenuBarExtra` hung the test host on the main thread. The config key is reserved; no dead toggle is shown.
- **Manual owner acceptance not performed.** Ten owner scenarios require a human, a real library, and destructive fixtures; the suite substitutes deterministic fixtures. This is an explicit gate requirement in the roadwork and is not satisfied by automated tests.

---

## What is genuinely proven

- 1,024 unit cases pass, including 414 per-probe contract cases across all 138 probes.
- Release compiles without the earlier Debug-only `DataStore` dependency.
- Tests do not touch the real app-support tree.
- A failed verification restores the original book state; undo restores byte-equal state.
- Safe output (journal, notification body, diagnostics) carries no titles, paths, or note text.
- The 50 ms fast-pass budget is met with ~35× headroom.

---

## Rollback

Revert the Sentinel v2 source, app wiring, tests, and gate receipts. The v1 engine remains as the fallback, so this rollback is structural rather than a data migration. Diagnose any store issue by quarantining `Sentinel/state.json` and replaying the journal; no library file is rewritten.

---

## Next phase (owner)

1. Run the ten manual owner scenarios against a copied library.
2. Decide whether to delete the v1 engine now or keep it for one more release.
3. Approve or reject the menu bar surface (needs a different implementation than SwiftUI `MenuBarExtra`).
4. Schedule localization.
