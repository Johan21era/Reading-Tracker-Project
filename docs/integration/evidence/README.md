# §19 Evidence bundle — assembly manifest (2026-10-18, ladder complete)

Per §19: the bundle ships the completed integration's evidence, user data excluded
(synthetic fixtures only; the one deletion artifact is a file-LIST, not user content).

| §19 item | In-repo evidence | Location |
|---|---|---|
| Architecture ADRs | ADR-2 transport · ADR-3 packaging · ADR-4 stratum · ADR-5 identity · ADR-6 feature lifecycle · ADR-6a NEW-DE-5 discharge · ADR-7 spoiler cursor (+Annex A/S10-ES-3) · ADR-8 repository strategy · ADR-12 TiB charter (draft) | `docs/integration/adr/` |
| Protocol schema | Mirage protocol extraction (28-action register, wire shapes, framing) | `docs/integration/phase1/mirage-protocol-extraction.md` |
| Source-revision inventory | Engine pinned SHA `81422613610701d81956394d9601bcb61e2938e9` + RT ladder commits `0842b2b`→`0aa4ed8` | merge log M-014…M-028 + `RUNTIME-MANIFEST.json` (staged bundle) |
| Baseline build/test logs | Per-PR census receipts; standing default census **191/0/4**; receipts referenced in every M-row; full xctest logs = CI artifacts once Actions toggled | merge-log rows; `.github/workflows/census.yml` |
| Integration test report | Real-engine identity proof (single lifecycle, 5 proofs incl. detail-free status); boot-diagnostic evidence ladder (4-rung, clean) | `Reading TrackerTests/MirageIdentityRealEngineImportTests.swift`, `MirageZBootDiagnosticTests.swift`, rehearsal log R2/R4 |
| Performance report | Spawn/banner latency measured (≈1 s cold boot; ms exchanges); dedicated budget report = §20-next delta | rehearsal log + PR-8 stage receipts |
| Security/privacy review | No-network posture; entitlement confinement; stratum-write confinement; OPE-001 Class-Δ deletion with archived list; tampering-resistant manifest | ADR-3/4/7; `docs/integration/evidence/OPE-001-deleted-stub-list-2026-10-18.txt` |
| Packaging validation | Staged-bundle receipts + clean-machine 3-stage gate + CI workflow | `scripts/*.sh`, `scripts/bundle_smoke.py`, rehearsal log R6 |
| Known-issue list | NEW-DE-12 stub-cover regeneration; backup wire-exposure gap (named owner); single-lifecycle doctrine (softened only by evidence, doctrine unchanged); app-embed pending owner toggle | merge log M-014…M-028 + §21 addendum register |
| Rollback rehearsal record | R1 in-vivo census on the pre-PR-6 tree; R5 backup-restore re-pin; R6 staging/swap procedure | `docs/integration/rehearsals/rehearsal-log-2026-10-18.md` |
| Final acceptance checklist | Filled with receipts + honest deltas | `docs/integration/final-acceptance-2026-10-18.md` |

User-data policy: verified — the bundle contains NO user library content; fixtures are
synthetic; the OPE-001 artifact is the list of DELETED stub file names (no user covers).
