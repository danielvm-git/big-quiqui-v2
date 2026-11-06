---
bug_id: BUG-036
status: fixed
severity: medium
scope: docs
title: execution-status.yaml called e06s01-e06s03 "planned" in development_status while its own stories block said done
---
# BUG-036: the status of record contradicted itself

<!-- story: e06s03 -->

**Found by:** e07 post-epic review, fifth pass (a consistency check over the two
representations `execution-status.yaml` keeps).

## Problem

`specs/execution-status.yaml` holds the same fact twice: a flat
`development_status` map (`e06s01: planned`) and a per-story `stories` block (`e06s01: {status: done,
…}`). For the three e06 stories the two disagreed:

```
development_status: e06s01 planned, e06s02 planned, e06s03 planned
stories:            e06s01 done,    e06s02 done,    e06s03 done    (with timestamps)
```

`scripts/status-counts.sh` reports "no drift" because it reads the per-story rows, so a dashboard or an
agent reading the flat map would believe e06 was never played — three shipped scenes.

## Root Cause

e06's stories were recorded in the `stories` block by the story ritual, and the flat map was only updated
where someone remembered. Nothing compares the two.

## Fix

The three rows now say `done`, matching their own timestamped rows. Verified by a parse-and-compare over
every key the two representations share (0 mismatches; the 16 stories that have not started yet are
absent from `stories` by design — "queued rows are created when their story starts").

## Verification

```
mismatched rows: []
```
`bash scripts/preflight.sh` green (L5 parses and required-key-checks the file),
`bash scripts/status-counts.sh` → `epics 7/11 done, stories 27/43 done, no drift`.
