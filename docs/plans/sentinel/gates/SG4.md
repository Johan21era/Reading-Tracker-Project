# Gate SG4 — Release Health Center

**Date:** 2026-10-28
**Branch:** `main`
**Base commit:** `6099e4e`
**Tree state:** committed in `40bc922`; GitHub `census` green at `6aecdc3`

**Decision:** PASS WITH KNOWN DELTAS — owner review required.

---

## Delivered

| SG4 deliverable | State | Evidence |
|---|---|---|
| Release Health Center window | Done | `Window("Sentinel Health", id:)`, ⌘⇧H command |
| Overview / Issues / History / Checks / Settings tabs | Done | `SentinelHealthCenterView` |
| The five user questions answered | Done | Band + headline; issue list/detail; why; actions; coverage |
| Issue detail: what, why, right now, if left alone, evidence | Done | `SentinelIssueDetailView` |
| Preview before fix; undo from History | Done | Repair preview sheet; History tab |
| Snooze / acknowledge / ignore / reopen | Done | Runtime status edges + view model |
| Coverage-honest bands (unknown when incomplete) | Done | `SentinelHealthModel.compute`; skipped-probe test |
| Launch report card, once per day for all-clear | Done | `SentinelLaunchCardBuilder`; 6 launch tests |
| Settings for autonomy, cadence, quiet hours, domains, notifications | Done | Health Center Settings; Settings root pane |
| Notifications opt-in, quiet hours, one per issue per week | Done | `SentinelNotificationPolicy`; 5 policy tests |
| Static notification body with no user text | Done | Policy tests |
| Redacted diagnostics export | Done | `SentinelDiagnostics`; export test; Settings button |
| Release and Debug both compile the surface | Verified | Release build exit 0 |

---

## Verification

| Check | Result |
|---|---|
| Launch-card states (fixed, decision, incomplete, all-clear, quiet, no-cycle) | **6/6 passed** |
| Notification policy (off, sentinel-off, quiet, threshold, weekly cap, safe body) | **5/5 passed** |
| Diagnostics (valid JSON, registry, no title/path/debug detail) | **1/1 passed** |
| Health Center is reachable in Release | Window + `.commands` are outside `#if DEBUG` |
| Release build | exit 0 |

Census receipt: `census-2026-10-28.md` (temporary `.xcresult` not retained)

---

## Known deltas

- **Menu bar surface is not shipped.** A `MenuBarExtra` scene was implemented, then removed after it hung the test host on the main thread (`MenuBarExtraController` spin). The `menuBarEnabled` configuration key remains reserved for a future implementation; no menu bar scene reads it, and the toggle was removed from Settings so there is no dead Release control.
- **Automated accessibility testing is not present.** Labels and hints are present, and the layout is native SwiftUI, but there is no VoiceOver or largest-Dynamic-Type UI test. SG4's "accessibility pass" criterion is **not verified**.
- **System notification delivery is not integration-tested.** The pure policy, quiet hours, weekly cap, and redaction are pinned; `UNUserNotificationCenter` delivery/permission is exercised only by the thin bridge.
- **First-run education is minimal.** The Health Center's empty state explains coverage; there is no separate guided first-run tour.
- **Localization is English-only.**

---

## Rollback

Remove the Health Center `Window`, the Settings pane entry, and the launch card. Notifications are opt-in and default off; resetting `SentinelNotifier` bookkeeping makes them inert. No user data is migrated by this surface.

---

## Next phase

SG5 — data-system coverage (SQLite, backups, files, subsystems).
