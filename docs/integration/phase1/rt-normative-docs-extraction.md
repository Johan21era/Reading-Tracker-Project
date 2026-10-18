# Evidence artifact — RT normative-document extraction (Phase 1/2)

Source: full-read analysis of 12 documents, on-disk dirty tree at SHA `8fbd5357677a0bde6729454e565e12ba4c0ba9fc` (branch merge/integration).
Documents read completely: README.md (213 ln) · docs/registers/02-defect-register.md (217) · 03-fix-log.md (245) · 04-handoff.md (78) · docs/audits/08-deep-audit.md (309) · docs/roadmap/05-remediation-roadmap.md (210) · 06-rsvp-feature-plan.md (188) · docs/method/07-testing-strategy.md (92) · docs/01-project-tree.md (75) · docs/history/09-final-traces.md (120) · 10-profiler-fix.md (427) · LAST_DEFEAT_demo_profiles.txt (513).
Notation: ROOT = `/Users/johanrembeci/Desktop/Reading Tracker Main ` (trailing space confirmed in audit Appendix C).

## Binding claims (path:line-anchored)

### Persistence & write path
- RT sandbox runtime root: `~/Library/Containers/johan.Reading-Tracker/Data/Library/Application Support/ReadTracker/` — `library.json` (monolith), `library-state.json`, `covers/`, `Backups/` (10-deep hash-gated), `sentinel-journal.jsonl`, plus `.migrated` legacy files and an abandoned `library.sqlite3` from the P5-G revert. (README.md:50,77-85; live-verified)
- Write discipline claim (README): "Writes go through `PersistenceWriter` on a serial utility queue behind a debounce." (README.md:90) — **weakened by NEW-DE-1** (below).
- Write-ordering slice context: "PersistenceWriter.swift: owned serial queue for ALL library disk writes… This is the P6-G prescribed design — future DB adoption lands here." (09-final-traces.md:74-76)
- P6-HOTFIX v2 contract: "Library ENCODE moved off-main — enqueueWrite takes an encode thunk executed inside the detached task." (03-fix-log.md:219)
- SQLite standing constraint (P5-G post-mortem): "any DB work needs FULLMUTEX + owned serial queue + stress suite BEFORE rewiring." (09-final-traces.md:26-28)
- Failure surfacing: silent-catch sites degrade `persistenceHealth` and render the bottom banner — new paths must route through this, not `print()`. (03-fix-log.md:46)

### NEW-DE defect register (lives ONLY in the audit's §7 — NOT in 02-defect-register.md; grep-verified absence)
All OPEN. Anchors (08-deep-audit.md):
- NEW-DE-1 🟠高危durability: PersistenceWriter gates but does not serialize encode→write; stale-overwrite window; saveImmediately drains only gated jobs (:135-137).
- NEW-DE-2 🟠 live UI: `Spatial/BookCoverCardView.swift:46` reads legacy `book.coverImageData`; fix = one-line `book.coverImage` (:139-141).
- NEW-DE-3 🟠: <24h crash+relaunch converts idle→reading; >24h Sentinel orphan repair records full wall-clock (`SentinelEngine.swift:293-297` unbounded) (:143-145).
- NEW-DE-4 🟡: AnalyticsCache signature lacks day; streak/trend stale across midnight (`AnalyticsCache.swift:32-48`) (:147-149).
- NEW-DE-5 🟡 data-destroying: onboarding import bypasses facade/duplicate check (`OnboardingView.importBook` :207-211); `commitGoal` :220-226 overwrites entire ReadingGoalSet (:151-153).
- NEW-DE-6 🟡 uncancellable RSVP extraction keeps security scope (:155-157); NEW-DE-7 🟡 NYC weather on location-denied (WeatherKitService2:686-699) (:159-161); NEW-DE-8 🟡 row-level coverage=1.0 (WeatherAnalysisEngine:1412) (:163-165); NEW-DE-9 🟢 BCE fabricates evidence if activated (:167-168); NEW-DE-10 🟢 double-snapshot/record paths (:170-171); NEW-DE-11 🟢 discovery stack gaps (:173-174); NEW-DE-12 🟢 test hygiene set (:176-177); NEW-DE-13 🟢 truth-drift set incl. ~12 print() in prod paths (:179-180).
- Release blockers ×4: empty AppIcon; missing WeatherKit entitlement (runtime 403); `ENABLE_USER_SELECTED_FILES=readonly` vs read-write entitlements file; empty-string `CFBundleIdentifier` in custom plist (:19,126,205).

### Integration-relevant standing rules (RT house standards)
1. Fix-finality triad: Finality statement + fix-log entry + pinned regression test citing defect ID (03-fix-log.md:5-9; README.md:193-199).
2. "Finality not reached ⇒ reverted to the proven engine" — honest reverts are successes (03-fix-log.md:167).
3. Green at every phase boundary; baseline build+test before touching code; commit at every boundary (README.md:189,203-205; 02-defect-register.md:173).
4. Every background path needs explicit `nonisolated` under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (README.md:68-71; 04-handoff.md:66; freeze root cause 03-fix-log.md:213-222).
5. Sentinel S1–S7 for any new writer (03-fix-log.md:189-197).
6. Preserve-list (do not "improve" during other work): persistence hardening cluster+pins, doc-truth norm, defect-class-pinned suites, DataMaturityEngine, entitlement grant LT-3a (05-remediation-roadmap.md:71-73).
7. Feature-module isolation proven by RSVP plan: "one fully self-contained module — zero dependency on [other features]… wiring into the main app is deliberately one of the last steps" (06-rsvp-feature-plan.md:56-60,76-87,109).
8. Do not mix feature commits with remediation commits (05-remediation-roadmap.md:201).
9. Tests: Swift Testing style, named for guarded defect; injected fake clocks for timing windows; no tests side-effecting real user dirs (07-testing-strategy.md:55-82,92; NEW-DE-12).
10. Save-storm pin = canonical write acceptance test: 20 rapid mutations → exactly one observable write cycle (05-remediation-roadmap.md:129-135).

### Architectural tracks (planned-not-executed; do NOT combine with integration)
- Order: dead-code sweep (LibraryView.swift deleted first) → store split (#3) → SQLite core (#1: blueprint at 09-final-traces.md:98-112 — FULLMUTEX + PersistenceWriter-owned queue + dual-read migration, RemediationPins as acceptance) → Swift 6 → BCE decision. (04-handoff.md:44-54; 09-final-traces.md:83-116)
- NEW-DE pursue order: 2 → 5 → 4 → 3 → 1 (04-handoff.md:49; 08-deep-audit.md:275).

### Cross-document conflicts (PR-1 must resolve)
(a) register open-section stale vs fix-log/audit (02-defect-register.md:28 vs 03-fix-log.md:93-104 vs 08-deep-audit.md:67); (b) 28 vs 108 test-count drift (02-defect-register.md:171-173); (c) handoff's "working tree clean" vs current dirty state (04-handoff.md:60); (d) NEW-DE IDs absent from register despite handoff directive 04-handoff.md:62; (e) README baseline command target-name drift (`ReadingTrackerTests` vs actual `Reading TrackerTests`) — discovered live in C-05.

## Live-verified (TEST-VERIFIED, this session)
- `xcodebuild build` Debug → BUILD SUCCEEDED (evidence/phase1/rt-baseline.log).
- Container snapshot BEFORE tests: library.json sha256 `2f7c1d97305cd4b50280f67893f3188788cf5f346e3b7e5fd425ac62a5ff9456`; library-state.json `f0274c8fd85b57acb9fc0cc3fbe6920ab6390e7ef29604cfd146a4e82ff5b9ab`; covers file count 39. Post-test re-hash to follow in merge log M-007 C-05b row.
