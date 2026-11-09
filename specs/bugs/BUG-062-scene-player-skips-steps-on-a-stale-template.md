# BUG-062 — ScenePlayer skips a step when the old template still reports full progress

<!-- story: e12s04 -->
- **Severity:** high · **Priority:** P0 · **Scope:** player · **Status:** fixed
- **Found by:** e13 review round 1, while driving `bathroom_probe` through the player (three steps in one def)

## Symptom

A def with two or more steps ended early. The second step finished in the same tick that it mounted.

## Root cause

`ScenePlayer._tick_template` read `progress()` from the template that was still mounted for the
previous step, and passed that value to the new step. The old template reported 1.0, so the runner
completed the new step at once. e12 had only single-step defs, so nothing showed it.

## Failing test

`test_rubbing_the_real_tool_completes_each_step_and_chains` in `integration/test_bathroom_rub_e2e.gd`
ended at `step_index == 3` without any rub on steps two and three.

## Fix

`_tick_template` returns when `_active_step != runner.step_index`. A template reports progress only
for the step it was mounted for.

## Verification

The bathroom e2e test now needs a real rub on each of the three steps.
