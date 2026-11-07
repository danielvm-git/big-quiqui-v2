---
bug_id: BUG-051
status: fixed
severity: low
scope: code
title: casinha.gd restores unowned placements and starves tray when owned count exceeds TRAY_LIMIT
---
# BUG-051: casinha.gd restores unowned placements and starves tray when owned count exceeds TRAY_LIMIT

<!-- story: e09s02 -->

**Found by:** e09 post-epic review.

## Evidence

In `game/scripts/scenes/casinha.gd`:
1. `_spawn_from_save()` iterates over `progress.placed()` and spawns every entry without checking `owns_furniture(id)`. If a tampered save injected unowned placements, they would spawn.
2. `_tray_ids` is capped at `TRAY_LIMIT = 4`. When a player owns >4 items, excess items are not spawned on mount. When items from the tray are placed into the room, `casinha.gd` did not replenish the vacant tray slots from remaining unplaced owned pieces until scene reload.

## Fix

Verify `owns_furniture(id)` before spawning placements in `_spawn_from_save()`, and replenish the tray when slots open up.
