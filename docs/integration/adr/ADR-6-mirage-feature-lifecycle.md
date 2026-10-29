# ADR-6 — Mirage as an optional RT feature: lifecycle governance (canonical §17 seat)

Status: **RATIFIED as written by the owner 2026-10-18, closing round (PR-7 implementation; PR-8 further implements decision 1's availability worlds)**

> Numbering note: the interim record `ADR-6a-mirage-import-independence-newde5.md` (NEW-DE-5
> discharge) briefly occupied this number before the §17 slot list was resolved; this file is
> the canonical ADR-6 seat: the feature-lifecycle decision.

## Problem statement

PR-7's gate (§16 / S16-ES-1) requires "enable/disable semantics, unavailable-state UX,
accessibility, clean shutdown; disable-deletes-nothing verified." The feature is user-facing
(surface = the book-detail "Analyze with Mirage" ingress + status section); without a
recorded lifecycle decision the settings semantics would be ad-hoc and uncountable.

## Decision

1. **One plain switch** — `mirage.enabled`, surfaced as Settings ▸ Mirage (SettingsRootView
   gains one tab; native Toggle/labels = accessibility by construction). Default **ON**:
   real availability is governed separately by the engine gate (dev checkout today via
   `MIRAGE_REAL_ENGINE_DIR`; bundled runtime after ADR-3/PR-8), and the unavailable-state
   copy explains itself honestly when the engine is absent. Turning the feature OFF hides
   the working ingress; the discoverable card remains.
2. **OFF means NO engine, NO spawn** — both the status runner and the analyze flow gate on
   the switch (defense in depth: UI replaces the start affordance AND the flow entries
   guard the flag). Pinned by `MirageFeatureLifecycleTests`.
3. **Disable deletes nothing** — the identity stratum, the ledgers, and Mirage's stored
   analyses stay byte-identical across any enable/disable cycle; no deletion path exists in
   the settings namespace, and none is planned under the playbook's ownership rules. Copy
   states this verbatim ("Nothing was deleted … remain exactly as they are").
4. **Never auto-run holds unamended** — the settings session introduces no automatic engine
   work; every engine contact remains an explicit gesture (S10-ES-1 doctrine from PR-5, kept).
5. **One analyze = one clean sidecar lifecycle (unchanged)** — the PR-7 settings session
   does not alter the lifecycle doctrine; the "persistent settings session" idea the ladder
   once contemplated is NOT taken here (the machinery boundary M-024 — one spawn per
   process — is honored rather than fought; see M-027 root-cause record).

   > **Superseded 2026-10-29 by ADR-13.** M-027 found no machinery boundary on the
   > production path, so the warm app-scoped session is now implemented. This decision's
   > safety intent is preserved by serialized requests, explicit gestures, idle/background
   > teardown, and the explicit retry gate. The other ADR-6 decisions remain in force.
6. **The unavailable-state experience** — three honest worlds, each with plain language:
   (a) engine not set up (no dev checkout; future: bundle) `— "The Mirage engine isn't set up
   on this Mac yet…"`; (b) feature disabled — the sheet reports and starts nothing and the
   copy names Settings ▸ Mirage; (c) engine reached but refused/errored — the PR-5 typed
   outcome copy. None of them hides state behind jargon.

## Alternatives considered

- **Default OFF** — cleaner opt-in posture, but on a developer machine with the dev gate
  configured it adds a settings step before any first analysis; the feature cannot act
  without explicit gestures either way. Owner may flip this at ratification (one-line change).
- **Kill running sessions when toggled off** — rejected: a cancel-after-commit stale claim
  risk; sessions are per-gesture and self-tearing, so there is nothing to kill except a live
  analyze, whose cancel semantics (S10-ES-1(e)) already describe themselves honestly.
- **Bulk removal affordance ("delete all Mirage data")** — rejected for this PR: destructive
  ops need owner countersign (Class Δ) with their own design; disable is a UI gate, not a
  data operation.

## Consequences

- Settings ▸ Mirage appears right after Sentinel; the reader ingress stays discoverable.
- The unavailable copy becomes the ONLY honest bridge until PR-8 bundles the engine.
- A future "delete all Mirage data" surface, if wanted, is a NEW countersigned decision
  (this ADR neither grants nor forbids it; it records that disable negative-deletes).

## Tests

- `MirageFeatureLifecycleTests` (PR-7): default-ON pin; disabled ⇒ runner never fires and
  no engine status is produced; stratum bytes byte-identical across an enable/disable
  cycle + side-artifact preserved; honest copy pins (names the settings surface; never
  claims deletion; contains no removal verbs).

## Approving owners

- Owner (Johan) — ratification requested at the PR-7/session close (decisions 2–5 and the
  unavailable-copy posture were countersigned across PR-5/PR-6 sessions in substance).

## Supersedes / superseded-by

- None (ADR-6a is the separate NEW-DE-5 discharge record under an interim number).
