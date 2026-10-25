# Gate G8 — Final acceptance / release candidate

**Date:** 2026-10-24
**Status:** ACCEPTED — MERGED AND PUSHED
**Branch:** `main`
**Release commit:** `6da2d81`
**Release tag:** `asterisma-v1.0-mvp`
**Merged main:** `aba8aa4`

## Acceptance checklist

- [x] Debug and Release build clean.
- [x] Full census **213 passed / 0 failed / 9 skipped** (222 cases) — re-run on merged `main`.
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
- [x] App entry file renamed to `AsterismaApp.swift`.
- [x] README/defect register carry Bedrock status notes.
- [x] Ad-hoc signed Release `.zip` produced; `codesign --verify --deep --strict` passes.
- [x] Packaged-app launch smoke: **PASS**.
- [x] Owner acceptance signature.

## Release receipt

- Owner accepted the release candidate on 2026-10-24.
- `bedrock/2026-10-24` fast-forwarded `main` from `bafb9e9` to `aba8aa4`;
  pushed as `origin/main`.
- `asterisma-v1.0-mvp` and all six Bedrock tags pushed to GitHub.
- Release package: `dist/AsterismaV1.0-1.0-arm64.zip`
- SHA-256: `c77b61af98a6b193f17882bc4abd72119b67b6a232473aa67490e149dcdad649`

**Post-acceptance authority:** the owner's personal test results are the
absolute source of truth from 2026-10-24 onward and override this receipt and
every prior benchmark/census. See `docs/12-owner-test-authority.md`.

### Owner-test fixes (post-acceptance)

The first owner run found three defects the green census missed. They are fixed
on top of the accepted release:

- Commit `9a0cc76`; tag `asterisma-v1.0-test-reset`.
- Package: `dist/AsterismaV1.0-1.0-arm64.zip`
- SHA-256: `c77b61af98a6b193f17882bc4abd72119b67b6a232473aa67490e149dcdad649`
- F1: packaged app now carries its sandbox/entitlements.
- F2: onboarding Finish now dismisses the sheet.
- F3: Add Book accepts iBooks-style unzipped `.epub` directories.
- F4: windowed toolbar and green zoom repaired with a standard title bar and a 1000x680 minimum.
- F5: seamless fullscreen surface — flat sidebar, unified canvas, focus-only search ring; library toolbar removed.
- F6: Add Book picker rejects parent folders and admits PDF/EPUB files and iBooks EPUB packages.
- Regression pin: `FolderEPUBImportTests`.
- Owner retest is the acceptance gate for this candidate.

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

- Package: `dist/AsterismaV1.0-1.0-arm64.zip`
- SHA-256: `c77b61af98a6b193f17882bc4abd72119b67b6a232473aa67490e149dcdad649`
- Ad-hoc signed, not notarized.
- First launch requires right-click → Open (documented in `DISTRIBUTION.md`).
- Bundle ID remains `johan.Reading-Tracker` for MVP container compatibility;
  changing it requires a dedicated sandbox-container migration.

## Rollback

```bash
git checkout asterisma-v1.0-mvp
```

Data rollback: the pre-rename snapshot was deleted by the owner on 2026-10-24.
No local data snapshot remains; use Time Machine or an external backup if one
exists, and check out the pre-rebrand tag if needed.

## Decision

- [x] ACCEPT RELEASE CANDIDATE (with deltas)
- [ ] CHANGES REQUIRED
- [ ] STOP
