# ADR-12 — Titanium Bridge (TiB) charter: continuous convergence across the guarded boundary

Status: **ADOPTED — countersigned by the owner 2026-10-18, closing round ("Countersign both — the TiB era opens at TB-M0"). TB-M0 observe-mode execution is therefore OPEN; each milestone's EXIT still signs against its evidence (gates are the only brake — decision 6 stands, with opening ≠ exit)**

> Numbering note: ADR-12 is the seat the playbook reserves for the TiB era (§22 header:
> "ESCALATED-DESIGN pending ADR-12"). Numbers ADR-8…ADR-11 remain unclaimed for the
> regular §17 register.

## Problem statement

The 8-PR ladder is complete (`0842b2b` → `9a78947` → `0aa4ed8` → `40b1513`); the merge
itself ends when the owner signs the §18 checklist. What remains is the lifetime problem:
Mirage is now a vendored subsystem inside RT, pinned by hand (SHAs, scripts, staging).
Every future change to Mirage risks drifting from RT's copy — the exact class of decay
the merge playbook exists to prevent. §22 specifies the standing answer (the Titanium
Bridge: a convergence subsystem with formal SLOs, evidence-carrying promotions, and
"gates are the only brake"). An ADR must adopt — or reject — that charter, because the
playbook cannot self-execute.

## Decision (proposed)

1. **Adopt the TiB charter as specified in §22** — the one-sentence promise as the
   subsystem's contract: a line merged into Mirage at 4:00 PM is the same line, with the
   same behavior, the same performance envelope, and the same optimizations, running
   inside RT's copy of Mirage by 4:01 PM — zero human steps in the development ring, a
   signed evidence-carrying promotion in the release ring. The formal SLO numbers
   (convergence latency targets, the four sub-guarantees, the H0–H11 hop pipeline, the
   torture list, retention depth) are **§22.0–§22.19 as written**; this ADR does not
   amend them — it is the adoption record.
2. **Two rings, one bridge** — dev ring: continuous, zero-human-step convergence behind
   a feature flag with manual-confirm pointer swap (TB-M1); release ring: signed,
   gate-gated promotion, "gates are the only brake" (TB-M5). No ring ever writes the
   other's artifacts.
3. **Generation model is inviolable** — old or new generation serves; never a third
   thing (torture #3). Swap is whole-directory atomic replacement only (the ADR-3/PR-8
   mechanism, promoted to standing policy).
4. **The subset manifest seeds from tonight's bundle** — the PR-8 staged layout is the
   first declared subset: `bin/python3.12`, `examples/mirage_sidecar.py`,
   `src/miragev10 (tree digest)`, with `RUNTIME-MANIFEST.json` carrying the bindings.
   The locator's SHA-256 spot-check ladder is the first in-app verifier. The TB-M0 work
   extends both to the full manifest + drift sensor (see the gate-plan sibling doc).
5. **Owner custody** — promotion signing keys are owner-held; the machine side never
   holds private keys; refs converge from the allowlist (default: canonical Mirage
   main) only. Refusal on unsigned or unverified material is fail-closed and ledgered
   (tampered object → `TB-VERIFY-HASH`, quarantine, no swap).
6. **Non-execution continues until separately countersigned gates** — each milestone
   (TB-M0…TB-M5) opens only by an owner gate-signature against its exit evidence; the
   §21.0 non-execution charter applies to every §22 subsection until then.

## Consequences

- The engine remains upstream-canonical: Mirage's own repo stays the source of truth;
  RT carries a manifested, verified copy. Neither repo is migrated or archived (§20
  item 12's consolidation decision rides its own record).
- The census stands as the permanent RT-side gate; Mirage-side suite re-pins stay in
  the rehearsal ladder until the bridge owns them.
- Refusal shapes (`TB-VERIFY-HASH`, unsigned-promotion refusal) enter the S9 fault
  registry family when TB-M0 implements them.
- If countersignature is declined: the merge still stands (the ladder is complete and
  PR-8's pinned-staging discipline remains the interim convergence mechanism), and the
  §22 addendum keeps its ESCALATED-DESIGN status unchanged.
