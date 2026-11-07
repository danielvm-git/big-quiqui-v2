---
bug_id: BUG-046
status: fixed
severity: high
scope: telemetry
title: party.locked diary event is never emitted on mount when the party is locked
---
# BUG-046: party.locked diary event is never emitted on mount when the party is locked

<!-- story: e09s03 -->

**Found by:** e09 post-epic review.

## Evidence

In `game/scripts/scenes/festa.gd`, `fsm` is initialized to `STATE_LOCKED`. In `_ready()`, `refresh_unlock()` is called:
```gdscript
var want: String = STATE_DANCING if party_unlocked() else STATE_LOCKED
if fsm.state == want or not fsm.transition_to(want):
    return
_apply_state()
```
When mounting with `< 5` pieces placed, `want == STATE_LOCKED`, matching `fsm.state`. It returns immediately and `_apply_state()` is never called on mount. As a result, `_log("party.locked", ...)` is never emitted, directly violating `e09s03.md` AC 7 and scenario `SC-E09-P0-01`.

## Fix

Ensure `_apply_state()` runs on initial setup or initialize the FSM properly so that `party.locked` is emitted exactly once on mount when under the unlock threshold.
