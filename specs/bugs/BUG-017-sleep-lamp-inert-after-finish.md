---
bug_id: BUG-017
status: fixed
severity: medium
scope: ui
title: The bedroom lamp is not inert after the step finishes, so the room relights behind the party transition
---
# BUG-017: The bedroom lamp is not inert after the step finishes

<!-- story: e07s01 -->

**Found by:** e07 post-epic review, `AUDIT`/`request-review` residual (reviewer A should-fix 4,
reviewer B consider 13).

## Problem

`SleepScene.toggle_lamp()` guarded with a double negative:

```gdscript
if fsm.state != STATE_SLEEPING and not credited:
    return false
```

The guard is true only when the scene is **finished and uncredited**. In the normal case
(`FINISHED`, `credited == true`) it is false, so the lamp still toggles after the child has been put
to bed: the room lights up again while the celebration is fading in. In the uncredited case it refuses —
the opposite of the intent in both directions.

## Evidence

`game/scripts/scenes/quarto_sono.gd:64-66` before the fix. Reproduced by tap after finishing:
`state=FINISHED`, second tap → `lamp_on=true`, `background.modulate=WHITE`.

## Root Cause

The condition was written to mean "not sleeping", but the `and not credited` clause turned it into
"finished and unpaid". No test covered the lamp after `_finish()`, so the gate could not see it.

## Fix

`toggle_lamp()` refuses whenever `fsm.state != STATE_SLEEPING`.

## Verification

`game/tests/integration/test_quarto_sono_scene.gd::test_the_lamp_is_inert_once_the_step_is_finished`
(red before the fix: the second tap re-lit the room) — green after.
