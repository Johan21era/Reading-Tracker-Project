# TB-M0 gate plan — manifest + hash-verify in observe mode (DRAFT, awaiting ADR-12 countersign)

Sister to `ADR-12-titanium-bridge-charter.md`. §22's non-execution charter applies:
**this plan does not execute until the owner countersigns ADR-12 and signs the TB-M0
gate.** Nothing in tonight's session built or ran any TB instrument.

## Goal

Prove the convergence machinery's *measurement* layer without ever swapping anything:
a declared subset manifest over RT's vendored Mirage materials, a verify instrument
that computes digests and compares against the manifest, and a 7-day observation ledger.
Observe mode means: verify, record, notify — **swap code paths are not built yet.**

## Scope (what TB-M0 will materially add per §22.19.1)

| Instrument | Seeds that already exist (PR-3/8, verified) | TB-M0 adds |
|---|---|---|
| Subset manifest | `RUNTIME-MANIFEST.json` (interpreter + sidecar bindings + tree digest), staging script with refusal pins | Whole-subset declaration (every file that constitutes RT's Mirage copy), canonical manifest under version control |
| Hash-verify | `MirageRuntimeLocator` SHA-256 spot-checks (fail-closed, census-pinned) | Full-manifest verify instrument (script-side, daily); in-app spot-checks stay as-is |
| Drift sensor | Per-PR censuses; engine re-pinned suite receipts | Daily auto-run of the verify instrument against the live vendored copy; records to the observation ledger on drift |
| Observation ledger | Rehearsal log + merge log discipline | `docs/integration/tib/observe-ledger.md` template: date · subset digest · verify result · drift rows · operator note |
| Swap machinery | none by design | none in M0 (observe only) |

## Exit evidence (per §22.19.1, verbatim bar)

1. **7 days of observation ledger entries** — consecutive, dated, one per day minimum.
2. **0 false-green verifies** — the instrument must never pass unverifiable material.
   The tamper drill (below) demonstrates the red side is real; the quiet week
   demonstrates the green side is honest.
3. **Tamper drill receipt** — archived: flip one byte in `bin/python3.12` of a
   sacrificial staged copy → verify must refuse (`TB-VERIFY-HASH` shape), quarantine
   row in the ledger, NO swap, live runtime untouched; then restore and re-verify green.

## Operating rules while TB-M0 runs

- No swap, no promotion, no generation mutation — the vendored copy changes only by an
  authorized PR + owner push, exactly as today.
- A red verify row (other than the archived tamper drill) freezes further TB work until
  root-caused in the merge log next-slot discipline.
- The ledger lives in-repo (docs/integration/tib/); every row is cheap, verifiable, and
  append-only.

## What TB-M0 will NOT decide

Key custody, signing ceremony, ref plumbing, PPC differential baselines, or the
shadow-ledger migration path — all later gates (TB-M2…TB-M5), each with its own plan.
