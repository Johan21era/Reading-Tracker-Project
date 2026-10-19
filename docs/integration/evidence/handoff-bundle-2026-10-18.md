# §15.4 Operational handoff bundle — RT ⇄ Mirage integration (2026-10-18)

Path-anchored answers for the release/operations owner. Every row states its
verification status; operator-verified rows say so.

## Identify the running Mirage process

- Supervisor PID file: `<Application Support>/ReadTracker/mirage/guard.pid` — written
  atomically by `MirageSidecarSupervisor` (MirageSidecarSupervisor.swift:235); removed on
  clean shutdown (:239). **Verified in unit suites** (foreign-pid guard release test).
- Process census command (operator): `PGID=$(ps -axo pid,command | grep mirage_sidecar |
  grep -v grep | awk '{print $1}')` — real census rows: **operator-verify on a live dev
  session** (tonight's receipts are the smoke exits, not a long-lived census).

## Check version / protocol compatibility

- Handshake fields pinned from the engine banner: `api_version` (`1.0.0`) +
  `schema_version` (`ledger@0.0.10`) + `db` + `status:"ready"` (serve.py, pinned wire
  contract; proven in every real-engine proof). RT refuses on incompatible protocol
  (typed `protocolIncompatible` — supervisor pin) — **unit-verified**.
- Packaged-runtime version triple now lives in `RUNTIME-MANIFEST.json`
  (`engine_checkout_sha`, `interpreter_sha256`) — bundled channel verifies bindings at
  cold start; manifest lines surface in Settings ▸ Mirage's availability row.

## Locate the approved ledger (and what may touch it)

- Live ledger: `<Application Support>/ReadTracker/mirage/mirage.sqlite3` (+ WAL/SHM
  siblings while a sidecar lives). **Mirage-write territory** (ADR-4): ONLY the Mirage
  process writes it; RT's imports/sessions/status are `import_epub`/read-only inventory
  calls.
- One sidecar lifecycle per gesture; the supervisor's own quiesce/teardown owns the
  ledger quiesce (SIGTERM grace then escalation — lifecycle pins).

## Backups (both systems, independently — §18 row)

- Mirage approved path (verified from source, NOT assumption): `Ledger.backup(dst)` —
  SQLite online backup API + `PRAGMA integrity_check` (`ledger.py:2235-2252`,
  §14.4/§46 R3). Gap: no wire/CLI surface — trigger stays engine-side (operator run or
  embedded call) until a countersigned amendment. Owner of the gap: J.
- NEVER copy the live db files (WAL-consistency is not a shell copy's problem to solve).
- RT strata: DataStore3's own save/rotation + Sentinel cadence — outside this bundle's
  scope; not assumed to cover the ledger (restated from §15-ES-3).

## Feature on/off and failure states (operator-facing)

- Disable = Settings ▸ Mirage switch — deletes nothing, spawns nothing (verified).
- Not-available state = honest copy in the sheet + Settings row bundled/dev/none names.
- Failed initialization: `.mapUnreadable` fail-closed (contained state, no writes) —
  test-anchored. Crash mid-exchange: typed EOF, next gesture gets a fresh epoch.
- Local restore from a backup: engine-side operation; RT has no ledger-restore surface
  (by design — ownership discipline).

## The packaged runtime (PR-8)

- Staged layout + manifest: `RUNTIME-MANIFEST.json` bindings (interpreter sha256,
  sidecar sha256, src tree digest — staging-side truth).
- Swap rehearsal procedure: rehearsal log R6 (atomic replacement; smoke; census).
- Clean-machine gate: `scripts/verify-clean-machine.sh` — the standing artifact for
  "packaging works on a clean machine"; its CI publication = the owner Actions toggle.
