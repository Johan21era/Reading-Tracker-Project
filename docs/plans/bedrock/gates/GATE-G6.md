# Gate G6 — Behavior Context V3

**Date:** 2026-10-24
**Status:** ENGINE + UI + EVIDENCE PERSISTENCE PASS
**Branch:** `bedrock/2026-10-24`

## Scope delivered

- [x] `BehaviorContextEngine.intelligenceReport` stores the full V3 report.
- [x] Session-close cascade now runs `analyzeWithIntelligence()` (V3), not V1 only.
- [x] App launch analyzes existing history via `SessionEventRouter.analyzeHistory`.
- [x] V3 feeds `FullIntegrationInput` through the existing adapters.
- [x] Fixed NEW-DE-9: narrative evidence no longer fabricates `Date()` sampling
  timestamps; it uses the real reading-session start date.
- [x] Behavioral evidence survives relaunch via a local
  `behavior-evidence.json` archive (retention policy applied on load).
- [x] Simple “Your Context” panel gains an “Advanced Context” button.
- [x] New Advanced Context window: cited narratives, routines, evidence quality,
  diversity, transitions/trends, provenance note.
- [x] `G6ContextPinsTests`: 10-session history produces a stored V3 report.
- [x] `G6EvidencePersistenceTests`: archive loads application sessions.

## Known deltas

- Evidence persistence is a JSON archive, not the SQLite behavior tables yet.
  The observation API is unchanged; the SQLite migration can replace the
  archive later without touching the engine.
- Advanced Context is a Window scene, not an inline detail pane.
- V3 still uses deterministic rules; no LLM/network.

## Rollback

```bash
git checkout bedrock-g4
```
