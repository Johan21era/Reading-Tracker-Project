# Asterisma Rebrand — MVP

**Date:** 2026-10-24
**Official product name:** **Asterisma**
**MVP build name:** **AsterismaV1.0**

---

## What changed

| Layer | New value |
|---|---|
| Product / app bundle | `AsterismaV1.0.app` |
| Display name | `AsterismaV1.0` |
| Xcode project | `AsterismaV1.0.xcodeproj` |
| App target / scheme | `AsterismaV1.0` |
| Test targets | `AsterismaV1.0Tests`, `AsterismaV1.0UITests` |
| Swift module | `AsterismaV1_0` |
| App entry point | `AsterismaApp.swift` / `AsterismaApp` |
| Source folder | `AsterismaV1.0/` |
| Entitlements | `AsterismaV1.0.entitlements` |
| Info.plist | `AsterismaV1.0-Info.plist` |
| Release package | `dist/AsterismaV1.0-<version>-arm64.zip` |
| Data root | `Application Support/Asterisma/` (auto-migrates from `ReadTracker/`) |
| User-facing copy | “AsterismaV1.0” |

## Deliberate MVP constraint: bundle identifier

The sandbox container is keyed by bundle identifier. Changing it would create a
new, empty container and orphan the current library. For the MVP:

- **Display/product name:** AsterismaV1.0
- **Internal bundle id:** `johan.Reading-Tracker` (unchanged, not user-visible)

A future distribution release should adopt `com.asterisma.app` with an explicit
container-migration plan (outside-sandbox copy or a security-scoped migration
helper). Do not change the bundle id casually.

## Data migration

`AppIdentity` moves the legacy data root in place on first launch:

```text
~/Library/Containers/johan.Reading-Tracker/Data/Library/Application Support/
  ReadTracker/  →  Asterisma/
```

The migration is:
- only performed when the new directory does not exist;
- a move first, then a copy fallback;
- leaves the legacy directory untouched if it cannot move/copy;
- never deletes user data.

The weather store migrates into the Asterisma root on next weather-service init.

## Verification

- Live migration run: `ReadTracker` removed, `Asterisma` created.
- SQLite counts after migration: **7 books / 292 sessions / 138,459 timings**.
- App launched successfully under `AsterismaV1.0.app`.
- Full rebrand census: **213 passed / 0 failed / 9 skipped** (222 cases), re-run
  on the merged `main`.
- Release package built, ad-hoc signed, and launch-smoked:
  `dist/AsterismaV1.0-1.0-arm64.zip`.

## Release receipt

- `main` fast-forwarded from `bafb9e9` to `aba8aa4` and pushed to GitHub.
- Release commit: `6da2d81`; tag: `asterisma-v1.0-mvp`.
- Owner-test fixes: `0ec5127`; tag: `asterisma-v1.0-owner-test-fixes`.
- Package SHA-256:
  `31dc0abf35ea7cba4eeb9ab8580b6a60eeee6e10086bc7d3759f174dd33447cc`.
- Canonical worktree: `/Users/johanrembeci/Desktop/AsterismaV1.0`.

## Rollback

The pre-rename snapshot was deleted by the owner on 2026-10-24:

```text
~/Desktop/Asterisma-Backups/2026-10-24-pre-rename/   (deleted)
```

There is no local data snapshot anymore. Use Time Machine or an external
backup if one exists, then check out `bedrock-g8` (the last pre-rebrand release
candidate) if needed.
