# ADR-8 — Repository strategy: two canonical repositories, one verified vendored copy (canonical §17 seat)

Status: **RATIONALE COUNTERSIGNED 2026-10-18 — the de-facto strategy of the whole ladder, now the owner's recorded decision (closing round: countersign both)**

## Problem statement

§17.1 requires an ADR for repository strategy ("keep repositories separate, use
monorepo, or migrate while preserving history") and §16 forbids interpreting "merge"
as permission to consolidate ("consolidation may eventually be appropriate, but it is
a separate decision…"). Eight PRs executed a de-facto strategy; leaving it an informal
assumption in code review is exactly what §17 bans.

## Context

- The ladder never moved Mirage's files into RT's history except as automated,
  verbatim copies: the engine stays upstream-canonical in its own repository, pinned
  by SHA in every receipt (`81422613610701d81956394d9601bcb61e2938e9`).
- RT carries verified vendored materials: the protocol pins (PR-3), the identity map
  pins (PR-5), and — since PR-8 — a staged runtime bundle whose manifest binds the
  interpreter and engine files by SHA-256.
- No archive, deletion, or history migration was ever executed; the one deletion
  (OPE-001 Class Δ, 38 stub-hash files) was owner-countersigned and its file-LIST is
  archived in-repo (`docs/integration/evidence/`).

## Decision

1. **Keep the two repositories separate and canonical** — Mirage's repo remains the
   source of truth for the engine; RT's repo remains the source of truth for the app.
   Neither is archived, migrated, or rewritten.
2. **RT's copy of Mirage is a VERIFIED VENDOR, not a fork** — every Mirage-derived
   artifact inside RT must be (a) byte-verbatim from the pinned upstream SHA at copy
   time, and (b) re-verifiable against recorded digests (`RUNTIME-MANIFEST.json`
   bindings; staging-script refusal pins). Updates flow by re-pinning at PR time —
   the staging script REFUSES non-pinned generations — until the Titanium Bridge
   gates (ADR-12 §22.19) take over as the standing convergence mechanism.
3. **Rejected alternatives:** monorepo migration (would entangle Mirage's independent
   release/validation cadence with RT's, and violates §16's no-unsafe-coupling rule);
   git submodules (a pointer, still requiring fetch machinery, with weaker verification
   than digests recorded in-repo — the manifest + scripted-refusal discipline is
   strictly stronger at verifying WHAT shipped); history-preserving consolidation
   (unnecessary movement — the integration goal never required it, and §16 requires
   consolidation be a separate decision anyway).
4. **Any future consolidation is its own owner ADR** — monorepo or migration proposals
   must prove a hard dependency from the initial integration (they have not), carry
   their own backup/rollback rehearsal (§20), and may not dictate runtime-architecture
   coupling (§16 verbatim).

## Consequences

- Release provenance is explicit: app releases depend on a pinned, digest-verified
  Mirage generation, recorded in the shipped `RUNTIME-MANIFEST.json`.
- Mirage's own repo keeps its independent CI/ownership cadence; engine-side work
  never requires an RT-side release to be valid.
- The merge-era discipline (master log, Playbook receipts, per-PR census) already
  provides the audit trail this ADR relies on.
- Security/privacy impact: untouched user data ownership (both repos are code
  only); subresource verification is per-file digest, not per-repo trust.
- Rollback implications: re-pinning backwards is the same procedure forwards (stage →
  verify → census); rehearsed (rehearsal log R6).
- Tests required: no new suites — the verification machinery (adherence-suite census
  gates, `MirageBundledRuntimeTests`, staging script) already exists and is green
  (191/0/4).
- Approving owners: J. (RT owner) — countersign requested at the 2026-10-18 closing
  round, alongside ADR-6 ratification and ADR-3/ADR-12 votes.
