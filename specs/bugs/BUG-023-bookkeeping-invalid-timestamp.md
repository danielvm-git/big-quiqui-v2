---
bug_id: BUG-023
status: fixed
severity: medium
scope: docs
title: execution-status recorded a nonexistent instant (16:60) and the release plan still called e04-e07 "planned"
---
# BUG-023: bookkeeping that cannot be parsed and statuses that lie

<!-- story: e07s04 -->

**Found by:** e07 post-epic review (reviewer B should-fix 8; the release-plan half was found while
checking the epic against its own capsule).

## Problem

1. `specs/execution-status.yaml` recorded `e07s02.completed_at: "2026-11-06T16:60:00-03:00"`. Minute 60
   is not a valid ISO-8601 instant: any consumer that parses the field (dashboard, Allure report, an
   agent sorting the rows) either errors or silently mis-sorts.
2. `specs/release-plan.yaml` still listed **e04, e05, e06 and e07** as `status: planned` while
   `execution-status.yaml` said done and every capsule was archived with `status: done`. The
   epic-level source of truth for the ladder contradicted the story-level one for four epics — and
   `scripts/status-counts.sh` looked green only because it reads the other file.

The `epic.yaml:5 status: in_progress` half of the same finding was already fixed by the e07 release
commit (`chore(release): close e07, archive the capsule`), which the reviewer could not see in a
squashed history.

## Root Cause

The story timings were typed by hand into a YAML file with no schema and no validator, and the release
plan's epic statuses are only ever updated by the human closing ritual — nothing checks the two files
against each other.

## Fix

- `16:60:00` → `17:00:00` (the row now sorts between e07s03's 16:50 start and e07s04's 17:10 start).
- `e04`, `e05`, `e06`, `e07` → `status: done` in `release-plan.yaml`.
- Swept every `T…` timestamp in `specs/*.yaml` for the same defect: no other out-of-range minutes.

## Verification

`bash scripts/preflight.sh` (L5 spec schema + L5b/L5c release config) green;
`bash scripts/status-counts.sh` → `7/11 done, no drift`.
