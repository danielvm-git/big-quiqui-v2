---
bug_id: BUG-024
status: fixed
severity: medium
scope: docs
title: DESIGN.md's night_slumber_tint disagreed with the shipped tint on both value and scope
---
# BUG-024: the design system renamed a colour that changed

<!-- story: e07s01 -->

**Found by:** e07 post-epic review (reviewer B should-fix 9).

## Problem

`DESIGN.md` §2 said:

| Token | Hex | Usage |
|---|---|---|
| `night_slumber_tint` | `#2B2D5C` | Canvas modulate tint during `SLEEP` lamp-off state |

The shipped `SleepScene.NIGHT_TINT` is `Color(0.42, 0.45, 0.72)` = `#6B73B8`, applied to the **background
`TextureRect` only** — deliberately, because a canvas-wide tint darkens the character and T-E07-01 exists
to stop that. So the design document was wrong twice: the value and the scope ("Canvas modulate").

The code's choice is the right one for a pre-reading child; the document was the thing that lied.

## Root Cause

The e07 spec wrote the tint from the design token and then shipped a lighter, background-scoped value
after the oracle/visibility check, without updating the token table. Nothing links `DESIGN.md` to code
constants, so the gate could not see it.

## Fix

The row now carries the shipped hex, says **background-only**, names `SleepScene.NIGHT_TINT`, and states
the rule the value encodes: never the rig, never a `CanvasModulate` (BUG-017's sibling failure mode).

## Verification

`DESIGN.md` is documentation; the behaviour it now describes is pinned by
`test_the_lamp_dims_the_background_and_never_the_rig` and
`test_the_night_tint_never_reaches_a_layer_or_the_canvas` (BUG-026).
