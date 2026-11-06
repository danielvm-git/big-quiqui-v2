---
bug_id: BUG-029
status: fixed
severity: low
scope: docs
title: specs/README.md advertised five ADRs while nine exist, and did not say capsules are archived
---
# BUG-029: the map of `specs/` stopped at ADR-005

<!-- story: e01s01 -->

**Found by:** e07 post-epic review (second pass, documentation sweep).

## Problem

`specs/README.md` is the entry point an agent reads before `specs/`. It said:

- `specs/adr/` — Architectural Decision Records (`ADR-001` through `ADR-005`). → **nine** ADRs exist
  (ADR-006 vertical slicing, ADR-007 CI/release, ADR-008 edge-anchored composition, ADR-009 the care
  cycle's money/dwell/voice decisions).
- `specs/epics/eNN-slug/` — with no mention that a closed epic moves to `specs/epics/archive/`. An agent
  looking for `e07` in `specs/epics/` finds nothing and concludes the capsule is missing (it is archived,
  and the archive is where the review's spec amendments landed).

## Root Cause

The index is maintained by hand and nothing compares it to the directory listing; every epic since e04
added an ADR and archived a capsule without touching it.

## Fix

Range corrected to `ADR-001`–`ADR-009`, and the archive directory is now listed with the rule
("closed epic capsules, verbatim, moved here when the epic ships").

## Verification

Documentation-only; the count matches `ls specs/adr/` (9 files) and `ls specs/epics/archive/` (7
directories).
