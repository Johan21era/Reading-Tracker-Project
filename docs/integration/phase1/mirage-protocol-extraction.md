# Evidence artifact — MirageV1.0 normative docs + wire protocol extraction (Phase 1/2)

Source: `/Users/johanrembeci/Desktop/MirageV1.0` — HEAD `81422613610701d81956394d9601bcb61e2938e9`, tag `v1.0.0`, clean tree.
Read in full: docs/embedding.md · docs/literary_intelligence_mission_statement.md · examples/mirage_sidecar.py · serve.py · webserve.py · api/service.py (dispatcher + signatures) · cli/__init__.py · domain/enums.py · domain/contracts.py (key sections) · spoilers/eligibility.py · storage/ledger.py (infra sections) · storage/schema.py · docs/problems.md/fixlog.md/testing.md/product_era_plan.md/completion_plan.md/p17-record.md · ADR-0001/0002 · protocol-pinning tests.

## Version boundaries (embedding.md:16-20 + source)
- Ledger schema: `ledger@0.0.10` (storage/schema.py:3; 16 migrations m0001_initial … m0016_series_registry at schema.py:622-637)
- Mirage application API: `1.0.0` (api/service.py:27 `MIRAGE_API_VERSION`; pinned by tests/test_public_api.py:120)
- Package `__version__ = "1.0.0"` (__init__.py:3) — CONFLICT NOTE: docs/embedding.md:20 says package `0.0.1`, contracts.py:278 `contract_version: "0.0.1"`. Host must pin on `version` action (`api_version` wire key), not file manifests.

## Wire protocol (P-1 … P-10, PROVEN unless marked)
- **P-1 framing:** one JSON object per line, stdin→stdout; `serve()` prints health banner FIRST line (serve.py:45,48), then reads until EOF; every response `flush=True`; returns 0 after EOF; engine closed in `finally` (serve.py:61-63).
- **P-2 request grammar:** `{"action": str, "payload": {...}, "id"?: any}` — `id` echoed verbatim when present (serve.py:38-40). **NO protocol-version field exists anywhere on the wire** — pinning is operational via the `version` action only. (Do not invent one without an ADR.)
- **P-3 response envelope:** success `{"ok": true, "result": ...}` (serve.py:32). Error `{"ok": false, "error": {type, code, status, message}}` (error_envelope serve.py:15-24). Codes: MirageError=`mirage_error`/400, ValidationError=`validation_error`/422, NotFoundError=`not_found`/404 (api/errors.py). Unknown command → ValidationError("unknown command: X", 404) (service.py:997) — envelope carries status 404 with code `validation_error` (asymmetry, pinned test_webserve.py:148). Non-dict/bad-JSON → ValueError envelope (serve.py:28-29,56-57). Sidecar usage error: `{"code":"usage","status":2}`, exit 2 (examples/mirage_sidecar.py:29-33).
- **P-4 action set (28 dispatch branches, service.py:823-997):** `health, version, import|import_epub (aliases), analyze, projection, search, checkpoint, verify_checkpoint, reconstruct, verify_deltas, export_graph, cited_claims, neighborhood, edge_detail, history, books_list, edition_remove, book_remove, search_eligible, series_create, series_list, series_candidates, series_attach, series_detach, series_read_state, series_breakdown, series_remove, translate`.
  - Payload gates (verbatim): `'path' is required for import_epub` (:829); analyze needs book_id+edition_id (:840); projection needs edition_id+cursor_unit (:850); search requires `edition_id`,`query`,`cursor_unit_index` — **fail-closed without cursor** (:858-861; embedding.md:62-63; tests/test_public_api.py:104-114).
  - `analyze` default `pipeline_version="heuristic-1"` (:845); responses embed `ledger_version` from `ledger.current_ledger_version()` (:857).
  - Removals (`edition_remove`, `book_remove`, `series_remove`) are **confirm-gated**: `confirm` boolean required (service.py:934-938, 984-987; cli/__init__.py:94-104).
- **P-5 version pinning:** `version()` → `api_version "1.0.0"`; `health()` → `status "ready"` (tests/test_public_api.py:52,120). Full key set of health/version/projection payloads: partially proven — **do not assume extra keys**.
- **P-6 lifecycle:** host owns process lifecycle; sidecar = `python mirage_sidecar.py DB` (single argv, examples/mirage_sidecar.py:28-36); in-process: `with MirageService.open(db_path) as mirage:` (embedding.md:25-32). Close semantics: open transaction → rollback (I-JOB1), `PRAGMA wal_checkpoint(TRUNCATE)` + `PRAGMA optimize` (ledger.py:74-88). **`backup` exists in-process only (Ledger.backup → conn.backup + integrity_check, ledger.py:2235-2248) — NOT a wire action (BLOCKED for NDJSON use).**
- **P-7 durability handed to host:** spoiler predicate fail-closed (mission L1742; eligibility.py:93-169 — future-evidence gate :136-137, token-leak gate :139-150, dependency closure :163-169); import idempotency: same bytes → `reused: true` no-op (service.py:111-115), same edition_id + different bytes → collision ValidationError (:103-110); stable unit ids `u_<sha24>` from `edition_id|normalized_text|chapter|order_index` (ingestion/epub.py:43-52); schema forward-compat refusal via `PRAGMA user_version` (ledger.py:198-203,230); checksummed delta chain (`verify_deltas` on wire).
- **P-8 parity rule:** sidecar, `--serve`, and web `POST /command` all route through the same `MirageService.run_command` — "the sidecar and `mirage --serve` can never drift apart (audit D11)" (mirage_sidecar.py:13-14; webserve.py:7-10).
- **P-9 failure surface:** structured JSON error envelope with non-zero exit — never a traceback (cli/__init__.py:57-72).
- **P-10 UNSUPPORTED/BLOCKED:** ① no protocol/envelope version field; ② backup/restore not wire actions; ③ exact read-state cursor canonicalization string not located (CacheKey join `book|edition|cursor|mode|v|settings|platform` proven at contracts.py:247-261; ADR-0002 ordering note `book|edition|index|unit_id`); ④ full payload key sets of health/version/projection not fully proven; ⑤ DisclosureMode.STRICT_CURRENT_UNIT/FULL_BOOK_GATED literal strings not quoted (membership proven); ⑥ pyproject entry points not extracted; ⑦ two orphaned mission-quote fragments (§2.2 L270+, §3.1 L302+).

## Doctrine (mission statement — binding on RT as host)
- Ten non-negotiable truths (L29-38): spoiler visibility = f(cursor + provenance), models never decide (L29); ledger is truth, graph is projection (L31); navigation changes visibility never destroys analysis (L32); incremental always — no full-book rerun on a page turn (L33); uncertainty first-class (L34); local-first, one MacBook, measured resources (L35); readers are capability adapters with manual fallback (L36); engine/UI separated, contracts > frameworks (L37); correctness > density (L38).
- Formal invariants (L1811-1820): I-SP1 (no transitive future evidence at cursor), I-SP2 (per-cursor cache isolation), I-SP3 (future identity merge invisible), I-LED1 (every displayed claim ≥1 resolvable evidence), I-LED2 (append-only revisions), I-INC1 (page turn invokes no full-book analysis), I-HIS1/I-HIS2 (history/hash stability), I-JOB1 (crashed job leaves committed data intact), I-PRIV1 (local-only mode = zero network calls, proven by test).
- Local-first (L359-369): external services must be explicit documented options, never invisible requirements.
- Engine/UI separation (L378-383): UI must not own spoiler policy or filter unrestricted graph data.
- ADR-0001: deterministic/classical-only; "no external analysis-provider network calls" (L20). ADR-0002: Rust core demoted to experiment (CursorKey canonicalization mismatch, L5-12) — **the Python API is the only sanctioned surface; do not integrate the Rust crate.**

## Storage facts
- SQLite WAL; pragmas on open: busy_timeout 5000, foreign_keys ON, synchronous NORMAL, cache_size -8192, temp MEMORY, mmap 32MiB (ledger.py:52-59).
- Migrations refuse newer DBs; `PRAGMA user_version = len(MIGRATIONS)` after migrate (ledger.py:203,230).
- Backup API: `Ledger.backup(destination)` → `conn.backup` + `PRAGMA integrity_check` (ledger.py:2235-2248) — in-process only.
- Thread affinity: sqlite connection bound to creating thread (webserve.py:85-90 documents the single-dispatch-thread constraint); two live processes on one DB file risk `busy_timeout` contention — RT must own exactly one sidecar per ledger.

## Import identity (service.py:84-174)
- `digest = sha256(file bytes)`; `edition_id = edition_<digest[:16]>`; `book_id = book_<digest[:16]>`; `edition_fingerprint = digest` (:97-101).
- Re-import of identical bytes → `reused: true` (no-op); same edition_id + different content → refused (:103-115). Degraded imports persisted (`import_status", "degraded_import") and analysis refuses them (:151-154).
- Text lives inside the ledger (`content_units` + `content_unit_texts` + FTS5 triggers; schema.py:329-336, 365-403); original file referenced via `source_assets.local_path_ref` (schema.py:64, service.py:122-132) — **removing/moving the RT-side EPUB strands the reference; RT must treat source paths as durable or re-import.**

## Reading state & cursor (host-supplied truth)
- Reading state = string trio `unread | reading | read` enforced by CHECK (schema.py:595; validated ledger.py:1846-1847). CLI surface `reading@cursor` maps to `reading` + cursor_unit.
- `Cursor` dataclass: book_id, edition_id, unit_index, unit_id?, platform_version="skeleton-0.0.1" (domain/enums.py:52-64) with `canonical()` `"{book_id}|{edition_id}|{unit_index}|{unit_id or ''}"`.
- **RT page numbers are NOT unit indexes** — RT `currentPage` (PDF 0-based PDFKit index; EPUB estimate `wordCount/250`, BookImporter.swift:200-201) must be translated through `readers/adapters.py` (AdapterPositionResolver, persisted in `position_mappings`) — never passed raw (spoiler boundary is unit_index-based).
- DisclosureMode: `read_so_far` (default, embedding.md:582 §6.1), `strict_current_unit`, `full_book_gated` (explicit labeled request; positional gate waived but status/dependency/leak gates still apply; cache-isolated by mode — eligibility.py:132-135).

## Protocol-pinning tests (server-of-record for the wire contract)
- tests/test_public_api.py:117-126 — version == "1.0.0"; unknown command → validation_error. :104-114 — search fail-closed. :53-101 — lifecycle health→import(2 units)→analyze→reused→collision-refused.
- tests/test_webserve.py — 127.0.0.1-only bind asserted; engine paths open ZERO sockets (socket.socket patched to AssertionError across import→analyze→projection→search→citations→export→checkpoint→verify→corrections) (:175-213) — I-PRIV1 at code level.
- tests/test_surface_parity.py:15-32 — projection/citations/neighborhood agree at a cursor; future evidence invisible at cursor 3, visible at 5 (:35-48).
- tests/test_multibook.py:306-332 — NDJSON product surface covers import→list→read→remove through run_command.
