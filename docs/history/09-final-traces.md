# 09 · Final Traces (Performance Marathon)

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

(status: ✅ COMPLETE — commit 25c7318)

## PHASE A SHIPPED
- CoverStore.swift: files at covers/<uuid>.jpg, NSCache(300), serial writes,
  migrate/remove helpers. UUID-only filenames (security).
- BookImporter: PDF+EPUB captures → CoverStore by newBook.id; payload lean.
- DataStore.load: one-time migration embedded→files, clears payload field.
- removeBook: deletes cover file (no orphans).
- LibraryArchive v1.1: optional covers:[String:Data]; export collects files
  (+embedded fallback); import restores; v1 archives still decode.
- Pins: CoverStorePinsTests x5, DurabilityPins updated to store-contract.
- Commits: 25c7318.

## PHASE B LOG — Upgrade #5 AnalyticsCache
(status: ✅ COMPLETE — commit f616d04)
- AnalyticsCache.swift: signature = count ⊕ id-fold ⊕ session-count ⊕ epoch.
  Memoizes readerProfile/streak/timeOfDay/genreProfiles/trend.
- Engine entry points gain `epoch: UInt64 = 0` (>0 routes through cache;
  0 = uncached back-compat so zero callers break).
- DataStore.analyticsEpoch bumps in scheduleSave (all mutation paths flow
  through it) → invalidation on any real change.
- GoalProgressViewModel captures store ref at bind; refresh passes epoch.
- InsightEngine wired.
- Pins: AnalyticsCachePinsTests x3. Fixture lesson: updateBook w/ unknown id
  is a no-op by contract — mutation tests must use addBook.

## PHASE C/D LOG — Upgrade #4 safe slice (#3 groundwork next session)
(status: ✅ PARTIAL — commit 57bef63)
- PersistenceWriter.swift: owned serial queue for ALL library disk writes.
  saveImmediately drain = one-line barrier (no semaphore dance). This is the
  P6-G prescribed design — future DB adoption lands here.
- Actor variant attempted first, spiraled on isolation gymnastics under
  MainActor-default builds → git-reverted file, rewrote with DispatchQueue.
  Lesson: pick the simplest primitive that satisfies the contract.

## REMAINING BLUEPRINTS (for next sessions)

### Upgrade #3 full execution (split @Observable stores) — MEDIUM effort
Current: one ObservableObject (DataStore) publishes books/libraryState/
newlyEarnedAchievements/persistenceHealth — every emission wakes ALL views.
Plan:
1. iOS 17+/macOS 14+: convert DataStore → @Observable final class (drop
   ObservableObject/@Published). Views switch @EnvironmentObject → @Environment.
2. Split into LibraryStore (books), GoalStore (libraryState), HealthStore
   (persistenceHealth + newlyEarnedAchievements).
3. SessionCoordinator/GoalVM keep their own observables; they observe only
   the sub-store they read.
4. Migration pins: existing RemediationPins suite must stay green untouched
   (it exercises the same public API).
RISK: touches every view file (whole-file rewrites ×~20 views). Schedule a
fresh-context session; do 3 views per commit.

### Upgrade #1 full execution (normalized DB core) — XL effort
Prereq DONE: PersistenceWriter owns the disk queue (P6-G's blocker solved).
Plan:
1. Schema: books(id PK, payload JSON) / sessions(id PK, book_id, start, end,
   start_page, end_page) / page_times(session_id FK, idx, page, t0, t1) /
   library_state(key, payload). Indexes: sessions.book_id, page_times.session_id.
2. FULLMUTEX open + ALL access via PersistenceWriter.queue (the fix P6-G
   lacked).
3. Dual-read migration: on open, if legacy JSON exists and DB empty → import
   → rename *.migrated (never delete).
4. DataStore keeps its PUBLIC API byte-for-byte; internals swap. The whole
   RemediationPins battery is the acceptance test.
5. Load lazily: books array holds summaries; sessions/pageTimes load per-book
   on reader open. Analytics move to SQL aggregates (SUM/AVG/COUNT per book).
ESTIMATE: 2–3 fresh sessions. Do NOT attempt at end-of-context.

### Swift 6 mode (Upgrade #4 completion) — separate session
Flip SWIFT_STRICT_CONCURRENCY=complete, fix fallout (est ~20-40 sites, mostly
Sendable annotations on already-clean value types). Only after #3 lands.

## FINAL STATE AT HANDOFF
Commits this marathon: 25c7318 (#2), f616d04 (#5), 57bef63 (#4-slice),
+ this doc. Suite exit=0 verified after EACH phase. All pushed.
