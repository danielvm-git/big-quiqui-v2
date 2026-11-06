# Delivery metrics — how this ledger is produced, and what is missing

<!-- story: e06s03 -->
`specs/metrics/cycle-times.yaml` is written **only** by
`bash scripts/record-cycle-time.sh append`, which derives:

- `effort_hours` — additive, idle-stripped, from the commit stream (git-hours model)
- `lead_time_minutes` — calendar latency, first commit → merge (never summed)

## Gap: e01–e06 have no rows, and it is structural

`partition()` in `scripts/lib/git-hours.sh` reads **one trailer value per commit**:

```bash
git log --no-merges --pretty=format:"…%(trailers:key=Story,valueonly,separator=%x2C)"
```

Three `Story:` trailers on one commit collapse into the single bucket
`"e06s01,e06s02,e06s03"`. This project **squash-merges exactly one commit per epic**, so:

| What we want | What the workflow produces | Result |
|---|---|---|
| one row per story | one commit for four stories | no per-story attribution possible |
| one row per epic | one commit, if it carries `Story: e06` | works |

The first attempt (e05) failed for a second, smaller reason too: the squash body carried prose
(`Stories: e03s01, e03s02…`) instead of a trailer, and GitHub squashed from the *commit message* rather
than the PR body, so the trailers I put in the PR body never reached the commit.

**Not back-filled.** Reconstructing e01–e05 by hand, or from wall-clock timestamps that include overnight
and UAT gaps, would put exactly the fabricated numbers into the ledger that this script was written to
replace.

## Adopted convention (CONVENTIONS §2)

**Verified mechanism (e07, second failure):** GitHub's squash takes the **branch commit messages**, not
the PR body. With seven commits on the branch, `Story: e07` — present in the PR body — never reached the
squash commit. The reliable form is to pass it at merge time:

```bash
gh pr merge <n> --squash --delete-branch \
  --subject "feat(eNN): <epic title>" \
  --body "Story: eNN"
```

One **epic-level** trailer on the single squash commit:

```text
Story: e07
```

`record-cycle-time.sh append --story e07 --bcps <epic bcps>` then produces one honest row: effort and lead
time for the epic, derived from git. Per-story effort is *unavailable by construction* in a
squash-per-epic workflow and is reported as such rather than estimated.

If per-story metrics are ever wanted, the workflow must change (story-sized commits on `main`, or a
per-story tag), not the ledger.
