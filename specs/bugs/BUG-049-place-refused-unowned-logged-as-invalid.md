---
bug_id: BUG-049
status: fixed
severity: medium
scope: telemetry
title: place_furniture logs item invalid for valid but unowned furniture IDs instead of not_owned
---
# BUG-049: place_furniture logs item invalid for valid but unowned furniture IDs instead of not_owned

<!-- story: e09s02 -->

**Found by:** e09 post-epic review.

## Evidence

In `game/scripts/autoloads/progress_manager.gd:229-231`:
```gdscript
func place_furniture(id: String, nx: float, ny: float) -> bool:
    if not Ids.is_valid(id) or not owns_furniture(id):
        _emit("furniture.place_refused", {"item": "invalid"})
        return false
```
When `id` is a valid identifier (e.g. `"sofa"`) that is unowned, `place_furniture` logs `{"item": "invalid"}` instead of distinguishing invalid syntax from ownership refusal. In contrast, `buy_furniture` distinguishes `furniture.invalid` from `furniture.already_owned` and `furniture.denied`.

## Fix

Differentiate syntax refusal (`item: "invalid"`) from unowned refusal (`item: id, reason: "not_owned"`).
