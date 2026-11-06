---
bug_id: BUG-025
status: fixed
severity: low
scope: docs
title: An orphaned doc comment above ProgressManager.equip described _apply, so the file documented the wrong function
---
# BUG-025: orphaned doc comment in ProgressManager

<!-- story: e02s02 -->

**Found by:** e07 post-epic review (`audit-code` read of the reward path the epic changed).

## Problem

`game/scripts/autoloads/progress_manager.gd` carried two doc blocks stacked above `equip()`:

```gdscript
## One logical change, one `progress_changed`: the mutators above are for the
## HUD's incremental updates, a full cycle is a single event.
## Records what she is wearing. One id per slot, ...
func equip(slot: String, id: String) -> bool:
```

The first block describes `_apply()` (the money path), not `equip()`. When e07 moved the save into
`_apply`, the comment that explains it stayed behind and silently attached to the wrong function.

## Root Cause

An edit inserted the new `_apply` body below the existing block instead of moving it; GDScript has no
documentation lint, so nothing objected.

## Fix

The "one logical change, one `progress_changed`" block moved onto `_apply()`, where it is true, and
extended to name the two HUD mutators it refers to.

## Verification

`gdlint` + `gdformat --check` green, `--fast` Preflight green. Comment-only change; the money path is
pinned by `test_progress_manager.gd` (`write_count`, fresh `load_or_default()` after a cycle).
