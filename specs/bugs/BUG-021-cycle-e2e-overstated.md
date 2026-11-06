---
bug_id: BUG-021
status: fixed
severity: medium
scope: tests
title: The cycle E2E claimed a door-to-door journey, carried 35 lines of unreachable branches and never ran the oracle
---
# BUG-021: the cycle E2E overstated what it proves

<!-- story: e07s04 -->

**Found by:** e07 post-epic review (reviewer B should-fix 7, reviewer A should-fix 3).

## Problem

`game/tests/integration/test_cycle_e2e.gd` (204 lines) carried three separate problems under one
honest-looking header:

1. **Dead test code.** `_finish_room(step)` had five branches (FEED/BATH/DRESS/PLAY/SLEEP) and was
   called exactly once, with `CareSteps.SLEEP`: ~35 of its 46 lines were unreachable. The file therefore
   *looked* like the door-to-door journey its story title names and was not one.
2. **AC4 not implemented.** e07s04 AC4 requires every scene to pass `GeometryOracle` with its own spec
   **during** the journey. The file's four `GeometryOracle` hits were the aspect constants; there was no
   `audit()` call anywhere.
3. **The "detour mid-cycle" test did not detour out of CELEBRATE.** It requested `closet.tscn` while the
   loop was in `SLEEP`, so `_close_celebrate_for_detour` was a no-op; the only assertions (Casa mounts,
   a door exists) passed with or without e07s03. T-E07-05's end-to-end coverage was thinner than
   `AUDIT-e07-epic.md` claimed.

The *boundary* itself (the four earlier rooms' gestures are proven by their own suites) was defensible
and is kept — dead branches are worse than either honest choice.

## Evidence

- Unreachable branches: only call site was `_finish_room(CareSteps.SLEEP)`.
- Mutation check after the fix: deleting `_close_celebrate_for_detour(path)` from
  `SceneManager.request_scene()` turns the new test red (`CELEBRATE` expected `IDLE`); before the fix the
  same mutation left this file green.

## Fix

- Extracted `game/tests/helpers/cycle_e2e_test_case.gd` (`CycleE2eTestCase`, the contract e07s04 §3 froze
  — BUG-022) holding the loader, the probes, `_walk_step()`, `_assert_step_credited()`,
  `_assert_probes_clean()` and `_audit_layout()`.
- `_audit_layout()` runs on every stage the loader mounts, with `CARE_ROOM_SPEC` for the hub and
  `STEP_ROOM_SPEC` for the rest: AC4 is now implemented, not asserted in prose.
- The four unused branches are gone; the bedroom keeps the touch journey (`_tuck_her_in`).
- `SC-E07-P1-17` now reaches `CELEBRATE` with a no-op loader (so the state stays observable), detours to
  `album.tscn`, and asserts `IDLE`, no extra payment, and a live FEED door on the remounted hub.

## Verification

`test_cycle_e2e.gd`: 21 lines of journey over a 162-line shared fixture; 404/404 with the oracle running
on six stages per canvas. Mutation check above proves the detour test discriminates.
