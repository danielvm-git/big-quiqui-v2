# BUG-060 — the hero is drawn over the buttons

<!-- story: e11s01 -->
- **Severity:** high · **Priority:** P0 · **Scope:** ui · **Status:** fixed
- **Found by:** the child's own Mac build, after the run reported "stuck on the first screen"

## Symptom

The title screen shows QuiQui in the meadow and **no Play button**. Tapping her makes her
laugh (`rig.tap` in the dev console) and nothing else happens, so the game cannot be started.

## Root cause

`QuiQuiRig` builds its art from `Sprite2D` layers with `z_index` `Z_BODY` 0 … `Z_GLASSES` 50
(ADR-003, so an outfit can never hide the face). A scene-level `Control` defaults to
`z_index = 0`, and **z_index beats tree order**, so every scene Control that overlaps the
character is painted *under* her.

Measured with the rig's painted rect (not its box), on both target aspects:

| Scene | Control | Buried at 16:9 | At 4:3 |
|---|---|---|---|
| `titulo` | `PlayButton` | **95 %** | **75 %** |
| `roda` | `SpinButton` | 50 % | 50 % |
| `album` | `Card_urso` | 100 % | 100 % |
| `pinguim_jogo` | `Draggable` | 50 % | 50 % (BUG-061, open) |
| `jardim` | `TickleZone` | 100 % (intentional — tapping her is the verb) | 100 % |

Every existing assertion asked about a **rect**: `GeometryOracle` proves the hit target is
≥ 120 px and inside the canvas, and the scene tests tap the node *directly*. None of them asked
in what order things are painted, so 604 green tests shipped a game a child could not start.

## Failing test (red first)

`game/tests/integration/test_occlusion.gd::test_no_scene_buries_a_control_under_the_hero`,
which reproduces the old title layout in `test_the_gate_can_fail` and reports
`PlayButton is 95% under the hero (z 0 <= 50)`.

## Fix

- `titulo`: the Play button moved out of the hero's column into the free grass at the
  bottom right (72 px insets, still 168²), `z_index = 100` so no future rig layer can bury it.
- `roda`: the SpinButton moved to the same bottom-right corner with the same `z_index`.
- `album`: a symmetric card row cannot work around a centred hero whose painted width is
  293 px (16:9) / 413 px (4:3); the three cards are a column in the right band, starting below
  the top-right HUD, at 210 × 260.
- `INV-10` (`test_occlusion.gd`) mounts every scene at both aspects and fails when any
  `hit_target` the child must find is ≥ 10 % painted over by the hero.

## Verification

Visual: captured renders at 1920×1080 (`titulo`, `album`) show the button and all three cards.
Automated: `INV-10` green at 1920×1080 and 2048×1536, `GeometryOracle` still green on every
scene, and the gate's own can-fail test proves it would catch a regression.
