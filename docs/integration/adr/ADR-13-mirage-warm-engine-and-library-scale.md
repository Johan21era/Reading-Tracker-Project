# ADR-13 — Warm Mirage engine, cached library index, and batch analysis

**Status:** IMPLEMENTED IN THE WORKING TREE — 2026-10-29. Direction requested by the owner in the current session ("massive Mirage systems overhaul … scale its strength multiple times over"). This record supersedes **ADR-6 decision 5 only**; the other ADR-6 decisions remain in force. Owner acceptance of this record is pending the close-out review.

**Date:** 2026-10-29
**Series:** RT ↔ Mirage integration, ADR-13
**Approving owners required:** Johan Rembeci (all roles, per the merge playbook)

## Problem statement

The integrated Mirage path was mechanically sound but operationally single-shot:

- every explicit gesture spawned a Python sidecar, completed one request, and killed it (`MirageAnalyzeSession.performImport` before this change);
- a per-book status check paid the same cold-start handshake;
- there was no library-wide read, so a reader with 200 EPUBs had no way to analyze them without 200 separate gestures;
- the only cached view of the engine was the per-book identity map, so the UI could not report coverage or reconcile links after the engine's inventory changed.

ADR-6 decision 5 deliberately kept one-analyze-per-lifecycle because of the M-024 "one spawn per process" machinery boundary. The M-027 root-cause campaign tested four shapes and found no such boundary under the production path; the original observation was most plausibly a machine-stress artifact. That removes the reason to pay a cold start for every request.

## Decision

### 1. One warm, app-scoped session

A single `MirageEngineService` owns at most one `MirageAnalyzeSession` for the app process. The session's supervisor, transport, handshake, identity store, and typed outcomes are unchanged. The service:

- resolves the runtime ladder only when a session is first needed;
- keeps the session warm across explicit requests;
- serializes every engine operation through an in-service FIFO gate, because the pipe transport is single-lane by contract;
- reuses the same identity store for analysis, verification, and library scans.

### 2. Lifecycle boundaries

The warm engine never starts by itself:

- `start`, `analyze`, `verify`, and `scanLibrary` are the only entry points, and each is an explicit user gesture (Settings button, sheet button, or check button);
- an idle session stops after **10 minutes** by default (`MirageEngineService.init` `idleInterval`);
- turning Mirage off in Settings stops the session;
- moving the app to `.background` stops the session after any in-flight request finishes;
- `stop()` never deletes the ledger, identity map, or library index.

Terminal handshake faults surface as a failed state. Recovery is the explicit `retry` gesture (which clears the supervisor's terminal state); there is no unbounded automatic restart.

### 3. Cached library index

`MirageLibraryIndex.refresh` spends exactly **one** read-only `books_list` call per scan and writes `mirage/library-index.json` (`mirage-library-index@1`) atomically. It also reconciles every active identity link in one identity-map write: links whose `(book_id, edition_id)` pair is absent from the fresh inventory become orphaned with reason `edition-gone`.

The index is derived data and safe to delete. It never invents a book, edition, unit, or claim; malformed inventory rows refuse the entire refresh rather than partially caching.

### 4. Batch analysis is a sequencer, not a second execution path

`MirageBatchAnalyzer` plans EPUB-only jobs and calls the same `MirageEngineService.analyze` used by the sheet. It does not open a second transport, bypass the request gate, or alter the identity-map commit rules. It:

- runs jobs sequentially;
- cancels cooperatively at the flow's existing checkpoints and marks unstarted jobs cancelled;
- retries failed jobs only, never successful ones;
- reports per-book linked/failed/cancelled state in Settings ▸ Mirage.

### 5. Ownership and persistence are unchanged

Mirage still writes only inside `<Application Support>/Asterisma/mirage/`. The ledger remains Mirage-owned, the identity map remains RT-written, and the index is a third, derived file in the same directory. RT's library, goals, and reading progress are not read or written by any new path.

## Alternatives considered

- **Keep one spawn per gesture** — rejected: the measured cold-start cost makes library-scale analysis and repeated status checks impractical.
- **A background daemon outside the app** — rejected: violates the local-first, single-instance pid-guard posture and adds a second lifecycle owner.
- **Parallel batch workers** — rejected: the NDJSON transport is one request at a time; concurrency would interleave bytes on the same pipes. Parallelism would need a second process/ledger design, which this ADR does not authorize.
- **Persisting the batch queue across launches** — not taken here: the queue is session-scoped and explicitly re-planned from the live library. A future durable queue needs its own restore/ownership decision.
- **Deleting the index when Mirage is disabled** — rejected: disable remains a UI gate, not a data operation (ADR-6 decision 3).

## Consequences

- The second book in a session starts without a sidecar cold start; a library scan is one request instead of one per book.
- The Settings pane can show coverage, last-scan freshness, warm/asleep state, and per-book batch progress without touching the engine.
- A crashed or idle-stopped session is re-handshaken by the next explicit request; the pid guard and bounded restart ladder still apply to each handshake.
- The app must be allowed to keep one child process alive while the feature is warm. Scene-background and idle teardown bound that lifetime.
- The old "one analyze = one clean lifecycle" copy in ADR-6 and the 2026-10-28 deep-dive is historical; both now point here.

## Tests

Implemented and passing on 2026-10-29:

| Suite | Pins |
|---|---|
| `MirageEngineServiceTests` | explicit start reuses one session; two concurrent `withEngine` calls never overlap (peak concurrency 1); idle warm-down stops the process; disabled feature builds no session; stop-while-busy defers until the request finishes |
| `MirageLibraryIndexTests` | one scan caches every row and totals; missing editions orphan in one map write; a second identical scan leaves the map byte-identical; malformed inventory refuses the whole scan; absent/wrong-schema index states; atomic index save under injected interruption |
| `MirageBatchAnalyzerTests` | in-order sequential execution with no overlap; cancel stops before the next book; retry only re-queues failures; planning skips PDFs and already-linked EPUBs |

Census receipt: `./scripts/census.sh --unit-only` exited 0 with **450 passed / 9 skipped / 0 failed** across **459 tests / 671 runs**. Build receipt: `./scripts/run-latest.sh --build-only` exited 0.

## Supersedes / superseded-by

- Supersedes ADR-6 **decision 5** (one analyze = one clean sidecar lifecycle). All other ADR-6 decisions remain in force, including never-auto-run, disable-deletes-nothing, and the one-switch governance.
- Does not supersede ADR-2 (wire/transport), ADR-3 (runtime distribution), ADR-4 (ledger ownership), ADR-5 (identity mapping), or ADR-7 (spoiler cursor).
- Updates the historical lifecycle statement in `docs/integration/MIRAGE-DEEP-DIVE-2026-10-28.md` §2.3 and adds its 2026-10-29 addendum.
