# ADR-4 — Data directories, Mirage ledger placement & backup ownership

**Status:** ACCEPTED — 2026-10-18, owner countersign: Johan Rembeci (merge log M-016)
**Date:** 2026-10-18 · **Series:** RT↔Mirage integration ADR-4 (§17 canonical slot: data directories / ledger path / backup ownership)
**Approving owners required:** Johan Rembeci (all six roles, M-005/D2) — countersign recorded in `docs/integration/merge-log.md` on acceptance.

## Problem statement
Where does Mirage's SQLite ledger live, who owns its backups, and how do RT's existing strata (library monolith, state file, Backups/, Sentinel journal, covers, archive/restore) co-exist with a new adjacent database stratum without violating S0-ES-3's **disjoint write-sets**?

## Context (evidence-anchored)
- RT sandbox root (source-verified): `~/Library/Containers/johan.Reading-Tracker/Data/Library/Application Support/ReadTracker/` holding `library.json`, `library-state.json`, `covers/`, `Backups/` (newest-10, LibraryArchiveManager.swift:149-200), `sentinel-journal.jsonl` (SentinelEngine.swift:136-141), `audio-profiles.json`.
- RT has a precedent for a secondary store at a *different* root: weather snapshots live under `Application Support/<bundle-id>/weather_snapshots.sqlite3` (WeatherKitService2.swift:363-377) — two roots already exist in RT; that split was unmotivated drift, not doctrine.
- Mirage ledger path is **caller-specified**: `Ledger.__init__(path)` (ledger.py:47-48); sidecar argv[1] = DB path; the CLI's CWD-relative default `mirage.sqlite3` (cli/__init__.py:17) must never be relied on. Pragmas: WAL, busy_timeout 5000, foreign_keys ON (ledger.py:52-59); close does rollback-if-open + `wal_checkpoint(TRUNCATE)` + optimize (ledger.py:74-88).
- Migrations refuse newer schemas (`PRAGMA user_version`; ledger.py:198-203,230) — `SCHEMA_VERSION = "ledger@0.0.10"` (schema.py:3).
- `Ledger.backup` exists **in-process only** (ledger.py:2235-2248: `conn.backup` + `PRAGMA integrity_check`) and is NOT a NDJSON action (M-009 P-10②).
- Sentinel doctrine: probes/writes only `sentinel-*` artifacts + `SentinelQuarantine/` (S1; SentinelEngine.swift:14-15, 136-141); a probe file lands directly in `ReadTracker/` (:496-498) and DiskSpaceProbe warns below 200 MB free (:556-571).
- S0-ES-3 ownership vector: RT and Mirage have disjoint write-sets; the sole cross-domain write is Mirage's ledger under Mirage's transaction authority.

## Alternatives considered
1. **Ledger at the weather-style `<bundle-id>/` root:** rejected — propagates an unmotivated drift; splits the feature's data across two roots.
2. **Ledger inside `Backups/`:** rejected — the archive manager prunes/pattern-matches there (LibraryArchiveManager.swift:149-226); a volatile bloat source in a rotation directory is a corruption hazard.
3. **Ledger bytes embedded in `library.json` (or library-state):** rejected — breaks S0-ES-3 disjoint write-sets, couples a 29 MB-document human-readable format to a WAL database, breaks single-writer discipline if any non-DataStore writer ever touches it.
4. **User Documents folder (library container):** rejected — RT's user-selected file scope covers the *book files*; engine-owned derived data belongs with engine-owned strata, invisible to the user's file manager.
5. **On-demand elsewhere (External volumes):** rejected — Sentinel DiskSpaceProbe semantics assume one runtime volume; multi-volume ledger breaks fail-fast writability checks.

## Decision
1. **Ledger path (absolute, RT-owned):** `…/Application Support/ReadTracker/mirage/mirage.sqlite3` (+ engine-managed `-wal`/`-shm` sidecars). The `mirage/` subdirectory is **exclusively Mirage-write territory**: RT never writes into it; Mirage (sidecar) never writes outside it. RT creates the directory atomically (with-existence check) before first spawn and verifies it against SC-08-style file-conflict checks.
2. **One ledger, one sidecar:** the sidecar process is opened with that absolute path as its single argv; multi-ledger configurations are out of scope (no config file passes paths around).
3. **RT backups exclude the ledger.** `LibraryArchiveManager` records no mirage/ content; the `.readingarchive` remains Mirage-agnostic. Rationale: backup of a large WAL database mid-session is consistency-hostile from outside the owner process; instead:
4. **Backup ownership = Mirage's own doctrine,** mirrored to the ledger directory: the RT feature exposes **no backup affordance** for the ledger in this milestone (BLOCKED — not a wire action, M-009 P-10②). A future wire `backup` action is a PR-2 amendment territory; today RT records the gap as a known limitation and mirrors engine fail-safe behavior: on orderly quit, the engine's own close (`wal_checkpoint(TRUNCATE)`) leaves a self-consistent on-disk set. RT does *not* fabricate its own ledger backups.
5. **Sentinel co-existence:** Sentinel never touches `mirage/` (no probes, no repairs, no quarantine). The DiskSpaceProbe free-space warning below 200 MB implicitly covers the shared container — no new probe is added in this milestone; ledger-size reporting belongs to the Mirage status row instead.
6. **Restore semantics (`restoreState(from:)` DataStore3.swift:181-192):** RT restores have **no effect** on the ledger. Resulting states are documented explicitly: (a) RT-restore that removes a book would leave the mapping in `mirage/identity-map.json` (ADR-5) — resolution: ADR-5's orphan rule (fail-closed, user-confirmed re-import), NOT automatic re-import; (b) ledger retention is deliberate — analysis is append-only value (I-LED2: navigation never destroys analysis), so restore ≠ ledger deletion.
7. **Deletion policy:** nothing auto-deletes the ledger. Uninstall of engine-side data (remove_book/remove_edition via wire, confirm-gated — service.py:933-966) is user-initiated only; whole-ledger deletion is an explicit user action gated as Class Δ.

## Consequences
- Positive: respects disjoint write-sets; the engine's file-set is positionally obvious for status/debugging; consistency ownership is singular; restores and backups stay fast and schema-stable.
- Negative: archive/restore does not round-trip the ledger (analysis metadata isolated from library backups) — acceptable because projections are recomputable and claims are append-only; disk footprint will grow with large corpora sharing the container's 200 MB warning envelope (mirrored in the Mirage status row; no new probe).
- Neutral: the mirage/ directory first appears only on feature enablement — flag-off installs show zero delta (S0-ES-6(a)).

## Security & privacy impact
- All Mirage content stays inside the app container; no broadened entitlements; the child's write-cone is one directory inside RT's own home container; no ledger content is replicated into RT's visible UI beyond typed read-only queries (ADR-7 territory).

## Rollback implications
- Flag-off leaves the mirage/ directory harmlessly dormant (no reads). Rollback of the feature PRs never deletes the directory (Class Δ decision, user-gated); the ledger remains recoverable-by-hand.

## Tests required (named; implemented in the PR that introduces them)
- `MirageLedgerPathPinsTests` (PR-4): absolute-path spawn (no CWD-relative reliance), directory creation races, flag-off zero-touch (no directory created), engine refuse-on-newer-schema surfaced as `protocol_incompatible` not crash.
- `MirageRestoreInvarianceTests` (PR-5 family): RT restore leaves ledger + identity-map byte-identical; orphan state surfaced in status row only.
