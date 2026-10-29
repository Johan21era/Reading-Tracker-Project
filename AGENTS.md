# Repository instructions

## Commit attribution

Never add AI attribution trailers or signatures to commits in this repository.
That includes `Co-Authored-By: Codebuff`, `Generated with Codebuff`, or any
equivalent. The owner had these removed from published history on 2026-10-28
because GitHub credited the account in the contributors graph.

Commit messages end at their own last line.

## Markdown truth audit (mandatory)

A Markdown file is a set of claims about this repository. An unsupported claim
is a defect, the same as a failing test. From this rule forward, **every `.md`
file you create or edit must be audited with the rubric below before you call
the task done**, and audited again at session close even if the last edit was
earlier.

### The one rule

If `something.md` says it, you must be able to prove it from bytes: a path that
exists, a line that contains the claim, a command and its exit status, a digest,
a commit, a run ID, or a tag. "Should", "probably", "appears to", "as
expected", and inherited benchmarks are not evidence. If you cannot prove a
sentence, do one of exactly three things:

1. delete it;
2. replace it with the receipt that proves it;
3. mark it `SKIPPED` in the audit ledger with a plain-English reason a
   non-engineer can understand (no jargon, no acronyms, no blame).

A skipped check is not a pass. A compile is not a test. A plan is not shipped
behaviour.

### When

- After the last `.md` edit of a task, before `git add`.
- At session close, over every `.md` touched in the session **plus** every
  `.md` that cites a fact the session changed.
- Before a release or close-out: every tracked `.md`. If that sweep is not
  possible, audit the touched/intersecting files and list the rest as
  `SKIPPED` with one plain-English reason and a re-audit owner.

### Evidence standard (byte level)

- **Paths** — must exist now. `path:line` must be inside the file, and that
  line must contain the claim's subject. Record the line's text.
- **Numbers** — counts, sizes, timings, LOC: cite the command and its exact
  output, or `file:line` plus the file's SHA-256 at audit time. Re-derive code
  and test counts; never copy an old number.
- **Hashes** — 64 lowercase hex, with the producing command and a resolving
  receipt. A deleted artifact can be cited only as a recorded receipt, marked
  `SKIPPED` for re-derivation.
- **Commits, runs, tags** — `git rev-parse`, `gh run view <id>`, `git tag
  --list`; exact IDs, never paraphrased.
- **Commands** — the exact command and its exit status. Timing claims also
  record the machine, repetition count, statistic (median), and raw runs.
- **File identity** — each audited file records its SHA-256 and line count in
  `docs/registers/05-doc-audit.md`. Any later edit invalidates that audit;
  re-audit, do not assume.

### Weighted rubric (100 points)

Score each dimension as the percentage of that file's claims in the dimension
that meet the evidence standard. Dimensions with no claims are `N/A` and their
weight is redistributed proportionally over the scored dimensions.

| ID | Dimension | Weight | What scores 100 |
|---|---|---:|---|
| A1 | Numerical claims | 14 | Every count/size/time has a command or `file:line` + digest; no inherited figures |
| A2 | Paths and anchors | 12 | Every backticked path exists; every `path:line` is in bounds and contains the claim |
| A3 | Commands and exit status | 8 | Every quoted command was run; pass/fail and exit code recorded |
| A4 | Receipts | 6 | Commits, runs, tags, hashes exact and resolvable |
| B1 | Internal consistency | 7 | The file never contradicts itself, including tense and counts |
| B2 | Cross-document consistency | 12 | Shared facts match every other document that states them |
| B3 | State and chronology | 6 | No "pending/open" leftover after it shipped; dated changes carry dates |
| C1 | Skipped/failed disclosure | 8 | Every unrun check is `SKIPPED` with a plain-English reason |
| C2 | Verification honesty | 6 | Compiles, previews, and plans are never presented as tests or releases |
| C3 | Limitations and risks | 6 | Known gaps and residual risks are stated where the claim lives |
| D1 | Canonical placement | 4 | One canonical copy; no contradictory duplicate |
| D2 | One-hop retrieval | 3 | `docs/INDEX.md` points at the right file/line and resolves |
| D3 | Link and table hygiene | 3 | No dead links, broken tables, or orphan headings |
| E1 | Freshness | 3 | Claims reflect the latest receipt; historical text is labelled historical |
| E2 | Generated artifacts | 2 | Generated files carry their generator command and are not hand-edited |

`score = Σ(weight × dimension%) / Σ(scored weights)`. **PASS = 90 or more with
zero critical failures. REVIEW = 70–89. FAIL = below 70 or any critical.**

**Critical failures** (cap the file at 59 regardless of other scores): a false
claim that a check passed; a path or anchor that does not resolve; a wrong
hash/run/tag; a contradiction on a release fact (version, count, tag, package);
a skipped check that is not disclosed.

### Output (required, append-only)

Append one row per file to `docs/registers/05-doc-audit.md`:

| Date | File (+ SHA-256, lines) | A1…E2 scores | Weighted | Verdict | Evidence / SKIPPED reason |
|---|---|---|---|---|---|

Rules for the ledger: append, never rewrite history (a corrected audit is a new
row that names the row it supersedes); `PROVEN` means every claim meets the
standard; `SKIPPED` must carry the plain-English blocker; `FAIL` must name the
false sentence and the receipt that contradicts it. The ledger itself is a
Markdown file and is audited by the same rubric.

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

- Verify `graph-3d-full.html` opens from `file://` with WebGL, no console
  errors, and no external resource requests. Verify `graph.html` separately: it
  loads its documented vis-network renderer from unpkg, so it needs network
  access.
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
