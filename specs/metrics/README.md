# Delivery metrics — how this ledger is produced, and what is missing

<!-- story: e05s03 -->
`specs/metrics/cycle-times.yaml` is written **only** by
`bash scripts/record-cycle-time.sh append`, which derives:

- `effort_hours` — additive, idle-stripped, from the commit stream (git-hours model)
- `lead_time_minutes` — calendar latency, first commit → merge (never summed)

## Gap: e01–e05 have no rows

The script attributes a commit to a story through a `Story: <id>` **trailer**. This project
squash-merges one commit per epic, and the squash bodies carried prose ("Stories: e03s01, e03s02…")
rather than the trailer. Result: `partition` finds no attributable commit and the script refuses
(`has no attributable commits in range … (check the 'Story: …' trailer)`).

**Not back-filled.** Reconstructing rows for e01–e05 would mean either:

- hand-writing the numbers — exactly the fabricated, self-reported measurement the script replaced, or
- deriving them from wall-clock timestamps that include overnight and UAT gaps — the
  calendar-latency-inflated figure the script removed.

Both would put fiction in a ledger built to prevent fiction. The rows start when the data exists.

## Fix forward (adopted in CONVENTIONS §2)

The epic squash commit / PR body must carry one trailer per story:

```text
Story: e06s01
Story: e06s02
Story: e06s03
```

`release-branch` verifies it before merging, and `record-cycle-time.sh` then has data from e06 on.
