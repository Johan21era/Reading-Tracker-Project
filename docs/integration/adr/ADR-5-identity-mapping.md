# ADR-5 — Identity-mapping contract: RT Book ↔ Mirage book/edition

**Status:** ACCEPTED — 2026-10-18, owner countersign: Johan Rembeci (merge log M-016)
**Date:** 2026-10-18 · **Series:** RT↔Mirage integration ADR-5 (§17 canonical slot: identity-mapping contract)
**Approving owners required:** Johan Rembeci (all six roles, M-005/D2) — countersign recorded in `docs/integration/merge-log.md` on acceptance.

## Problem statement
RT's `Book` (UUID-keyed, file-backed) and Mirage's books/editions (content-fingerprint-keyed) are independent identities. The integration needs an explicit, auditable mapping that never guesses — no title inference, no fuzzy-match merges — and stays stable across RT restores, engine re-imports, and file edits.

## Context (evidence-anchored)
- RT identity: `Book.id: UUID` (Book2.swift:35); the file reference is `fileURL` + security-scoped `bookmarkData` (:38, :51); duplicate check inside RT is fileURL equality (DataStore3.swift:199-207).
- Mirage identity: `book_id`/`edition_id` derive from the SHA-256 of the EPUB bytes (`edition_<digest[:16]>`, `book_<digest[:16]>`; service.py:97-101); fingerprint (`edition_fingerprint`) is recorded with the edition; identical re-import is a documented no-op (`reused: true`, :111-115); same edition_id with different bytes is REFUSED as a collision (:103-110); degraded imports persist and analysis refuses them (:151-154).
- Fingerprint-derived IDs mean an edited file = a different edition. Stale mappings therefore leave `position_mappings` (adapters, schema m0001-family table) dangling silently (touchpoint-inventory row 15).
- RT persistence posture (PR-5 requirement, S16-ES-1): "mapping in its own stratum; RT persistence schema untouched" — the `Book` model and `library.json` schema must NOT change for this feature; the tolerant decoder (Book2.swift:212-236) errs toward NOT inventing fields.
- Spoiler doctrine: I-SP3 — a future identity merge must be undetectable in earlier projections; auto-merging identities in RT would be worse: inventing a merge on the host is forbidden outright (mission §3: evidence-gated merges belong to the engine, D-010 overlay, and are out of RT's milestone scope).
- Write-set discipline (S0-ES-3): the mapping is RT-feature-owned data — it must not live in Mirage's ledger (it is host-side truth) and must not live in RT's library monolith (schema discipline).

## Alternatives considered
1. **Optional fields on `Book` (`mirageBookID`, `mirageEditionID`):** rejected for this milestone — PR-5's evidence gate says RT persistence schema untouched; adding Codable fields is a schema migration of the 29 MB monolith with all its decode/baseline risk; revisitable only via a new ADR (migration policy, ADR-9 territory).
2. **Mirage-side storage (engine table):** rejected — the ledger is Mirage-write territory exclusively (ADR-4); host-course mapping is host truth; also the ledger schema is pinned (`ledger@0.0.10`) and adding host tables violates Mirage's ownership.
3. **Title/author fuzzy mapping at import:** rejected outright — playbook scope D3(4): "identity mapping … explicit, evidence-classed, no title-guessing"; violates I-SP3 doctrine posture and creates silent cross-edition leaks.
4. **CoreData/UserDefaults:** rejected — non-versioned, non-atomic-enough, incompatible with the strata ownership pattern.

## Decision
1. **Own stratum file:** `…/ReadTracker/mirage/identity-map.json`, owned and written ONLY by the Mirage feature module (never by the engine, never by DataStore/PersistenceWriter, never Sentinel). Versioned: `{"schema": "mirage-identity-map@1", "entries": [...]}`. Crash-atomic writes: temp-file + atomic rename within the same directory (RT-side pattern mirror of engine atomicity).
2. **Entry contract:** `{rtBookID: UUID, mirageBookID: String, mirageEditionID: String, sourceFingerprint: String /* sha256 hex of the EPUB bytes at import time */, sourceResumeHint: String? /* optional last adapter-resolved unit id, diagnostic only */, createdAt, updatedAt, status: "active" | "orphaned" }`. One `active` entry per `rtBookID` at a time; historical superseded entries may be retained with status `"orphaned"` + reason for audit (append-only spirit).
3. **Creation rule:** an entry is created ONLY as the result of a confirmed, user-initiated one-book import flow (PR-5) whose EPUB bytes were hash-verified by the engine's idempotent import path (`reused:true` or fresh `imported` receipt read from the wire result — no local-only hashing shortcut).
4. **Drift rule (fail-closed):** when the RT feature needs the mapping, the current file's byte-hash is recomputed by RT (RT does the hashing; the engine refuses mismatches anyway) and compared to `sourceFingerprint`. Mismatch ⇒ the request is refused on the RT side with the typed state `identityDrift`; the entry becomes `orphaned` (reason: `source-changed`); the user is offered the explicit re-import flow (which creates a NEW edition and mapping; the old ledger edition remains Mirage's asset — never mutated by RT).
5. **Missing-file / removed-edition rule:** engine `not_found` (status 404) on the mapped edition ⇒ entry → `orphaned` (reason: `edition-gone`); no auto-cleanup, no auto-reimport.
6. **Degraded-import rule:** a `"degraded_import"` receipt (service.py:151-154) is REJECTED as mapping input — the entry is not created and the UI states the source file needs repair (engine refuses analysis for it anyway).
7. **No title/author-based lookups anywhere in the feature.** If RT has no mapping, the Mirage surface shows `notImported` state (explicit user action, e.g. "Analyze this book in Mirage" button) — never an inferred suggestion that pretends authority.
8. **Read path of the mapping is fail-safe:** unknown schema version or malformed entry ⇒ the feature degrades to `disabled` state (status: mapping-unreadable) rather than guessing (fail-closed doctrine mirrors Mirage's own).
9. **State-vocabulary coupling is NOT this ADR's job:** RT read/reading/unread ⇄ Mirage read/reading@N/unread transduction belongs to the cursor contract sub-document (S10-ES-3) gating ADR-7 — drafted next, before any spoiler-sensitive surface (read-only status surfaces only until then).

## Consequences
- Positive: zero library-schema movement; strata ownership clean (RT-feature file in mirage/ directory under ADR-4); drift detection is byte-precise; collisions impossible by engine contract.
- Negative: an extra file stratum to archive-awareness-discipline (explicitly NOT in `.readingarchive` — ADR-4 §4); mapping loss (file deleted by hand) means re-verification via import flow — harmless because engine import is idempotent (`reused:true`).
- Neutral: mapping entries never carry reader position as truth (that is the cursor contract + engine `position_mappings`), so no synchronization with page turns is needed here.

## Security & privacy impact
- The file contains only engine-assigned IDs and fingerprints — no titles, no user content. Within the app container; no entitlement changes.

## Rollback implications
- Feature rollback leaves `identity-map.json` orphaned-but-inert; re-enabling re-validates entries against live file hashes (drift rule self-heals conservatively).

## Tests required (named; implemented in the PR that introduces them)
- `MirageIdentityMapContractTests` (PR-5): schema pin; one-active-per-book invariant; temp+rename atomicity under interrupt injection.
- `MirageIdentityDriftTests` (PR-5): byte-change ⇒ `identityDrift` refusal + entry orphaned; deleted file ⇒ `edition-gone` orphaning; degraded_import never mapped; restoreState invariance (ledger + map untouched).
