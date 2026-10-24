# Gate G8 — Final acceptance / release candidate

**Date:** 2026-10-24
**Status:** RELEASE CANDIDATE — OWNER REVIEW
**Branch:** `bedrock/2026-10-24`

## Acceptance checklist

- [x] Debug and Release build clean.
- [x] Full census **212 passed / 0 failed / 9 skipped** (221 cases).
- [x] Real store cut over to `library.grdb.sqlite3`:
  7 books / 292 sessions / 138,459 page timings.
- [x] Legacy JSON renamed `.migrated`; app relaunched successfully from SQLite.
- [x] SQLite load **5.06 ms** vs JSON baseline **493.7 ms**.
- [x] SQLite daily backup + Sentinel pre-repair snapshot.
- [x] Open-Meteo weather provider + live session→snapshot→SQLite proof.
- [x] Mirage runtime embedded/signed; bundle smoke green.
- [x] EPUB metadata (genre/series/word count), Book Details, notes, collections.
- [x] Behavior Context V3 report + Advanced Context window + evidence archive.
- [x] Dead `LibraryView` and legacy recommendation engines removed (−1,157 lines).
- [x] App entry file renamed to `ReadingTrackerApp.swift`.
- [x] README/defect register carry Bedrock status notes.
- [x] Ad-hoc signed Release `.zip` produced; `codesign --verify --deep --strict` passes.
- [x] Packaged-app launch smoke: **PASS**.
- [ ] Owner acceptance signature.

## Known deltas (must be read with acceptance)

1. **Swift 6 language mode deferred.** Strict mode produced 148 actor-isolation
   errors; compiler settings were reverted. Dedicated follow-up.
2. **Reader selection highlights/quotes deferred.** Plain/Markdown notes, tags,
   page anchors, and collection management are live; EPUB/PDF text selection
   highlighting is not.
3. **Behavior evidence uses a JSON archive**, not the SQLite behavior tables.
4. **Collection rename has no UI** (create/delete/membership work).
5. **Old artifacts remain**: P5-G `library.sqlite3`, old `.migrated` files,
   graphify bulk. They are non-live; cleanup is cosmetic.
6. **CI runner mismatch** remains a release-pipeline item; local census is the
   authoritative receipt.

## Distribution

- Package: `dist/ReadingTracker-1.0-arm64.zip`
- SHA-256: `10170b30f01b1e9cc8e3e3d5517d660fa6cb482c57d4783e01091df0858d1001`
- Ad-hoc signed, not notarized.
- First launch requires right-click → Open (documented in `DISTRIBUTION.md`).

## Rollback

```bash
git checkout bedrock-g7
```
Data rollback: restore `library.json.migrated-2026-10-24` and
`library-state.json.migrated-2026-10-24`, or the pre-Bedrock snapshot.

## Decision requested

- [ ] ACCEPT RELEASE CANDIDATE (with deltas)
- [ ] CHANGES REQUIRED
- [ ] STOP
