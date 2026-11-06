---
bug_id: BUG-022
status: fixed
severity: medium
scope: docs
title: Three of the epic's frozen contracts were never built, and the audit reported PASS
---
# BUG-022: frozen contracts that did not exist

<!-- story: e07s01 -->
<!-- story: e07s02 -->
<!-- story: e07s04 -->

**Found by:** e07 post-epic review (reviewer B should-fix 4).

## Problem

The story specs are the source of truth for the next agent. Three of e07's frozen contracts described
code that was not there, and `AUDIT-e07-epic.md` reported PASS:

| Contract | Claimed | Shipped |
|---|---|---|
| `e07s01.md` §3 | `func tuck() -> bool` on `SleepScene` | only the private `_on_snapped` slot handler |
| `e07s04.md` §3 | `game/tests/helpers/cycle_e2e_test_case.gd`, `class_name CycleE2eTestCase`, with `_walk_step()`, `_assert_step_credited()`, `_assert_probes_clean()` | harness inlined in `test_cycle_e2e.gd`, no helper file |
| `e07s02.md` AC2 | "the `_rewarded_cycle_id` guard is asserted from the scene, not assumed" | the celebration never reads the ledger; no test asserted it |
| `e07s02.md` §3 | `WishBubble` in `celebracao.tscn` | not in the builder |

## Root Cause

The contracts were written in the planning pass and then implemented "in spirit": the behaviour
existed (a tuck happens, the E2E works, the reward is paid once), so no test or gate noticed that the
named seam was missing. `audit-code` read the code, not the spec lines, so it could not catch it either.

## Fix

1. `SleepScene.tuck() -> bool` is the public seam; `_on_snapped()` delegates to it. A second call is a
   no-op and returns `false`. The suite asserts the seam directly, in addition to the touch journey.
2. `game/tests/helpers/cycle_e2e_test_case.gd` (`CycleE2eTestCase`) now exists with exactly the named
   API: the loader fixture, per-scene `FsmProbe`s, `_walk_step()`, `_assert_step_credited()`,
   `_assert_probes_clean()` — plus the per-stage layout audit (BUG-021).
3. The celebration suite asserts the manager's ledger: `_rewarded_cycle_id == cycle_id` after entry,
   and a second `_grant_cycle_reward()` pays nothing.
4. `e07s02.md` §3 is amended rather than implemented: the celebration ships **without** a
   `WishBubble`, because it is the payoff and has nothing to ask for. The amendment is recorded inline
   in the archived spec. (A decorative bubble that never shows a wish would be dead scene weight.)

## Verification

`test_the_tuck_seam_reports_the_first_tuck_only`, `test_a_second_grant_in_the_same_cycle_pays_nothing`,
and the whole `test_cycle_e2e.gd` suite running on the extracted fixture. Suite 404/404.
