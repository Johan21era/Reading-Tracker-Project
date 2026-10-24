# Local Distribution — Bedrock

## What we ship

- `dist/ReadingTracker-1.0-arm64.zip`
- Ad-hoc signed `Reading Tracker.app`
- SHA-256 checksum alongside the zip

This is a **local/friend build**, not a notarized App Store build.

## Friend install (one-time Gatekeeper step)

1. Download and unzip `ReadingTracker-1.0-arm64.zip`.
2. Drag `Reading Tracker.app` to `/Applications` (or run it from Downloads).
3. First launch: **right-click the app → Open → Open**.
   - Or run once:
     ```bash
     xattr -d com.apple.quarantine "/Applications/Reading Tracker.app"
     ```
4. Subsequent launches are normal double-click.

The “unidentified developer” warning is expected because the build is ad-hoc
signed and not notarized. Making it truly seamless requires a paid Apple
Developer account, Developer ID signing, and notarization. The code/bundle is
kept App Store-compatible so that upgrade is a signing/pipeline change, not a
rewrite.

## Verification

```bash
codesign --verify --deep --strict --verbose=2 "Reading Tracker.app"
shasum -a 256 -c ReadingTracker-1.0-arm64.zip.sha256
```

## Clean-account rehearsal

At Gate G2 we test:
- launch on a fresh macOS user account;
- first-run onboarding;
- import a PDF/EPUB;
- read and page-turn;
- quit and relaunch;
- verify the library persisted.
