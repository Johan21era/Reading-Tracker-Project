# 07 · Testing Strategy

## What this document is

This describes **what to build so the same classes of bug get caught automatically next time**, rather than by another full manual audit pass. Where other documents describe what is wrong, this describes how to prevent it from happening again.

**Who should read this:** Anyone who wants to write tests for the project, or understand how the project guards itself against regressions.

**Status:** Current as of the AsterismaV1.0 release (2026-10-24), after the Bedrock and rebrand programs. The audit-era "step zero" (the test target running one placeholder) was resolved long ago: the suite is now real, wide, and enforced at every work boundary.

---

## The test landscape today

| | |
|---|---|
| **Framework** | Swift Testing — `@Suite` / `@Test` / `#expect` (the project standardized after converting the original XCTest suites) |
| **Scale** | 44 test files · 219 `@Test` functions |
| **Standing census** | **212 passed / 0 failed / 9 skipped** — the default, ungated census of every ordinary run |
| **The 9 skips** | 4 Mirage real-engine cases (identity import, handshake/health, and the two lifecycle steps), 1 benchmark, 2 real-library SQLite parity cases, and 2 live Open-Meteo cases |
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
