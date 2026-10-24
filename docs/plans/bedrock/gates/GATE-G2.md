# Gate G2 — Local distribution baseline

**Date:** 2026-10-24
**Status:** READY FOR REVIEW
**Branch:** `bedrock/2026-10-24`

## Scope delivered

- [x] Interim app icon generated (`scripts/generate-app-icon.py`) with all macOS sizes.
- [x] `Assets.car` + `AppIcon.icns` now present in the built app.
- [x] Added sandbox location entitlement for Open-Meteo.
- [x] Removed the read-only/read-write entitlement conflict; `ENABLE_USER_SELECTED_FILES = readwrite`.
- [x] Removed the empty `CFBundleIdentifier` source key; generated bundle ID remains `johan.Reading-Tracker`.
- [x] Shared `.xcscheme` committed; testables are non-parallel.
- [x] Release build + ad-hoc signing + zip packaging script.
- [x] Stripped FileProvider/Finder xattrs (BUG-003) and staged signing in system temp.
- [x] `dist/Asterisma-1.0-arm64.zip` + SHA-256.

## Verification

- Debug build: **BUILD SUCCEEDED**
- Release build: **BUILD SUCCEEDED**
- `codesign --verify --deep --strict`: **valid on disk / satisfies its Designated Requirement**
- `spctl`: **rejected** as expected for ad-hoc, no-notarization build
- Zip: `dist/Asterisma-1.0-arm64.zip` (25 MB)
- SHA-256: `954b01906b9387b64230c6856f49b0b2f923d6277098a6b1253a05676c7dd34a`
- App icon visible in built bundle; `CFBundleIconName = AppIcon`

## Known deltas

- First launch on a friend's Mac requires **right-click → Open** (or one `xattr -d com.apple.quarantine`). True double-click seamless requires Developer ID + notarization later.
- Clean-account launch rehearsal still pending; the package itself is valid.
- Icon is an interim generated mark; final artwork can replace it without code changes.

## Rollback

```bash
git checkout bedrock-g1
```

## Decision requested

- [ ] APPROVE
- [ ] APPROVE WITH CHANGES
- [ ] STOP
