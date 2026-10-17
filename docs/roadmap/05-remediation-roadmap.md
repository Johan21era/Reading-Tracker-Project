# 05 · Remediation Roadmap

**Source audit:** RA-002 · full-tree audit executed under the project's fix protocol
and `07-testing-strategy.md`.
**Suite state at authoring:** `xcodebuild test` exit 0, every case passing (fresh run, not inherited).
**Companion documents:** `02-defect-register.md` (defect register), `03-fix-log.md` (protocol log),
`07-testing-strategy.md` (coverage mapping), `04-handoff.md`.

**Governing rule:** every phase opens with the protocol step-zero (clean build + full suite green,
verified — not assumed) and closes with the same, plus `03-fix-log.md` entries per Guardrail 2.
No edit without its own Finality statement. One defect, one Finality, one log entry — including
downstream consequences discovered mid-fix (Bug Chain Discovery).

---

## How to read this roadmap

Phases **descend in weight on purpose** (per Johan's directive): the heaviest structural work happens
first, while attention and context are freshest; each subsequent phase is smaller, safer, and suited
to shorter sessions. Item IDs come from the audit: **NA-x** = new findings from RA-002,
**F-x** = legacy register findings, **LT-x** = live-test items, **O-x / D-x** = open/debt register.

Nothing in this roadmap includes feature-track work (RSVP speed reading, BCE V3 UI activation,
LT-10–LT-12 polish, achievements gallery). See **Parallel Tracks** at the bottom.

---

## Compiled evidence base (what the audit established)

### A. Verified-stable — trust without re-investigating

Every claim in the existing register checked out against live code, and the suite passes fresh:

| Cluster | Verdict |
|---|---|
| F-01 calendar guard, F-02 celebration redesign, F-03 entity decode, F-04 Gates A+B, F-05 continuation queue, F-06 chronological fatigue analysis, F-07 monitoring idempotence | All REAL in code, all pinned by running tests |
| Stage 1–4 compile/behavioral fixes, O-7 dispatch-once, §2.1 delete-by-ID, §2.2 toast FIFO, §2.3 ghost-hover guard, §3.3 unrepairable gate, D1 persistence banner, §4.1 observer tokens, §4.2 SQLite transaction, §4.4 deinit | All REAL |
| LT-1 discovery redesign, LT-2 sheet dismiss affordance, LT-3a entitlements, LT-3b phantom-time fixes (both readers), LT-4 Insights window, LT-5/6/7 report+hover polish, LT-8 demo profiles v1+v2 | All REAL |
| P2.1 environment refcount, P2.2 engine wiring, P2.3 Explorer + collection CRUD with referential integrity, P2.4 Import Intelligence surfacing, P2.5 fatigue fix | All REAL |

### B. Open defects this roadmap resolves

| ID | Sev | One-line statement |
|---|---|---|
| NA-1 | 🟠 HIGH | Weather "Fix 1/2/3" block is dead code; the live engine still hardcodes confidence (0.8×3 + coverage 1.0), uses unsorted first/lastObserved, and labels rarest genres "avoided" |
| NA-2 | 🟠 HIGH | Goals/deadlines unreachable end-to-end: `updateGoalSet`/`addDeadline` have zero callers; dashboard points to nonexistent settings; goal achievements structurally unearnable |
| NA-3 | 🟡 MED | Report generation races: untracked detached tasks, last-finished-wins overwrites newer selection |
| NA-4 | 🟠 MED | Audio monitoring ships without its declared-required apple-events entitlement and `NSAppleEventsUsageDescription`; Info.plist is an empty stub |
| NA-5 | 🟠 MED | No `PrivacyInfo.xcprivacy` anywhere |
| NA-7 | 🟢 LOW | Doc-truth set: phantom `AnalyticsCache`; nonexistent `Session Concept 1.md` ×2; "never reads Date()" contradicted by expiry rule |
| NA-8 | 🟢 LOW | Demo persona `??` on non-optionals (`DemoDataService.swift:206,308`) |
| NA-9 | 🟢 LOW | Discovery sheet lacks the dismiss affordance claimed universal |
| F-08 | 🟢 LOW | `weekGoalStreak` registered, never awarded |
| F-09 | 🟢 LOW | Importer shadows canonical text utilities (divergent entity handling at import time) |
| F-10 | 🟢 LOW | AudioProfileStore failures print-only |
| F-11 | 🟢 LOW | Validator S-3 dead `tmp` + misleading "swapped"; S-1 rule that can never fire |
| F-13 | 🟢 LOW | (a) dead estimation trio · (b) expiry rule reads wall clock despite injected-clock design · (c) sqlite3_open failure ignored · (d) inverted gap-record names |

Carried unchanged (correctly logged, scheduled below or deferred): **O-6** (weather session-key design),
**O-8 remainder**, **D6** (no archival/pruning), **D7** (hand-rolled SQLite — materially improved by §4.2).

### C. Dead code inventory (~310 LOC, ~0.9%)

`WeatherKitService2.swift:1032–1104` Fix-block (+ `coverageRatio(for:)`) ·
`AnnualReportArchiveView2.swift:186+` JanuaryFirstBannerView (~200 LOC, never instantiated) ·
`BehavioralCategory.swift` `Equatable.takeIf` + unassigned `systemPowerObserver` branch ·
`EstimationEngine` dead trio (`totalWeight`, instance `clamp`, `mapConfidence`) ·
demo fallback RHS ×2. Dispositions assigned in Phases 1/3/4.

### D. Scalability thresholds (from audit §5)

- ~10× volume: uncached whole-library analytics fan-out (hover-triggered) starts dropping frames;
  JSON monolith rewrite begins to stall main actor per save burst.
- ~100× volume: store rewrite size dominates; analytics scans dominate launch; weather store grows unpruned.
- Degradation stays graceful throughout (validator + backup + tolerant decoders hold).

### E. Preserve-list — do not "improve" these while fixing anything else

Persistence hardening cluster (backup/decoder/gate/transaction + their pins) · Documentation-truth
norm (status-correction comments with history) · Defect-class-pinned test suites · DataMaturityEngine
architecture · Minimal entitlement grant from LT-3a.

---

## Dependency map

```
Phase 1                          Phase 2                 Phase 3                Phase 4
─────────────────────────────    ───────────────────     ───────────────────    ──────────────
1.1 NA-1 weather (gate A)  ─┐
1.2 NA-2 goals a → b → c ───┼──►  2.1 D6 async saves ──►  3.1–3.3 readiness ──► 4.1–4.5 niche
    (1.2c F-08 needs 1.2b) ─┘     2.2 O-8 batch            + small fixes        hygiene only
                                  2.3 F-12 rebinds         (independent)        (independent)
```

Phase 2 does not depend on Phase 1's outcomes except where noted. Phase 3 items are independent
leaves. Phase 4 is pure hygiene with zero behavioral risk.

---

# PHASE 1 — Structural Corrections 【XL】

*Two heavyweight items. Expect multiple sessions. Everything else in the repo is lighter than this phase.*

### 1.1 · NA-1 — Resolve the weather-fix contradiction (wire or delete)

**Decision gate FIRST (small, decides the route):** read `WeatherInsightPanel2.swift` line-by-line
and determine whether report-level confidence fields (`WeatherTrendReport.confidence.overallConfidence`,
`EnvironmentalBehaviorReport.confidence`) are displayed anywhere. Correlation *rows* are already
evidence-gated by `DataMaturityWeatherAdapter`; only report-level confidence is at issue.

- **Route A (wire — recommended if report confidence is user-visible):** three independent Finalities:
  1. Replace `calculateAggregateConfidence` internals at `WeatherAnalysisEngine.swift:761–773`
     with real derivation (accept a `dataCoverageRatio` parameter; compute from correlation scores +
     `WeatherKitService.coverageRatio(for:)` over the session IDs actually analyzed).
  2. Sort sessions by timestamp before extracting `firstObserved`/`lastObserved` in
     `buildCorrelation` and `buildBinaryConditionCorrelation` (the authored `temporalBounds(of:)`
     already implements this — calling it is the fix).
  3. Replace `suffix(3)` rarest-genre selection at `WeatherAnalysisEngine.swift:908` with the ≤5%
     threshold logic from the dead `avoidedGenres(from:totalSessions:)`, then delete the dead block.
- **Route B (delete — acceptable if report confidence is nowhere displayed):** delete
  `WeatherKitService2.swift:1032–1104` entirely, reopen the three underlying defects in
  `02-defect-register.md` as OPEN with today's evidence, and note the partial mitigation (maturity gating)
  in each entry.

**Either way:** the surviving narrative must match reality — no file may continue claiming bugs are
fixed when they are not (this repo's own §6 defect class).
**Pin to add (Route A):** a test asserting `dataCoverageScore` reflects an injected coverage ratio
rather than constant 1.0.
**Unknown resolved by:** the decision-gate read above. Do not start Route A before it completes.

### 1.2 · NA-2 — Goals end-to-end (three sequential Finalities)

**1.2a · Settings shell (absorbs LT-9's container need).** New `Window` scene ("Settings",
`Cmd+,`) hosting a tabbed pane; the ONLY mandatory resident for this roadmap is the goal editor.
Keep the shell generic so LT-9's original symbol-color customization can land later without
restructuring. *Finality: a reachable, closable Settings window exists with one functional pane.*

**1.2b · Goal editor wired to tested APIs.** Editor pane binds `ReadingGoalSet` fields
(daily pages / daily time / annual books / weekly days) and per-book deadlines to the ALREADY-CORRECT
and ALREADY-PERSISTED `DataStore.updateGoalSet(_:)` / `addDeadline(_:)` / `removeDeadline(bookID:)`.
On save, also refresh `GoalProgressViewModel` state (it currently seeds once at root `.task`;
either re-bind on `libraryState` change or push the new set through `updateGoalSet(_:books:)`).
*Finality: a goal set in the editor persists across relaunch and changes `GoalsDashboard` cards on
next open.* **Pin to add:** round-trip test — set goals via store API → reload store → assert statuses reflect them.

**1.2c · F-08 — implement `weekGoalStreak` detection.** Derive "days meeting daily page target"
history from `AnalyticsEngine.dailyActivity` + the now-settable `goalSet.dailyPageTarget`;
award when 7 consecutive qualifying days exist; extend `detectGoalAchievements`. Depends on 1.2b
(an unset goal makes the streak meaningless-by-construction). *Finality: synthetic 7-day history
earns the badge exactly once; interleaved misses do not.* **Pin to add:** the earn-once + miss-breaks pair.

**Phase exit:** build + full suite green; both new pins green; fix-log entries for 1.1 route taken
and each of 1.2a/b/c.

---

# PHASE 2 — Persistence Scaling Batch 【L】

*One architectural change plus its registered companions. Narrower blast radius than Phase 1.*

### 2.1 · D6 — Move disk writes off the main actor

Design gate first: `DataStore` is `@MainActor`; the fix captures the books/libraryState VALUES,
encodes+writes inside a detached task, hops back only to set `persistenceHealth`. Debounce
semantics preserved (coalesce on main, execute off main). Reuse the existing degraded-surface path
for write failure — no new error channel.
*Finality: `scheduleSave()` performs zero disk I/O synchronously on the main actor; a failed write
still degrades the banner exactly as today.*
**Pin to add:** concurrent save-storm test (20 rapid mutations → exactly one observable write cycle,
health healthy at end).

### 2.2 · O-8 batch — guarded lookups + divergence checks

1. `urls(for:).first!` ×2 (`DataStore3.swift:73`, `WeatherKitService2.swift:430`): guard with a
   documented fallback directory (temp-dir + degraded banner mirrors D1 semantics).
2. Investigate-then-Finality: the registered `turnToPage` weak-store divergence claim — verify
   against current `SessionCoordinator.turnToPage` + readers before touching anything.
3. Duplicate-import silent no-op: decide the UX (surface "Already in library" info alert via the
   existing `importWarnings` channel) — smallest change that makes the no-op observable.

### 2.3 · F-12 — rebind subscription accumulation

One-line-each Finalities: `cancellables.removeAll()` at the top of `GoalProgressViewModel.bind(to:)`
and `SessionEventRouter.bind(to:)`.

**Phase exit:** suite green; save-storm pin green; O-8 items individually logged (fixed or
investigated-disproven, which is a valid protocol outcome).

---

# PHASE 3 — Submission Readiness & Small Correctness 【M】

*Independent leaves. If App Store submission ever becomes imminent, pull 3.1–3.2 forward —
they are small enough to do any day, which is why they are not forced earlier.*

### 3.1 · NA-5 — Privacy manifest
Create `PrivacyInfo.xcprivacy`. **Verify-then-declare, invent nothing:** enumerate accessed-API
categories against Apple's current required-reason list (UserDefaults use is confirmed:
`wks_lat/wks_lon/wks_manual_*`, `annualReport.bannerDismissedYear`). Judgment call requiring
verification: whether WeatherKit location transmission triggers a collected-data declaration —
resolve by reading Apple's current guidance before declaring. Log the reasoning in fix-log.

### 3.2 · NA-4 — Audio automation legality
Add `com.apple.security.automation.apple-events` to `Reading Tracker.entitlements` and
`NSAppleEventsUsageDescription` to Info.plist (replacing the empty stub with a real plist that
keeps `GENERATE_INFOPLIST_FILE = YES` compatibility — verify merge behavior with a build), **or**
excise the Music/Spotify AppleScript paths and document CoreAudio-presence-only detection.
Recommendation: grant the entitlement; the feature is real and the header already specifies
exactly what's missing.

### 3.3 · NA-3 — Report-generation race guard
Capture a monotonically increasing `generationIndex` before the detached task; on the main-actor
landing, apply results only if index matches current selection; cancel-and-replace otherwise.
~10 lines. *Finality: rapid year switching always renders the newest selection's data.*

### 3.4 · Small correctness cluster (each its own Finality)
- NA-7: three comment-truth corrections (delete phantom `AnalyticsCache` claim; replace
  `Session Concept 1.md` references with real pointers; fix the "never reads Date()" header OR
  fix the behavior — fold F-13(b) here by relocating the expiry check into `evaluate()` where
  `referenceDate` already flows, removing wall-clock from the rule chain).
- NA-8: delete the two dead `??` fallbacks (`DemoDataService.swift:206,308`).
- NA-9: add `.sheetDismissAffordance()` to the Discovery presentation (after confirming
  `BookDiscoveryView`'s internal close control, so we're layering redundancy, not duplicating UI).
- F-09: point `BookImporter`'s word-count/difficulty sampling at `SharedTextUtilities`; the canonical
  header then becomes true. Existing `TextExtractionTests` cover the shared implementation.
- F-10: route AudioProfileStore failures through the `PersistenceStatus` pattern (or make the
  documented-downgrade decision explicit in the file header).
- F-11: fix S-3 message + remove dead `tmp`; delete never-firing S-1 (ReliabilityTests pins stay green —
  verify before logging).
- F-13(c): check `sqlite3_open` return + schema-exec result; add `.openFailed` to `StoreError`.
- F-13(d): rename `precededSession/followedSession` on the dormant path (zero-caller verified).

**Phase exit:** suite green; register updated to reflect every disposition above.

---

# PHASE 4 — Niche & Hygiene 【S】

*Zero-risk sweep, suitable for a short session.*

1. **Dead code removals (product decision on one):** `Equatable.takeIf`; `systemPowerObserver`
   property + its unreachable removal branch (vestigial from a pre-Combine design);
   `EstimationEngine` dead trio remnants not consumed in 3.4; demo fallback residue if any survived.
   **Decision required:** `JanuaryFirstBannerView` — wire it (it implements a real spec'd feature)
   or delete it (~200 LOC). Default recommendation: delete; resurrect from git history if the
   January-banner feature is ever prioritized.
2. **O-6** — weather session-key design question: revisit ONLY once real multi-season snapshot data
   exists to inform it (deliberately deferred; do not solve speculatively).
3. **Profiling watch-item:** `SessionEventRouter.runPostSessionCascade` whole-library scan per
   `$books` emission — measure under Phase 2's async regime before optimizing; optimize only on
   evidence.
4. **Cruft:** delete `Reading Tracker/default.profraw`; confirm `.gitignore` coverage holds.
5. **Folder rename:** drop the trailing space in `Reading Tracker Main /` (pure filesystem op —
   do OUTSIDE any fix session; update nothing else, paths resolve relatively).

**Phase exit:** final register pass — `02-defect-register.md` superseded sections marked resolved with
pointers to fix-log stages; 04-handoff.md rewritten per Session Close-Out contract.

---

## Parallel tracks (explicitly out of scope here)

Feature work continues independently of this roadmap and should interleave AFTER Phase 1:
RSVP speed reading (see `06-rsvp-feature-plan.md`), BCE V3 activation with its UI
(gate: hardening pass items already closed by P2.5), achievements gallery (LT-10), star visual
polish (LT-11), broader de-blocking pass (LT-12), symbol-color settings (rides Phase 1's shell).
Do not mix feature commits with remediation commits — the fix-log's traceability depends on it.

## Definition of done (repo-wide)

1. Every NA/F item above is fixed-verified-and-logged or explicitly dispositioned in the register.
2. Suite green at every phase boundary (verified runs, never assumed).
3. `03-fix-log.md` carries a complete entry per Guardrail-2 pass; `02-defect-register.md` superseded;
   `04-handoff.md` answers the seven close-out questions.
4. No file in the repo asserts a wiring/fixed state that code contradicts — spot-checkable via the
   three known-good patterns (status-correction comments, truthful headers, pinned behaviors).
