# Local Distribution — AsterismaV1.0

## What we ship

- `dist/AsterismaV1.0-1.0-arm64.zip`
- Ad-hoc signed `AsterismaV1.0.app`
- SHA-256 checksum alongside the zip

This is a **local/friend build**, not a notarized App Store build.

**Release refs:** `main` at `aba8aa4`; release commit `6da2d81`, tag
`asterisma-v1.0-mvp`. SHA-256:
`ade4a54e3cbe233e14b809c32988422f4ace4aed7e9c855a9bcb269d20f58a96`.

## Friend install (one-time Gatekeeper step)

1. Download and unzip `AsterismaV1.0-1.0-arm64.zip`.
2. Drag `AsterismaV1.0.app` to `/Applications` (or run it from Downloads).
3. First launch: **right-click the app → Open → Open**.
   - Or run once:
     ```bash
     xattr -d com.apple.quarantine "/Applications/AsterismaV1.0.app"
     ```
4. Subsequent launches are normal double-click.

The “unidentified developer” warning is expected because the build is ad-hoc
signed and not notarized. Making it truly seamless requires a paid Apple
Developer account, Developer ID signing, and notarization. The code/bundle is
kept App Store-compatible so that upgrade is a signing/pipeline change, not a
rewrite.

The sandbox bundle identifier remains `johan.Reading-Tracker` for this MVP so
the existing container and library are preserved. A future Asterisma bundle ID
requires a dedicated container-migration release.

## Verification

```bash
cd dist
shasum -a 256 -c AsterismaV1.0-1.0-arm64.zip.sha256

# after unzipping / installing:
codesign --verify --deep --strict --verbose=2 "/Applications/AsterismaV1.0.app"
```

## Clean-account rehearsal

At Gate G2 we test:
- launch on a fresh macOS user account;
- first-run onboarding;
- import a PDF/EPUB;
- read and page-turn;
- quit and relaunch;
- verify the library persisted.

The clean-account rehearsal remains pending; the packaged-app launch smoke on
this Mac passed.
