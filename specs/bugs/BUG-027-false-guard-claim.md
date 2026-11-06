---
bug_id: BUG-027
status: fixed
severity: low
scope: docs
title: CelebrationScene's header claimed ProgressManager refuses a second payment for the same cycle; it does not, and reset() replays a paid cycle
---
# BUG-027: a documented guard that lives somewhere else

<!-- story: e07s02 -->

**Found by:** e07 post-epic review (reviewer A consider 1).

## Problem

`CelebrationScene`'s header said:

> Coming back after the celebration is free play: the loop is already IDLE and
> `ProgressManager` refuses a second payment for the same cycle.

`ProgressManager.complete_cycle()` has no per-cycle guard at all. The only ledger is
`CareLoopManager._rewarded_cycle_id`, in memory, next to `cycle_id`. A probe over the real autoloads shows
`CareLoopManager.reset()` + replay paying **10 coins / 2 cycles**, because `reset()` zeroes both fields.
That path is test-only (`TestReset`), but the file told a future agent the economy was guarded at the
wrong layer, which is how a "harmless" new caller of `complete_cycle` gets written.

## Root Cause

The comment was written from the design intent ("the manager owns money") rather than the code, and no
review step compares prose to symbols.

## Fix

- `celebracao.gd` now names the real guard, its lifetime (per session) and what it does not cover.
- `CareLoopManager.reset()` is documented as the **TestReset entry point**, with the replay consequence
  spelled out.
- The ownership model, the deliberate absence of a persisted per-cycle guard (it would need a `SaveData`
  schema change) and the reason are recorded in
  [ADR-009](../adr/ADR-009-care-cycle-money-dwell-and-voice-gaps.md).

## Verification

Comment-only change; the single-owner behaviour stays pinned by
`test_a_second_grant_in_the_same_cycle_pays_nothing` (BUG-022) and
`test_celebrate_pays_exactly_once_per_cycle`. Preflight green.
