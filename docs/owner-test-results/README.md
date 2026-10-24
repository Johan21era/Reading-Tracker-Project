# Owner Test Results

This folder holds the owner's personal test sessions.

**These results are the absolute source of truth.** They override all previous benchmarks, censuses, gate receipts, and documentation claims. See `docs/12-owner-test-authority.md`.

## Naming

```text
YYYY-MM-DD-session-N.md
```

Example: `2026-10-24-session-1.md`

## Start a session

1. Quit the app.
2. Snapshot the live data root (see the command in `docs/12-owner-test-authority.md` or the session template).
3. Copy `TEMPLATE.md` to the session filename.
4. Test the release package first; use Xcode Run only when you need the debugger or Developer Console.
5. Record expected vs actual for every check. A blank result is not a pass.
6. Commit the file and tag the session:
   `git tag owner-test-results-YYYY-MM-DD`.

## Precedence

1. Newest owner result.
2. Live app behavior and live library data.
3. Automated census and benchmarks.
4. Historical docs, graph reports, and AI summaries.

A FAIL is a release blocker until fixed or explicitly waived by the owner.
