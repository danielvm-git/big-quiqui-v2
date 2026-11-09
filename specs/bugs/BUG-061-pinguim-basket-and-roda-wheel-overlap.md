# BUG-061 — the penguin basket and the roda prize wheel still sit behind the hero

<!-- story: e11s01 -->
- **Severity:** medium · **Priority:** P1 · **Scope:** ui · **Status:** fixed (2026-11-08)
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

## Closure (2026-11-08)

Both symptoms were composition calls, and both were made in the builder, not in the generated
`.tscn` (`build_pinguim_jogo_scene.gd`, `build_roda_scene.gd` — regenerate, never hand-edit).

1. **`pinguim_jogo`** — the closure option the symptom list already allowed: the basket is raised
   above every rig layer (`BASKET_Z = 60`) and the reason is written next to the constant. It is
   the control the child must drag, so it can never be the control she cannot see. The lane and
   the falling items keep their own order behind her.
2. **`roda`** — one wheel, not two. The 440 px wheel is now the spin target (`SpinButton` keeps its
   name, so no test or scene script changed) and the corner duplicate and its decoration node
   (`WheelArt`) are gone. It sits right of her painted rect (`WHEEL_ANCHOR = 0.80, 0.46`), which is
   clear of her at both aspects, and the first-spin badge hangs above it.
3. **The gate got a second fix the bug did not ask for.** `INV-10` read `control.z_index` on the
   leaf only, so the honest fix (raise the parent) still reported "50 % under the hero (z 0 <= 50)".
   Godot composes `z_index` down the chain, so the probe now sums it (`_effective_z`), with a
   regression test proving a control raised by its container is not reported. Without that, the
   next fix would have been a magic number on the leaf instead of the correct parent.
4. `test_occlusion.gd`'s `ALLOWED` map lost the `pinguim_jogo.tscn/Draggable` row; `IceLane` and
   `TickleZone` stay (both are by design). `test_roda_scene.gd` and the full suite stay green.
