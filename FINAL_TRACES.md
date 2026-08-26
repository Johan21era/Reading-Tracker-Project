# FINAL TRACES — Production Performance Upgrade Marathon

**Mission:** Execute the 5 systems-level upgrades (no new features):
1. Normalized database core (retire mega-JSON)
2. Covers → content-addressed files + NSCache (evict images from data payload)
3. Split @Observable stores (fine-grained reactivity)
4. Swift 6 mode + persistence actor (deliberate concurrency)
5. Derived-data layer (compute once, invalidate surgically)

**Operator condition:** this file documents EVERYTHING as I go, so any future
session can pick up exactly where I stopped.

## Execution order (risk-graded)
- **Phase A** = Upgrade #2 (covers→files). Highest value, smallest blast radius.
- **Phase B** = Upgrade #5 (AnalyticsCache for O(timings) hot spots).
- **Phases C/D/E** (#3/#4/#1) = deep blueprints below IF context remains;
  otherwise they are fully specified for the next session.

## Standing lessons that shape every decision
- `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`: every function needs explicit
  `nonisolated` or it silently hops to main. Check EVERY function on any
  background path.
- Whole-file rewrite tooling: never touch BehaviorContextEngine2 /
  BehavioralCategory without a dedicated fully-read session.
- Suite must be green (exit=0) at every boundary; push each milestone.
- Test-env quirk: SQLITE_ENABLE_THREAD_ASSERTIONS kills cross-thread sqlite
  handle use — any DB work needs FULLMUTEX + owned serial queue + stress
  suite BEFORE rewiring (see P6-G post-mortem in fix-log).

---

## BASELINE
- Commit at mission start: b8b49d2 (+8e45e00 lineage). Last full suite: exit=0.
- Re-verifying now per protocol before touching anything.

## PHASE A LOG — Covers → files + NSCache
- Design: CoverStore (thread-safe, injectable dir for tests) at
  AppSupport/ReadTracker/covers/<uuid>.jpg; NSCache<NSString,NSImage>.
- Book.coverImageData REMAINS in schema as legacy fallback; new imports write
  external files and leave the field nil; load-time migration extracts
  embedded covers to disk and clears them (one-time per book).
- Archive v1 gains OPTIONAL `covers:[String:Data]` (decodeIfPresent) so
  DurabilityPins round-trip still proves covers survive.
- View surface unchanged: Book.coverImage checks store → falls back embedded.

(status: IN PROGRESS)
