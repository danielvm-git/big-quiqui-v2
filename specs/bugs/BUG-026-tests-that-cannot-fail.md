---
bug_id: BUG-026
status: fixed
severity: low
scope: tests
title: Five assertions that could not fail — the zzz idempotence, the rig's layers, a CanvasModulate, the celebration's HomeButton, and the price duplicated in the scene
---
# BUG-026: tests that could not see the defect they name

<!-- story: e07s01 -->
<!-- story: e07s02 -->

**Found by:** e07 post-epic review (reviewer B should-fix 3 / consider 12/13/14, reviewer A consider 3),
each verified against the tree before the fix.

## Problem

Five gaps, all of the same kind: the test existed, the name claimed a property, and the assertions
could not tell the shipped code from the broken code.

| # | Where | Claim | Why it could not fail |
|---|---|---|---|
| 1 | `test_the_tuck_sets_the_sleepy_face_and_starts_zzz_once` | the second tuck does not restart the burst | it only re-read `expression_id`; a `zzz.restart()` would have passed |
| 2 | `test_the_lamp_dims_the_background_and_never_the_rig` | "never the rig" | asserted `rig.modulate` only; a tint on the rig's layers, or a `CanvasModulate`, was invisible |
| 3 | same | the rig has art | nothing asserted that the character is painted, so the "no tint" claim could pass on an empty rig |
| 4 | e07s02 AC5 "`HomeButton` leaves early without paying twice" | untested | nothing tapped the celebration's Home |
| 5 | `test_celebracao_scene.gd` | the reward is +5/+1 | it read `CelebrationScene.COINS`/`TICKETS` — constants the scene only carried **for the tests**, duplicating `ProgressManager`'s |

## Root Cause

Assertions were written against the same object the code mutates, not against the observable failure
mode. #5 is the classic version: a test that asserts a value against a copy of itself.

## Fix

1. Stop the burst (`zzz.emitting = false`) between the tucks and assert it stays stopped; the second
   tuck goes through the public seam (`tuck()`) so the guard is definitely reached.
2. New test walks the rig's `Pivot` children and asserts every `Sprite2D.modulate` is white.
3. Same test asserts the expression layer has a texture (the painted character), and that no
   `CanvasModulate` exists in the scene.
4. `test_home_leaves_early_and_the_reward_is_already_paid` taps the Home button and asserts one Casa
   request and one payment.
5. `CelebrationScene.COINS`/`TICKETS` are **removed** — the scene does not pay, so it does not name the
   price. The tests read `ProgressManager.CYCLE_COINS_REWARD` / `CYCLE_TICKETS_REWARD`.

## Verification

406 tests / 2128 asserts green. Mutation-tested #1 by inspecting the guard path (`tuck()` returns
`false` on the second call), and #2/#3 fail on a `modulate` mutation of the expression sprite.
