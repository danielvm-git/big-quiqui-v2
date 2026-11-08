# BUG-061 — the penguin basket and the roda prize wheel still sit behind the hero

<!-- story: e11s01 -->
- **Severity:** medium · **Priority:** P1 · **Scope:** ui · **Status:** open
- **Found by:** `INV-10` occlusion probe during the e11 post-epic review (BUG-060's sweep)

## Symptom

1. **`pinguim_jogo` — `Draggable`** (the basket she must drag) is **50 % behind the hero** at
   both aspects (rect 880..1040 × 762..922 at 16:9, her painted rect 813..1106 × 218..842).
   She sees the top half of the thing she is supposed to drag.
2. **`roda` — the prize wheel** is pinned top-centre and is half-hidden behind her head, while
   the *spin button* is a second wheel in the corner. Two wheels, one of them behind the hero,
   is not a readable screen for a four-year-old.

## Why it is not fixed here

Both are gameplay/composition calls, not draw-order bugs:

- Moving the basket changes where the catch minigame happens (the lane she drops into).
- The roda screen needs one wheel, not two: either the big wheel becomes the spin target or it
  becomes decoration and the corner button stays. That is a design decision for the next pass,
  not something to guess at the end of a bug-fix run.

## What is protected meanwhile

`INV-10` allowlists these two nodes **by name and by this bug id**, so the gate is green and
the debt is visible in one place. Any *new* buried control fails the gate immediately.

## Closure criteria

- `pinguim_jogo`: the basket's whole 160² rect is clear of `get_visual_global_rect()`, or it is
  raised above the rig with a documented reason.
- `roda`: exactly one wheel on screen, and the spin affordance is ≥ 90 % visible.
- Both rows deleted from `ALLOWED` in `game/tests/integration/test_occlusion.gd`.
