# 07 · Testing Strategy

## What this document is

This describes **what to build so the same classes of bug get caught automatically next time**, rather than by another full manual audit pass. Where other documents describe what is wrong, this describes how to prevent it from happening again.

**Who should read this:** Anyone who wants to write tests for the project, or understand how the project guards itself against regressions.

**Status:** Current as of the Sentinel v2 first tranche (2026-10-28), after the Bedrock, rebrand, and repository-reorganization programs. The audit-era "step zero" (the test target running one placeholder) was resolved long ago: the suite is now real, wide, and enforced at every work boundary.

> **Precedence:** the automated census is a strong early-warning system, not the final judge. The owner's personal test results are the absolute source of truth and override every benchmark, census, gate receipt, and documentation claim. See `docs/12-owner-test-authority.md`.

---

## The test landscape today

| | |
|---|---|
| **Framework** | Swift Testing — `@Suite` / `@Test` / `#expect` (the project standardized after converting the original XCTest suites) |
| **Scale** | 57 Swift files in the unit target · 379 test functions in 79 suites · 1,024 passing cases · responsibility-based groups plus Sentinel domain/runtime/catalog/persistence suites |
| **Standing census** | Local census on macOS 26.6.1 / Xcode 26.6 (2026-10-28): **379 test functions, 1,024 passed cases, 9 skipped, 0 failed**; Release build exit 0. Artifact `rt-census-20261028-152733.xcresult`. The remote GitHub census will roll to these numbers on the next push. |
| **CI scope** | The deterministic unit target is the merge-presence receipt. UI tests are placeholder launch stubs and depend on interactive automation, so they are not part of CI. The bundled-runtime assertion self-gates on `.mirage-runtime` being staged. |
| **The 9 local skips** | 4 Mirage real-engine cases (identity import, handshake/health, and the two lifecycle steps), 1 benchmark, 2 real-library SQLite parity cases, and 2 live Open-Meteo cases. None are Sentinel coverage skips. CI may add a bundled-runtime presence skip on a clean checkout without the staged 47 MB runtime. |
| **Census discipline** | Every fixing session opens and closes on a green census; canonical numbers come from `xcrun xcresulttool get test-results summary --path <.xcresult>` — never from eyeballing the console |

---

## House conventions (pinned by practice)

1. **Harness-shared helpers live at the tests root** — e.g. `MirageStubSidecarSupport.swift` (temp-dir factory, scripted-transport double). A transport double that runs `#expect` inside the double is an accepted, precedented pattern.
2. **Suites serialize with `.serialized`** — tests that touch process machinery or shared singletons run one-at-a-time inside their suite.
3. **Runtime `Skip` is not supported by the runtime — use `.enabled(if:)`** for conditional suites. That is why the nine "skipped" census cases appear as skips: the gating is compile-time metadata, not a throw.
4. **Test-runner `print()` output lands in the xcresult, not in the xcodebuild console.** To capture diagnostics, read them from the `.xcresult` bundle or write to a file.
5. **Never pass `-derivedDataPath` on a Desktop/iCloud-synced checkout.** The iCloud File Provider stamp (`com.apple.fileprovider.fpfs#P`) on the derived-data tree breaks code signing outright (BUG-003). `.rt-dd` debris was deleted; default DerivedData is the standing rule — including in worktrees built outside the synced tree.
6. **Green census at every PR boundary** — one green default census per commit unit; at least one named suite per defect class.

---

## The Mirage integration band (added by the merge campaign)

The Mirage surface is tested as bands, mirroring the boundary's enforcement rules (`docs/integration/` is the campaign of record; the playbook's census receipts tie to these):

| Band | Suites | What they pin |
|---|---|---|
| **Wire conformance** | `MirageWire*Tests`-family | Every NDJSON shape — request lines, envelopes, malformed-line refusals, protocol version gates |
| **Process lifecycle** | `MirageSidecarLifecycleTests` | Spawn → banner → exchange → teardown; EOF/timeout/reap; SIGTERM→SIGKILL escalation; foreign-guard pid files |
| **Identity & drift** | `MirageIdentity*Tests` | Entry birth only from validated receipts; superseded-orphan transitions; crash-atomic writes; fail-closed on unknown schema |
| **Spoiler contract** | `MirageSpoilerProbeTests`, `MirageCursorContractTests` | Fail-closed refusal codes (`CURSOR-MISSING`, `SPOILER-CURSOR-UNVERIFIED`, `SPOILER-PROBE-REJECTED`); no unverified cursor is ever produced |
| **Feature lifecycle** | `MirageFeatureLifecycleTests` | One switch, disable-spawns-nothing, **disable-deletes-nothing (byte-identical)** |
| **Page-turn isolation** | `MiragePageTurnNonTriggerTests` | Reader navigation carries no Mirage machinery; analysis is gesture-only |
| **Bundled runtime** | `MirageBundledRuntimeTests` | Manifest strict decode, SHA-256 tamper refusals, the locator ladder (bundled → dev gate → nothing) |
| **Opt-in real-engine** | `MirageIdentityRealEngineImportTests`, `MirageRealEngineProxy…`, `MirageZBootDiagnosticTests` | The actual Python engine, spawned live for ONE lifecycle: real identity receipt, detail-free status, version/inventory exchange |

### Engaging the opt-in suites

```bash
# Real engine, one lifecycle, the proven dev channel:
TEST_RUNNER_MIRAGE_REAL_ENGINE_DIR=/path/to/MirageV1.0 \
xcodebuild test … -only-testing:"AsterismaV1.0Tests/MirageIdentityRealEngineImportTests"

# The standing M-027 boundary probe (only when deliberately hunting the machinery boundary):
TEST_RUNNER_MIRAGE_REAL_ENGINE_DIR=/path/to/MirageV1.0 \
TEST_RUNNER_MIRAGE_BOOT_DIAGNOSTIC=1 \
xcodebuild test … -only-testing:"AsterismaV1.0Tests/MirageZBootDiagnosticTests"
```

`-only-testing` matches Swift Testing type identifiers. The boot diagnostic uses the **disposable-data** path plus `MIRAGE_BOOT_DIAGNOSTIC=1`; the single-lifecycle doctrine holds even under it.

### Standing Mirage doctrine (same rules the code enforces)

- Entries are born **only** from validated `import_epub` receipts — a test may not invent a mapping.
- The engine's spawn contract is `<interpreter> <engine>/examples/mirage_sidecar.py <ledger>` on a disposable ledger; the real ledger is never touched by tests.
- The packaged runtime bundle must verify byte-verbatim: no test mutates the staged bundle except the whole-directory swap rehearsal.

---

## The Sentinel v2 band (2026-10-28)

Sentinel is tested in four layers, plus the product surface:

| Band | Suites | What they pin |
|---|---|---|
| **Domain laws** | `SentinelDomainTests` | Fingerprint stability, ordering, lifecycle edges, evidence, copy, diagnosis, trend |
| **Persistence** | `SentinelPersistenceTests` | Journal segments/checksums/rotation, v1 import, torn state fallback, issue rebuild, config migration |
| **Runtime** | `SentinelRuntimeTests` | One cycle lock, generation snapshots, timeout/failure isolation, coverage honesty, repair guards |
| **Catalog contract** | `SentinelCatalogTests` | Per descriptor: clean-install silence, determinism, privacy; damaged-fixture evidence; SQL fixtures; 50 ms fast-pass budget |
| **Repairs** | `SentinelLaunchAndRepairTests` | Launch-card states, executor refusal matrix, plan builders, rollback/undo, notification cap, diagnostics redaction |
| **Legacy pins** | `SentinelSG0Tests`, `SentinelPinsTests` | v1 security doctrine S1–S7 and write confinement |

The 414 parameterized probe-contract cases come from running three tests over all
138 descriptors. The catalog is designed so adding a probe automatically adds its
three contract cases. A new probe with no clean/determinism/privacy coverage is a
gate failure by construction.

Known test gaps are recorded in [SG7](../plans/sentinel/gates/SG7.md): no automated
accessibility pass, no 10× SQLite benchmark, and no per-repair fault injection for
all 25 plans.

---

## What to cover, mapped to what's risky

The original audit-era table earned its keep: the risky classes it listed (persistence failure paths, multi-index deletes, toast FIFO, calendar math, observer lifecycle, SQLite transactions, celebration timers) are now all **covered and pinned by named suites** — that is what the census is made of. The current frontier of coverage:

1. **Mirage-era deltas (ledgered, not blocking):** a dedicated Mirage performance-budget report (spawn latency is measured; per-exchange paths have no standing regression budget); large-library soak beyond fixtures.
2. **RSVP edge conditions:** the feature ships (P5-B2); its tokenizer and pacing engine have production paths but only partial direct pins — worth a tokenizer-matrix suite before any format overhaul.
3. **Weather honesty (NEW-DE-7/8):** the missing coverage is the honesty behavior itself — coverage ratio and locale fallback are product decisions still pending, so their tests wait on the decision.
4. **BCE Phase-2:** dormant by product decision; its activation must arrive with its own band (see the register) or the scaffold must go.

---

## Example: the shape of a pin in this repo

```swift
// From the merge campaign — the disable-deletes-nothing pin:
@Suite("Mirage Feature Lifecycle", .serialized)
struct MirageFeatureLifecycleTests {
    @Test func disablingMirageDeletesNothing() throws {
        // Seed the stratum, toggle mirage.enabled OFF,
        // assert every stored byte is identical across the toggle.
    }
}
```

When you add a pin, name it after the defect or the contract it guards so the suite reads like the defect history — the standing examples are `TextExtractionTests` ↔ F-03, `NonGregorianCalendarTests` ↔ F-01, `CelebrationTimelineTests` ↔ F-02, `SentinelPinsTests` ↔ S1/S5, and the Mirage band ↔ the merge playbook's census receipts.
