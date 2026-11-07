---
bug_id: BUG-054
status: fixed
severity: low
scope: tests
title: DoorBadge texture swapping untested with real Art child in test_door_badge.gd
---
# BUG-054: DoorBadge texture swapping untested with real Art child in test_door_badge.gd

<!-- story: e09s03 -->

**Found by:** e09 post-epic review.

## Evidence

In `game/tests/unit/test_door_badge.gd:15-20`, `DoorBadge` is instantiated without an `Art` TextureRect child. In `DoorBadge.refresh()`, `if _art == null: return`. As a result, the unit test only tests `badge.current_art_path()`, never testing actual `_art.texture` assignment or cache metadata `door_badge_path`.

## Fix

Add an `Art` TextureRect child to `badge` in `test_door_badge.gd:before_each()` and assert `_art.texture` updates when unlocked.
