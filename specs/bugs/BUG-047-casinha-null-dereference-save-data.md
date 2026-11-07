---
bug_id: BUG-047
status: fixed
severity: high
scope: code
title: Unhandled null dereference on ProgressManager.data in casinha.gd and missing owned_furniture() encapsulation
---
# BUG-047: Unhandled null dereference on ProgressManager.data in casinha.gd and missing owned_furniture() encapsulation

<!-- story: e09s02 -->

**Found by:** e09 post-epic review.

## Evidence

In `game/scripts/scenes/casinha.gd`:
```gdscript
var save: SaveData = progress.get("data") as SaveData
var owned: Array[String] = save.owned_furniture
```
If `progress.data` is null (e.g. during test setups, corrupted load, or before data initialization), `save.owned_furniture` crashes with a null-dereference error. Furthermore, reaching directly into `progress.get("data")` breaks encapsulation.

## Fix

Add `owned_furniture() -> Array[String]` to `ProgressManager` (returning a defensive copy), and update `casinha.gd` to use it with null guards.
