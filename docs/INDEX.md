# Index — where to look first

> The map, not the manual. Use this page when you already know the question.
> Every entry links to the file that owns the answer — and, where a single line
> settles it, to that exact line. `scripts/comprehension-bench.py` re-validates
> every link and anchor and fails when a niche question stops resolving in one
> hop.

## Read in this order

1. `README.md` — what the app is, verified health, open work, commands.
2. `docs/INDEX.md` — this page; skip straight to the row you need.
3. `docs/01-project-tree.md` — where every file lives.
4. `docs/registers/04-handoff.md` — the current state and the next actions.

## The app and its shell

| If you need… | Read first | Then |
|---|---|---|
| Bundle identifier, product name, deployment target | `AsterismaV1.0.xcodeproj/project.pbxproj#L465` | `AsterismaV1.0-Info.plist` |
| App shell: declares the root content view (SwiftUI) | `AsterismaV1.0/App/NewContentView.swift#L1` | `AsterismaV1.0/App/AsterismaApp.swift` |
| App identity: data root directory name, bundle identifier constants | `AsterismaV1.0/Core/AppIdentity.swift#L12` | `AsterismaV1.0/Core/RuntimeEnvironment.swift` |
| Feature folders and the full file map | `docs/01-project-tree.md` | `AsterismaV1.0/Features/` |

## Defaults and feature switches

| If you need… | Read first | Then |
|---|---|---|
| Mirage toggle: switches the feature off, defaults key | `AsterismaV1.0/Features/Mirage/MirageSettings.swift#L21` | `docs/integration/adr/ADR-6-mirage-feature-lifecycle.md` |
| Sentinel defaults keys: kill switch, repairs, interval minutes | `AsterismaV1.0/Core/SentinelEngine.swift#L140-L143` | `AsterismaV1.0/Core/Sentinel/SentinelConfiguration.swift` |
| Sentinel notifications: request defaults key, launch card | `AsterismaV1.0/Core/Sentinel/SentinelNotification.swift#L75` | `docs/plans/sentinel/gates/SG7.md` |

## Health: Sentinel and recovery

| If you need… | Read first | Then |
|---|---|---|
| Sentinel probe IDs and contracts: manifest tables, required surfaces need a registered owner, catalog | `AsterismaV1.0/Core/Sentinel/SentinelProbesSurface.swift#L45` | `AsterismaV1.0/Core/Sentinel/SentinelProbeCatalog.swift`, `docs/plans/sentinel/gates/README.md` |
| Surface manifest freshness: the script that fails CI when the manifest is stale | `AGENTS.md#L21` | `scripts/verify-sentinel-surface.sh`, `scripts/sentinel-surface.py` |
| Sentinel catalog size and the probe receipt | `docs/registers/04-handoff.md#L25` | `docs/plans/sentinel/gates/README.md` |
| Library recovery: Phase 5 rebuild result, carries skipped rows | `AsterismaV1.0/Core/LibraryRecovery/LibraryLogicalRebuilder.swift#L11` | `docs/plans/library-recovery/G6.md` |
| Recovery gate: enum defines the operational mode that suspends writes | `AsterismaV1.0/Core/LibraryRecovery/LibraryRecoveryGate.swift#L13` | `docs/plans/library-recovery/G6.md` |

## Data

| If you need… | Read first | Then |
|---|---|---|
| SQLite store: journal mode, GRDB connection that backs the live library, schema, migrations | `AsterismaV1.0/Core/Storage/LibraryDatabase.swift#L34-L45` | `AsterismaV1.0/Core/Storage/LibrarySnapshot.swift` |
| Library snapshot: table counts struct, key paths | `AsterismaV1.0/Core/Storage/LibrarySnapshot.swift#L48` | `AsterismaV1.0/Core/Storage/LibraryDatabase.swift` |

## Build, test, release

| If you need… | Read first | Then |
|---|---|---|
| Build and test commands: runs the unit-only census, surface gate | `AGENTS.md#L23` | `scripts/census.sh`, `README.md` §7 |
| Release receipts: git tag, package SHA-256, last unit census tests/runs record | `docs/registers/04-handoff.md#L89` | `README.md#L7` |
| CI receipts: last remote census run id, green Sentinel tranche | `docs/registers/04-handoff.md#L83` | `.github/workflows/census.yml` |
| Clean test session: Erase Library & Data… menu action | `README.md#L301` | `docs/registers/04-handoff.md` |
| CI workflow: GitHub Actions census runs on the runner image, Xcode version, test steps | `.github/workflows/census.yml#L10-L13` | `AGENTS.md` |

## Knowledge graph

| If you need… | Read first | Then |
|---|---|---|
| 3D graph view: full nodes and edges, 2D community HTML, generator | `README.md#L294` | `scripts/build-graph-3d.py`, `scripts/graph3d-template.html` |
| 3D graph generator: verify outputs without writing, staleness flag | `scripts/build-graph-3d.py#L232` | `README.md` §6 |
| Retired artifacts: the community 3D graph file removed 2026-10-29 | `AGENTS.md#L134` | `README.md#L294` |

## Tests

| If you need… | Read first | Then |
|---|---|---|
| Reader appearance tests: covers settings and contrast | `AsterismaV1.0Tests/Reader/ReaderAppearanceTests.swift#L1` | `docs/design/READER-POLISH-2026-10-25.md` |

## How this page is checked

```bash
python3 scripts/comprehension-bench.py --validate-only   # bank + every anchor
python3 scripts/comprehension-bench.py --mode all        # gate: one-hop accuracy, time, files
```

The bench is a fresh, context-free process each run. It compares a grep-first
reader with an index-first reader on 30 niche questions, then compares a full
246-file scan with the four entry documents above. A stale anchor, a broken
path, or a question that falls back to grep fails the gate. Fix the index, not
the threshold.
