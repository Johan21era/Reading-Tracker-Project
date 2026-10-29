# Repository instructions

## Commit attribution

Never add AI attribution trailers or signatures to commits in this repository.
That includes `Co-Authored-By: Codebuff`, `Generated with Codebuff`, or any
equivalent. The owner had these removed from published history on 2026-10-28
because GitHub credited the account in the contributors graph.

Commit messages end at their own last line.

## CI gate: GitHub Actions is the source of truth

`.github/workflows/census.yml` is the merge gate. Treat a red run as an
unfinished task, not as a note to add to the summary.

**Before calling any code task complete**, run the same checks the workflow
runs, from the repository root:

```bash
./scripts/verify-sentinel-surface.sh          # step 1: surface manifest freshness
python3 scripts/comprehension-bench.py --validate-only  # step 2: docs/INDEX.md links and anchors
./scripts/census.sh --unit-only               # step 3: unit census
```

That is the local mirror of the workflow's three test steps. If a step cannot
run locally (for example a clean checkout is missing the ignored
`.mirage-runtime/` staging directory), say which step and why; do not claim it
passed. The full comprehension gate (timing and one-hop accuracy) is a local
tool: `python3 scripts/comprehension-bench.py --mode all`.

**After an approved push**, watch the workflow to completion and act on it:

```bash
gh run list --workflow=census.yml --limit 5
gh run watch <run-id> --exit-status
gh run view <run-id> --log-failed            # only the failing job output
```

Never use `gh` to cancel, disable, or skip a check to make a run green.

### If CI returns an error

Do not stop, do not hand back a summary that mentions the failure, and do not
treat the error as pre-existing without proof. Loop until it is resolved:

1. Read the failing job log (`gh run view <run-id> --log-failed`).
2. Reproduce the same step locally with the workflow's own command.
3. Fix the cause in source or test code. Never weaken, delete, skip, or
   `XCTSkip` an assertion, never add a type/lint suppression, and never edit the
   workflow to exclude the failing check to get a green result.
4. Re-run the failing step locally, then push the fix and watch the new run.
5. Repeat until the workflow succeeds end to end.

The task is not complete while a run is red. The only permitted pause is a
blocker you cannot resolve from this machine (GitHub outage, missing
credentials, a runner-image change). Report that blocker explicitly with the
run URL and the exact unaddressed failure, and leave the red run visible rather
than pretending it passed.

## Large-task close-out protocol

### Trigger

Run this protocol after an **enormous or massively long task**: one that spans
multiple sessions or phases, touches more than roughly ten files, adds or
removes a subsystem, changes release or packaging behavior, generates gate
receipts or other artifacts, or materially changes architecture or release
state.

A question, a one-file fix, or a small copy/style edit does not trigger it.
Those still follow the normal fix protocol and the commit-attribution rule
above.

### Order (do not reorder)

1. Documentation sweep
2. Junk-artifact audit and safe removal
3. Graph refresh: regular graphify and the full 3D view
4. Owner verification gate: commit and push

### 1. Documentation sweep

Update every document whose claims the work changed. At minimum, consider:

- `README.md` — front-door status, commands, counts, paths
- `docs/INDEX.md` — the one-hop lookup table; move an anchor when its file or
  line changes, and run `python3 scripts/comprehension-bench.py --mode all`
- `docs/01-project-tree.md` — file/folder map and generated artifacts
- `docs/registers/03-fix-log.md` — what changed, why, and proof
- `docs/registers/04-handoff.md` — current state and next actions
- `docs/MILESTONES.md` — only when a capability milestone changed
- relevant `docs/plans/**`, `docs/audits/**`, `docs/design/**`,
  `docs/roadmap/**`, and `docs/integration/**` gate/ADR/evidence records

Quality bar for every edited Markdown file:

- **Technical:** exact paths, commands, versions, hashes, counts, exit
  statuses, before/after sizes, and limitations. No "should work", no
  inherited benchmark, no unverified pass.
- **Neat:** update the canonical document in place; do not append a
  contradictory duplicate. Use the existing headings, tables, and chronology.
  Link to the deeper source instead of copying it. Keep numbers internally
  consistent across documents.
- **Honest:** record skipped, blocked, or failed checks. Never present a
  compile as a test pass, a preview as a release acceptance, or a plan as
  shipped behavior.

Do not hand-edit generated `graphify-out/GRAPH_REPORT.md`; regenerate it.

### 2. Junk-artifact audit and safe removal

Inventory before deleting:

```bash
git status --short --branch
git status --ignored --short
du -sh ./* ./.??* 2>/dev/null | sort -h
find . \( -name '.DS_Store' -o -name '*.xcresult' -o -name '*.profraw' \) -print
```

Classify every candidate as **regenerable**, **required**, or **unknown**.

- Remove only **regenerable** artifacts: `.DS_Store`, `DerivedData/`, `build/`,
  `.xcresult`, `.profraw`, stale test logs, `.playwright-cli/`, temporary
  release staging, and regenerable graphify cache/ephemera.
- Preserve **required** and **unknown** artifacts until the owner confirms:
  source, tests, docs, `.git/`, `graphify-out/graph.json`, `graph.html`,
  `GRAPH_REPORT.md`, `manifest.json`,
  `.graphify_labels.json`, `cost.json`, `.mirage-runtime/`, lockfiles,
  signed release zips/tags, and all user data.
- `graph-3d-full.html` is regenerable and gitignored; rebuild it with the 3D
  generator rather than treating it as source. It is the only 3D view;
  `graph-3d.html` was retired on 2026-10-29.
- Safety rules: use explicit paths; never `rm -rf .`, never `git clean -fdx`,
  never wildcard over the repository root, and never delete anything outside
  the repository. Preview ignored-file cleanup with `git clean -ndX` first.
  Stop and ask on ambiguity.
- Record the exact before/after sizes, paths removed, and artifacts kept in
  `docs/registers/03-fix-log.md`.

### 3. Graph refresh

Refresh the regular graphify output first, then rebuild the full 3D view from
the new graph:

```bash
# Follow the graphify skill/CLI for the refresh; do not invent a cache state.
python3 scripts/build-graph-3d.py
python3 scripts/build-graph-3d.py --check
```

- Verify `graph.html` and `graph-3d-full.html` open from `file://` with WebGL
  (3D), no console errors, and no external resource requests.
- Update graph counts and hashes in `README.md`, `docs/01-project-tree.md`, and
  `docs/registers/03-fix-log.md` when they changed.
- If graphify cannot run, record the blocker and mark the graph stale. Do not
  claim it was refreshed. Never hand-edit `graph.json`, `GRAPH_REPORT.md`, or
  the generated HTML.

### 4. Owner verification gate: commit and push

When the checks are complete, stop and present:

- the changed-file list and `git diff --stat`
- every check run, with exact results and skipped/blocked checks
- artifacts removed, with before/after sizes
- graph counts/hashes and 3D-view status
- the proposed commit message and target branch

Ask the owner to verify the work. Treat **commit approval** and **push
approval** as two separate explicit gates; approval of one is never approval
of the other. Do not commit or push while waiting.

If approved:

- Commit only the reviewed files; never stage unrelated work.
- Follow repository commit-message style, and end the message at its own last
  line. No AI attribution, `Co-Authored-By`, or generated-with trailers.
- Push only after separate push approval, to the approved branch.
- If anything changes after verification, re-run the affected checks and ask
  again before committing or pushing.

### Exit criteria

A large-task close-out is complete only when:

- every affected Markdown file is technically accurate and internally
  consistent;
- the artifact audit is recorded, with regenerable junk removed and required
  or unknown files preserved;
- the graph and the full 3D view are refreshed and checked, or the blocker is
  recorded honestly;
- the owner has separately verified the commit and the push.

For a small task, skip this close-out protocol, but still follow the fix
protocol and the no-attribution rule.
