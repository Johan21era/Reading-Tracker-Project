# Gate Review Template — Bedrock

Every gate stops here. Copy this template to `docs/plans/bedrock/gates/GATE-<id>.md` and fill it before asking the owner to review.

---

## Gate `<id>` — `<name>`

**Date:**
**Worktree/branch:**
**Commit range:**
**Tag:**
**Status:** READY FOR REVIEW / BLOCKED / FAILED

---

### 1. Scope delivered

- [ ] Item
- [ ] Item
- [ ] Item

### 2. What did not change

State explicitly what was intentionally left alone, so the review cannot over-read the gate.

---

### 3. Tests

| Check | Command | Result |
|---|---|---|
| Targeted pins | `...` | pass/fail |
| Full census | `./scripts/census.sh` | 213/0/9 + new |
| UI smoke | `...` | pass/fail |
| Test isolation | `./scripts/verify-test-isolation.sh` | pass/fail |

Attach or point to the `.xcresult` path.

### 4. Data receipt

- Real-store snapshot checksum:
- Migration counts before/after:
- Parity result:
- Rollback rehearsal:
- Any files renamed/deleted:

### 5. Performance receipt

| Metric | Baseline | This gate | Budget | Verdict |
|---|---:|---:|---:|---|
| Warm launch | | | | |
| Cold launch | | | | |
| Reader open | | | | |
| Save latency | | | | |
| Analytics cached/cold | | | | |
| Memory | | | | |

### 6. Manual evidence

- Screenshots/recording:
- Clean-account/friend-install rehearsal:
- Feature walkthrough:

### 7. Known issues / deltas

Be honest. List anything still broken, deferred, or only partially tested.

### 8. Rollback

```bash
# exact commands
git checkout <tag>
# restore data if applicable
```

### 9. Decision requested

- [ ] **APPROVE** — proceed to the next gate.
- [ ] **APPROVE WITH CHANGES** — list changes; re-run this gate.
- [ ] **STOP** — revert to the previous tag; document why.

Owner notes:

---

## Standing gate rules

1. No red census advances.
2. No destructive migration without a verified snapshot and rollback.
3. No silent feature degradation.
4. Each defect gets Finality + fix-log + named pin.
5. `main` stays untouched until the final approved merge.
