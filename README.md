# Reading Tracker

**A macOS reading-analytics app — and one of the most honestly documented indie codebases you'll ever read.** Built over ~30 focused working sessions, Jun 17 – Aug 26 2026, then hard-audited and reorganized (Oct 2026). Swift/SwiftUI only. One dependency.

> **This README is the project report.** The full audit with file:line evidence for every claim lives in [`docs/audits/DEEP_AUDIT_OCTOBER_2026.md`](docs/audits/DEEP_AUDIT_OCTOBER_2026.md). Live registers: [`docs/registers/CURRENT_AUDIT.md`](docs/registers/CURRENT_AUDIT.md) (defects), [`docs/registers/fix-log.md`](docs/registers/fix-log.md) (protocol log), [`docs/registers/handoff.md`](docs/registers/handoff.md) (where we left off).

---

## 1 · What it is

**Plain English.** You import your PDFs and EPUBs, read them inside the app, and it quietly remembers everything: how fast you turned each page, what hour you read, what the weather was, what you were doing on your Mac beforehand. It draws a living night-sky background that follows real time and weather, tracks goals/streaks/25 achievement badges, renders a year-in-review slideshow, and has an optional speed-reading mode. A slow-learning "context brain" tries to reconstruct *where and why* you read. Hidden Developer Console (⌘⇧D) stress-tests the app with 16 fake reader personas; a "Sentinel" watchdog scans for data problems at launch, auto-repairs the provably-safe ones, snapshots everything before touching anything, and reports overnight.

**Technical.** Swift/SwiftUI macOS app, 3 targets, `MACOSX_DEPLOYMENT_TARGET = 26.5`, Swift 5 language mode with **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`** + approachable concurrency (the project's defining build setting — and the root cause of its hardest freeze bug). Persistence is hand-rolled and layered: a debounced pretty-printed JSON monolith (`library.json` — every book → session → page-turn timing), sidecar `library-state.json` (goals/achievements/collections), keyed-access SQLite for weather snapshots, a content-addressed cover file store (NSCache'd), 10-deep hash-gated backup rotation, `.readingarchive` v1 export/import, and an append-only JSONL Sentinel journal (500-line rotation). Analytics are pure static-namespace engines; `AnalyticsCache` memoizes five whole-library reductions behind a mutation-epoch counter; `PersistenceWriter` owns disk writes on a utility queue; `DataMaturityEngine` gates every intelligence claim behind evidence floors with an injected clock.

## 2 · The numbers (validated by direct count, Oct 17 2026)

| | |
|---|---|
| Swift files | **120** — 100 app · 18 unit tests · 2 UI-test stubs |
| Application LOC | **39,900 raw** (28,697 code / 5,869 comment / 5,334 blank) |
| Test suite | **2,763 LOC · 108 `@Test`** functions (~160+ executed with parameterization); 25 achievement kinds; 16 deterministic personas; 286 top-level types |
| Dependencies | exactly **1** — ZIPFoundation 0.9.20 (pinned) |
| History | 45 commits (Jun 17 – Aug 26 2026) + Oct 2026 audit/reorg commits |
| Toolchain | Xcode 27.1 · deployment target macOS 26.5 |
| Docs | ~30k words of registers, method docs, and session history under `docs/` |
| Repo | 43 MB on disk (30 MB is regenerable `graphify-out/` analysis artifacts — gitignored) |

## 3 · Current health (verified live, not inherited)

- ✅ **`xcodebuild build` → BUILD SUCCEEDED (exit 0)** — fresh Debug build of the exact current tree.
- ✅ **`xcodebuild test` (unit target) → TEST SUCCEEDED** — full suite green on a fresh run Oct 17, 2026.
- ✅ The once-critical Sep-2 one-line freeze fix (`.environmentObject(dataStore)` on the console window) is now **committed** (355d68e) instead of living only in an uncommitted working tree.
- ⚠️ See §5 for what's still open.

**Test-suitability score: 0.68 / 1.0** — exceptional defect-pin depth (0.9; nearly every test is named for a numbered historical defect), narrow architecture breadth (0.4; views/network/readers untested), good hygiene (0.65), sound infrastructure (0.7).

## 4 · Where we are project-wise

Every planned remediation arc and feature package has been executed, with the suite green at every phase boundary:

| Track | Status |
|---|---|
| Bug-hunt remediation (Stages 1–4, 10 compile + behavioral + observer/calendar fixes) | ✅ shipped, pinned |
| Four-phase remediation of the full RA-002 re-audit | ✅ shipped |
| Five production features (weather evidentiary · covers + reading HUD · RSVP speed-reading · onboarding + search/sort · archive durability) | ✅ shipped (SQLite engine attempted → honestly reverted; post-mortem preserved) |
| THE SENTINEL (deterministic watchdog + safe auto-repair + kill switch) | ✅ shipped with security doctrine S1–S7 pinned |
| Demo-profile freeze saga (3 failed rounds → probe-the-frozen-process → 1-line root cause) | ✅ closed; evidence pair kept in `docs/history/` |
| Performance marathon FINAL TRACES (covers→files · AnalyticsCache · PersistenceWriter slice) | ✅ shipped; store-split & SQLite blueprints written |
| UI Review execution (chrome recedes, one atmosphere) | ✅ shipped |

**Not yet done** (deliberate, blueprinted): the normalized SQLite core ( retiring the JSON monolith — the roadmap's one XL item), split `@Observable` stores, Swift 6 strict mode, BCE V3 UI activation (audit recommends delete-first), CloudKit (deferred by design), App Store submission.

## 5 · Open findings snapshot (October register)

13 new defect-class items + 4 release blockers were logged by the October audit and merged into [`docs/registers/CURRENT_AUDIT.md` Appendix D](docs/registers/CURRENT_AUDIT.md). The ones that matter most, in fix order:

1. **NEW-DE-2 🟠** Explore/spatial card views read the legacy embedded-cover field, so real covers never show there post-migration — one-line fix (`book.coverImage`).
2. **NEW-DE-5 🟡** Onboarding import bypasses the import-intelligence facade and duplicate check; its goal commit can overwrite an existing full goal set.
3. **NEW-DE-4 🟡** AnalyticsCache signature has no day component → streak/trend values can go stale across midnight.
4. **NEW-DE-3 🟠** A crash + relaunch under 24 h silently converts idle time into reading time (Sentinel only repairs >24 h, and even then books the full wall-clock duration).
5. **NEW-DE-1 🟠** `PersistenceWriter` gates but does not serialize the encode/write work — a narrow stale-overwrite window exists; restore the ordering contract and re-pin.
6. **Release blockers** — empty AppIcon set; missing WeatherKit entitlement (weather will 403 at runtime); `ENABLE_USER_SELECTED_FILES=readonly` build setting vs read-write entitlements file; empty-string `CFBundleIdentifier` key in the custom plist.

Also worth knowing: per-correlation weather confidence still hardcodes coverage = 1.0 (aggregate fixed, row-level not); location-denied weather silently describes New York; RSVP text extraction tasks aren't cancellable; ~5.5–6.5 k LOC (~12–15% of the app target) is dead/dormant scaffolding, headlined by the Behavior Context Engine's 81%-dead Phase-2 append and the never-instantiated `LibraryView.swift`.

**Closed mysteries:** the Behavior Context Engine's silence on 1,500 h of synthetic history was diagnosed from code — `analyze()` only fires when a *live session closes* (`.dropFirst()` suppresses launch/import), and synthetic personas generate zero NSWorkspace evidence; day-span floors bind before hour-volumes do. The profiles are proven innocent (16/16 validator-clean, pinned).

## 6 · Estimates (multi-basis)

| Scenario | Sessions | Hours |
|---|---|---|
| Quick fixes + release blockers + commit hygiene (minimal-ship shape) | 1–2 | **~6–10 h** |
| + dead-code retirement, discovery hardening, weather honesty, achievement-flood UX, pruning policy, BCE V1 activation | 4–6 | **~20–35 h** |
| + store split (#3) + normalized SQLite core (#1) + Swift 6 completion | +3.5–6 | **+23–40 h** |

**Scale reality check (monolith kept):** 100 books/300 sessions → fine. Persona-scale (~185k page-timings) → 1–3 s encodes (the codebase's own measurement). A multi-year real library (~1–10 M timing records) → a 250 MB–5 GB single JSON re-encoded per save burst with launch validation on main — which is exactly why the SQLite blueprint exists and is the recommended next architectural arc.
**Monolith-breaking risks are real even now:** the write-ordering window (NEW-DE-1) and 10× back copies of the full library are the two mechanisms by which a crash could cost real history; both are small, bounded fixes.

## 7 · Strengths & weaknesses (verified)

**Strengths.** Protocol-driven traceability — every historical fix is implemented, Finality-verified, logged, and pinned by a test named for its defect (the suite reads like a defect history). A layered data-loss defense stack (corrupt→`.bak`→banner→repair-blocks-save→rotation→archive→Sentinel). Honest session logs including documented failures. Correct handling of the brutal MainActor-default isolation. Genuinely well-engineered files (`EPUBPackage`, `DataMaturityEngine`, `EstimationEngine`, the Sentinel security doctrine). Submission-adjacent basics already exist (privacy manifest, usage strings, sandbox, ATS-clean network).

**Weaknesses.** Unpruned lifetime-growth persistence; several main-actor re-analysis paths that stall at 10× volume; ~12–15% dead code; a test belt that pins the persistence/engine layers superbly but leaves the only Release-reachable network feature (Discovery) and all view flows untested; zero App Store formalities attempted (icon, entitlements-gap, scheme/test-plan hygiene); historical " 2"-suffixed filenames in an auto-including synchronized folder.

## 8 · Documentation map

```
docs/
├── registers/    living truth: CURRENT_AUDIT (defects) · fix-log (protocol log) · handoff (session state)
├── roadmap/      REMEDIATION_ROADMAP (phases, mostly executed) · rsvp feature plan
├── method/       testing strategy
├── history/      FINAL_TRACES marathon log · profilerfix post-mortem · LAST_DEFEAT knowledge transfer
│                 freeze.txt (the 5-second sample of the frozen app) · diagnostics-2026-08-26.txt
├── audits/       DEEP_AUDIT_OCTOBER_2026.md (the full audit behind this README)
└── tree.md       regenerated project tree
```

Engineering standards (carried by `docs/registers/fix-log.md`): every fix needs a Finality statement, a fix-log entry, and a pinned regression test; suites must be green at every phase boundary; probe a frozen process (`sample`) before reasoning about performance.

## 9 · How to build / run / verify

```
open "Reading Tracker.xcodeproj"          # Xcode 26.5+ tooling (built here with Xcode 27.1)
# Run: ⌘R        Develop console: ⌘⇧D (Debug only)     Settings (goal editor): ⌘,
# Verify:
xcodebuild build -project "Reading Tracker.xcodeproj" -scheme "Reading Tracker" -configuration Debug -destination 'platform=macOS'
xcodebuild test  -project "Reading Tracker.xcodeproj" -scheme "Reading Tracker" -configuration Debug -destination 'platform=macOS' -only-testing:"Reading TrackerTests"
```

Runtime data lives under `~/Library/Application Support/johan.Reading-Tracker/` (`library.json`, `library-state.json`, covers, weather SQLite, `Backups/`, `sentinel-journal.jsonl`).

---

**Status: healthy, building, fully tested, and finally telling the truth about itself.** The next session should start at §5 §item 1 — and commit at every boundary, exactly like this one.
