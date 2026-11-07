---
bug_id: BUG-053
status: fixed
severity: low
scope: code
title: Functions in build_mercado_scene.gd, casinha.gd, and placement_oracle.gd exceed the 20-line bar
---
# BUG-053: Functions in build_mercado_scene.gd, casinha.gd, and placement_oracle.gd exceed the 20-line bar

<!-- story: e09s01 -->

**Found by:** e09 post-epic review.

## Evidence

In `CONVENTIONS.md` §5, all new or changed functions must not exceed 20 non-comment lines.
1. `game/tools/build_mercado_scene.gd:129` `_price_badge()` has 24 non-comment lines.
2. `game/scripts/scenes/casinha.gd:117` `_spawn()` has 21 non-comment lines.
3. `game/tests/helpers/placement_oracle.gd:16` `audit_normalized()` has 21 non-comment lines.

## Fix

Extract helper functions in `build_mercado_scene.gd`, `casinha.gd`, and `placement_oracle.gd` to keep all functions <= 20 lines. Regenerate `game/scenes/mercado.tscn`.
