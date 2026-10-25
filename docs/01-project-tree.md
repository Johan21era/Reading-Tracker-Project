# 01 · Project Tree

## What this document is

This is a map of every file and folder in the project, organized so you can find your way around without needing to know how to code.

**Think of it like a building directory:** the top level is the project folder itself; inside are folders for documentation, the actual app code, tests, and the Xcode project settings.

---

## The top level (what you see when you open the project folder)

| Folder / file | What it is |
|---|---|
| `README.md` | The front door — start here |
| `docs/` | All project documentation (registers, roadmap, audit, history, the Mirage integration campaign, etc.) |
| `RT_Mirage_Codebase_Merge_Playbook.md` | Owner's kept snapshot of the merge playbook (tracked canon: `docs/integration/` — ignored here by `.gitignore`) |
| `merge-log.md` | Owner's kept snapshot of the campaign log (tracked canon: `docs/integration/merge-log.md` — ignored here by `.gitignore`) |
| `AsterismaV1.0/` | The actual app code — every Swift file that makes the app work |
| `AsterismaV1.0Tests/` | Automated tests that prove the app works correctly |
| `AsterismaV1.0UITests/` | User-interface tests (mostly placeholder stubs) |
| `AsterismaV1.0.xcodeproj/` | The Xcode project file (do not edit by hand) |
| `AsterismaV1.0.entitlements` | Permissions the app asks macOS for (sandbox, user-selected files, location) |
| `AsterismaV1.0-Info.plist` | App settings such as its name, icon, and location description |
| `scripts/` | Census, benchmark, test-isolation, runtime staging, icon, and release-package scripts |
| `dist/` | Locally built release packages (gitignored) |
| `graphify-out/` | Generated knowledge graph, report, and interactive HTML |
| `.gitignore` | Tells Git which files to ignore (build junk, user settings, etc.) |

---

## The `docs/` folder (documentation)

Every documentation file begins with a number so you can read them in order:

| File | Number | What it is | Who should read it |
|---|---|---|---|
| `README.md` | 00 | Project overview and front door | Everyone, first |
| `docs/01-project-tree.md` | 01 | This file — where everything lives | Everyone |
| `docs/registers/02-defect-register.md` | 02 | Everything known to be broken or risky | Anyone who wants to fix bugs |
| `docs/registers/03-fix-log.md` | 03 | Everything that has been fixed, with proof | Anyone who wants to understand the history |
| `docs/registers/04-handoff.md` | 04 | What to do next, in order | Anyone who wants to contribute |
| `docs/roadmap/05-remediation-roadmap.md` | 05 | The long-term plan, phase by phase | Anyone planning future work |
| `docs/roadmap/06-rsvp-feature-plan.md` | 06 | Plan for the speed-reading feature | Anyone working on that feature |
| `docs/method/07-testing-strategy.md` | 07 | How tests are written and why | Anyone writing tests |
| `docs/audits/08-deep-audit.md` | 08 | The full independent audit from Oct 2026 | Anyone who wants the complete picture |
| `docs/audits/11-completion-and-health-report-2026-10-24.md` | 11 | Bedrock-era completion and health snapshot | Anyone reviewing the release |
| `docs/REBRAND-ASTERISMA.md` | — | Asterisma rename + data-root migration record | Anyone touching names, paths, or the bundle ID |
| `docs/plans/bedrock/` | — | G0–G8 gate record, master plan, baseline, distribution notes | Anyone auditing the release |
| `docs/design/fullscreen-surface-audit.md` | — | Fullscreen surface audit, border inventory, and after capture | Anyone reviewing the UI |
| `docs/12-owner-test-authority.md` | 12 | The owner's personal test results are the absolute source of truth | Everyone — this overrides all other claims |
| `docs/owner-test-results/` | — | Personal test sessions, template, and evidence | The owner, then anyone acting on the results |
| `docs/history/09-final-traces.md` | 09 | Diary of the performance upgrade marathon | Anyone interested in performance history |
| `docs/history/10-profiler-fix.md` | 10 | The story of how the big freeze was finally fixed | Anyone interested in the freeze mystery |

**The integration chapter — `docs/integration/`** (added by the Oct 2026 RT–Mirage merge campaign; its own ID space lives inside the folder):

| File | What it is | Who should read it |
|---|---|---|
| `RT_Mirage_Codebase_Merge_Playbook.md` | The playbook that governed — and still governs the §22/TiB era of — the merge | Anyone touching Mirage |
| `merge-log.md` | The campaign log of record (M-014 onward, append-only) | Anyone who wants the full history with receipts |
| `final-acceptance-2026-10-18.md` | The closing acceptance checklist, receipt per row | Reviewers |
| `adr/` | The ADR register: transport, packaged runtime, ledger stratum, identity mapping, feature lifecycle, spoiler-cursor contract, repository strategy, TiB charter | Anyone changing the boundary |
| `evidence/` | The §19 evidence bundle manifest + the operational handoff bundle + receipt artifacts | Reviewers / release owner |
| `phase1/` | Pre-ladder extractions: the 28-action wire protocol, RT touchpoints, normative-doc pins | Anyone on the wire |
| `rehearsals/` | §15 rehearsal log: rollback census, backup-restore re-pin, runtime staging/swap | Ops |
| `tib/` | §22 Titanium Bridge: TiB charter (ADR-12), TB-M0 gate plan + observation ledger | The next sessions |

Also in `docs/history/`:
- `freeze.txt` — a raw 5-second forensic sample of the app while it was frozen (technical, not meant to be read cover to cover)
- `diagnostics-2026-08-26.txt` — raw build output from August 26 (technical)
- `LAST_DEFEAT_demo_profiles.txt` — the complete story of the freeze hunt, written to be read by anyone

---

## The app code (`AsterismaV1.0/`)

This folder contains every Swift file that makes the app run. They are grouped by what they do:

| Group | Contains |
|---|---|
| `Core/` | The heart of the app: the data store, book models, validators, persistence, Sentinel watchdog |
| `Engines/` | The "accountants": analytics, estimation, data maturity, insights |
| `Features/` | Everything the user sees and touches: books, reader, goals, weather, audio, achievements, onboarding, reports, RSVP speed-reading, developer console — and `Mirage/` (14 typed files: the RT-side of the Mirage integration — wire types, client, sidecar supervisor, runtime locator, cursor gate, status surface, settings, identity map, import flow, sheet, mount, transport, child-process, protocol constants) |
| `Assets.xcassets` | Pictures, colors, and icons used in the app |

---

## The tests (`AsterismaV1.0Tests/` and `AsterismaV1.0UITests/`)

These are automated checks that run without you having to click anything. Each test is named after the specific bug or behavior it guards. If a test ever starts failing, that is an early warning that something broke.

As of the AsterismaV1.0 release (2026-10-24): 46 test files, 222 `@Test` functions, standing default census **215 passed / 0 failed / 9 skipped**. The 9 skips are deliberate opt-in gates: 4 Mirage real-engine, 1 benchmark, 2 real-library SQLite parity, and 2 live Open-Meteo (see `docs/method/07-testing-strategy.md` for how to engage them).

---

## How to use this map

- **If you want to fix a bug:** Start with `02-defect-register.md`, find the item you want to work on, then use this map to locate the relevant source file.
- **If you want to understand how a feature works:** Find the feature group in `Features/` and open the file with the same name.
- **If you are lost:** Come back to this file, or start over at `README.md`.
