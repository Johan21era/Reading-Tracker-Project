# ADR-3 — Packaged runtime distribution (engine + interpreter bundled with RT)

Status: **DIRECTION ACCEPTED + IMPLEMENTATION ACCEPTED — countersigned by the owner 2026-10-18 (bundle with the app); PR-8 implemented the plan below; closing round accepted the implementation with the app-embed delta (Resources/codesign exercised at first CI run / operator stage-into-app; owner Actions toggle pending)**

## Problem statement

RT's Mirage integration speaks to a local Python engine process. Today the engine location is
**dev-opt-in only**: the `MIRAGE_REAL_ENGINE_DIR` environment gate (PR-5). Shipping practices
(§14 Phase 9; PR-8's gate "bundled/provisioned runtime per approved ADR-3; signing/sandbox/
clean-machine/CI/performance/rollback") need a recorded runtime-distribution decision.

## Source-anchored comparative analysis

Engine-side facts (verified at the MirageV1.0 checkout, pinned SHA `81422613…`):
- `pyproject.toml`: pure **setuptools**; `requires-python = ">=3.11"`; MIT license;
  description "…as an **embeddable program**"; **no requirements.txt** — the whole engine is
  Python-standard-library-only. Interrogate-independently confirmed: no third-party imports
  surface in `src/` beyond stdlib.
- The sidecar runs as `python3 examples/mirage_sidecar.py <ledger-path>` (proven wire path,
  PR-4/PR-5 real-engine proofs).
- The engine also carries a `crates/` tree (a native-core track, unrelated to tonight's
  Python sidecar contract — see Direction 3 below).

| Direction | Verdict | Anchored reasons |
|---|---|---|
| **1 · Bundle engine + interpreter inside RT.app** | **ACCEPTED** (owner countersign, tonight) | Works offline day one; no user-time dependency probing; nothing to install; honors local-first by construction. Costs app size (a redistributable CPython 3.12-ish runtime ≈ 20–60 MB stripped + engine source ≈ a few MB) and build engineering. |
| 2 · Require system Python ≥ 3.11 | Rejected | `/usr/bin/python3` is an Apple shim that triggers Developer-Tools prompts and often resolves < 3.11 on user Macs (engine needs ≥ 3.11); version drift changes availability across macOS releases; degraded first-run UX violates the local-first "it just works" bar. |
| 3 · Native binary route (engine `crates/`) | Parked | Unverified tonight as a full sidecar replacement; would need its own pinned investigation before any ADR could argue it. Directory noted for the §22 era; NOT a PR-8 dependency. |

## Decision (PR-8 implementation charter)

1. **Staged bundle layout** inside `RT.app/Contents/Resources/mirage-runtime/`:
   - `bin/python3` — a **pinned python-build-standalone** CPython release (relocatable,
     redistributable; fetched at build time with a pinned release URL + sha256 recorded in
     the build manifest); stdlib trimmed per the relocatable semantics.
   - `mirage/` — the engine package `src/miragev10` copied verbatim from the pinned SHA +
     `examples/mirage_sidecar.py`.
   - `RUNTIME-MANIFEST.json` — engine version, interpreter version, content checksums
     (RT displays these in Settings ▸ Mirage's availability row — honest provenance).
2. **Locator ladder replaced wholesale** (the PR-5 gate becomes dev channel only):
   bundled channel (Bundle.main → `mirage-runtime`) → dev-opt-in gate (`MIRAGE_REAL_ENGINE_DIR`,
   unchanged for development) → unavailable copy (Settings row + sheet, "not available on
   this Mac yet"). No hardcoded absolute paths; every resolution is a Resource-relative,
   entitlement-safe path.
3. **Spawn contract unchanged** — same NDJSON wire, same banner/handshake/framing pins; the
   runtime merely changes WHERE the interpreter + engine live. The single lifecycle-per-gesture
   doctrine and the M-024 boundary findings carry over unchanged.
4. **Sandbox/codesign discipline** — bundled interpreter + engine carry the app's signing
   identity (build script codesigns the bundle entities); the spawn path stays inside the
   app's signed resources, so no additional entitlement is needed for spawning; network-free
   posture unchanged (engine is stdlib-only, local-only).
5. **Clean-machine gate** — a scripted verification from a fresh clone: build → spawn from
   the bundle → import a real fixture → census subset green. No machine-specific state.
6. **Rollback** — runtime updates arrive whole (previous bundle intact inside the previous
   app build); RT never mutates the bundle contents at runtime except REPLACING the whole
   directory atomically on upgrade; rollback = reinstall the previous signed app.
7. **CI publish** — GitHub Actions workflow (macOS runner) building the bundle + census;
   workflow file lands in PR-8; **publishing requires the owner to enable Actions on the
   GitHub repo (owner toggle)** — recorded as a machine-side-only prerequisite.

## Consequences

- `MIRAGE_REAL_ENGINE_DIR` becomes the DEVELOPMENT channel; Settings ▸ Mirage's availability
  row acts as the owner-facing honest surface.
- PR-8's verification pillar is the clean-machine script + census; §15's rehearsal ladder
  (rollback item) covers the runtime-swap rehearsal.
- App size grows by the runtime; the manifest makes the provenance inspectable.
- The §22 Titanium Bridge prerequisite ("packaged runtime per ADR-2 mentioned §22.4" — i.e.,
  ADR-3's bundle) becomes satisfiable once PR-8 lands its staging + CI.

## Security & privacy impact

Same local-only engine posture; the bundle adds no network entitlements; the manifest's
checksums make silent runtime tampering detectable; copying engine files verbatim at the
pinned SHA keeps RT's engine lineage auditable (§1 confidence rules).

## Tests

- `MirageBundledRuntimeTests` (PR-8): locator ladder pins (bundled found → used; missing
  → dev gate; neither → unavailable copy); manifest checksum verification; spawn-from-bundle
  smoke (opt-in real engine, disposable ledger) reusing the single-lifecycle harness.
- Clean-machine script output = the rehearsal-style artifact (§15-ES-3 discipline).

## Approving owners

- Direction (bundle with the app): **owner countersign 2026-10-18** (this ADR's Status).
- Implementation acceptance: at PR-8's close, with the clean-machine artifact attached.
