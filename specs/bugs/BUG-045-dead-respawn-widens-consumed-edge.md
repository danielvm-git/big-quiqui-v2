---
bug_id: BUG-045
status: fixed
severity: low
scope: code
title: "TouchDraggable.respawn_at_rest() is dead code and its CONSUMED->REST edge weakens the terminal state"
---
# BUG-045: dead respawn path in TouchDraggable

<!-- story: e08s02 -->

**Found by:** e08 post-epic review, second pass (component diff).

## Evidence

e08s02 added `respawn_at_rest()` and widened `LEGAL_EDGES[CONSUMED]` from `[]` to `[REST]` for a recycle
respawn. `vila.gd` never calls it (the bag is hidden after the earn, ADR-010 1) and no test covers it.
Every food and prop in the cozinha and closet inherited a CONSUMED state that is no longer terminal.

## Fix

Removed the method and restored `CONSUMED: []`.
