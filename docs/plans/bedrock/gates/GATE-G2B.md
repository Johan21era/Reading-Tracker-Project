# Gate G2B — Mirage embedding and signing

**Date:** 2026-10-24
**Status:** READY FOR REVIEW
**Branch:** `bedrock/2026-10-24`

## Scope delivered

- [x] `Embed Mirage Runtime` build phase copies the staged runtime into
  `Reading Tracker.app/Contents/Resources/mirage-runtime`.
- [x] Pinned runtime staged locally: CPython 3.12.7 + engine SHA
  `81422613610701d81956394d9601bcb61e2938e9`.
- [x] `RUNTIME-MANIFEST.json` verified by the locator; file SHA spot-checks pass.
- [x] Nested interpreter/dylib/executable signing in the package script.
- [x] Bundle smoke runs from a **copy** of the runtime so Python cannot write
  `__pycache__` into the signed app.
- [x] Production spawn sets `PYTHONDONTWRITEBYTECODE=1` and passes `-B`.
- [x] App bundle contains **47 MB** runtime.
- [x] `MirageBundledRuntimeTests` includes an app-host runtime pin.

## Verification

- Built Debug app contains `Contents/Resources/mirage-runtime`.
- Embedded `bin/python3.12` SHA-256:
  `fe2572aa0c87557fc41b07afe929ed39ca4020ce78712f5b952fd099ab7da179`.
- Bundle smoke from embedded runtime:
  - banner `ready`
  - `version` OK
  - `books_list` OK
  - clean SIGTERM
- Release app codesign valid after smoke (smoke copy, no bundle mutation).
- Package zip contains runtime; first package smoke exposed and fixed the
  `__pycache__` seal-invalidation bug.

## Known deltas

- In-app “Analyze with Mirage” against a real EPUB is not yet exercised on the
  packaged build; the runtime + wire smoke is green.
- Sandbox child-process EPUB read still needs the real-engine in-app rehearsal.
- Mirage remains optional; disabling it still deletes nothing.

## Rollback

```bash
git checkout bedrock-g2
```
Remove `.mirage-runtime/` to return to a runtime-less build.

## Decision requested

- [ ] APPROVE
- [ ] APPROVE WITH CHANGES
- [ ] STOP
