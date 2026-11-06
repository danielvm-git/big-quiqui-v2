---
bug_id: BUG-013
status: fixed
severity: high
scope: ui
title: On 4:3, QuiQui is painted at 42% of the viewport height while the oracle proves the box
---

# BUG-013: the hero-scale requirement is verified on the `Control` box, not on the character

<!-- story: e02s03 -->
**Opened by:** `request-review` round 1/5 — both reviewers, independently
(`specs/verifications/REVIEW-A-…md` must-fix 1, `specs/verifications/REVIEW-B-…md` must-fix 1, 2)

## Problem
**Expected:** `DESIGN.md:31-32` — on the primary device (iPad 4:3) QuiQui occupies **55–65 %** of the
viewport height, feet on the 78 % line.
**Actual:** the feet line and centring are right, and the *box* measures 0.574 on every canvas, but the
**painted character** is 0.418 of the height at `2048×1536` and 0.446 at `1920×1440` (0.457 / 0.487 on
`titulo`). The child sees a character roughly the same size relative to the screen as before the fix.

| Canvas | box height ratio (what `GeometryOracle` reads) | painted height ratio (what the child sees) |
|---|---|---|
| 1920×1080 | 0.574 | 0.574 |
| 1920×1440 (4:3 `expand`) | 0.574 | **0.446** |
| 2048×1536 (iPad) | 0.574 | **0.418** |

## Root cause (verified in the code, not only in the review)
`game/tools/build_casa_scene.gd:24-25,78-79` pins the rig box with a **fixed pixel width**
(`RIG_WIDTH = 640`) and a **ratio height** (`RIG_HEIGHT_RATIO = 620/1080`). `QuiQuiRig._update_layout`
(`game/scripts/components/quiqui_rig.gd:280`) fits the 1024×1024 art with
`factor = minf(box.x / art.x, box.y / art.y)`, so on a taller canvas the **width is the binding side**
and the extra box height above her head is empty. `GeometryOracle._audit_rig_height`
(`game/tests/helpers/geometry_oracle.gd:167-177`) reads `control.get_global_rect()`, so it measures the
empty box and passes. `QuiQuiRig.get_visual_global_rect()` — the observable that measures the art —
already exists (`quiqui_rig.gd:199`) and is unused by the oracle.

This is the exact failure mode the e01/e02 cycle was chartered to remove (*"a green gate standing in
for an unproven requirement"*, `FIX-e01-e02:76`): the assertion cannot fail for the requirement.

Consequences the reviewers found from the same cause:
- The rig box is 185–240 px taller than the art on 4:3, so **taps on blank background above QuiQui's
  head trigger the affection reaction** (`quiqui_rig.gd:66`, `casa.gd:110-115`) — a hidden hit area on
  a children's app (REVIEW-B should-fix 3).

## Resolution (TDD: red first, then green)

RED state, reproduced independently by review round 1 (their measured table: 0.418 / 0.446 on 4:3) and
by round 3's probe. To rerun it, restore **both** pre-fix conditions: `_update_layout`'s width-limited
`minf(box.x/art.x, box.y/art.y)` **and** a `get_visual_global_rect()` that returns the 1024x1024 frame
(pre-`cd97e88`). Reverting only the box-width fit in `_refit()` is not enough and prints 0.574 — the width fit shapes
the box and the tap surface, while the height-driven factor below delivers the requirement.

1. `QuiQuiRig._refit()` — the builder's ratio anchors own the **height**; the width now follows
   the art aspect (`offset_left/right = ±size.y * art_aspect / 2`), only for the centred `0.5/0.5`
   anchor column every builder pins. `_refit()` runs from `_ready`, `_apply_expression` and
   `NOTIFICATION_RESIZED`, so the box is art-shaped on every layout pass and `_update_layout`'s
   height-driven fit (`factor = box.y / seen.y`) keeps the painted height equal to the box height.
2. `GeometryOracle` measures `get_visual_global_rect()`, keeps the box check as a second assertion (`box is N of the canvas but the character is only M` when dead space > 3 %), and
   now audits the **scene root** rect and optional `required_groups` — the two ways a scene could still
   opt out of its own layout gate.
3. **Round 2** found the same defect one level down: `get_visual_global_rect()` returned the
   1024×1024 texture **frame**, and the shipped art carries an ~8 % transparent margin (opaque rect
   `x=306 y=75 412×868`), so the child still saw ~0.49. Now `QuiQuiRig.opaque_rect()` caches
   `Image.get_used_rect()` per texture; the layout scales on the opaque height, shifts the frame so the
   opaque **bottom** sits on the pivot and the opaque centre on the box centre, and
   `get_visual_global_rect()` returns the union of the visible sprites' opaque rects. Each base pose is
   fitted on its own opaque rect, so `carente` (wider, shorter) keeps the same seen height instead of
   pulsing between poses.
4. Measured after with `game/tools/measure_hero_scale.gd` (opaque, at rest — the tool pins the pose):
   **0.574 on all nine rows** (`casa`, `titulo`, and `cozinha` at 16:9, 1920×1440 and 2048×1536), feet 0.780 / 0.926 / 0.780.
   A raw `_process` run adds ±2 % of idle breathing (0.561–0.587), so any figure that differs from
   0.574 came from a breathing phase, not from the layout.
5. **Round 3** found the visible consequence of the size change: the wish bubble was pinned with an
   absolute `-812 px` offset tuned for a 620 px character, so on 4:3 her correct size put her head
   *through* the bubble (213–269 px of overlap, 26–30 % of her height) exactly when `casa.gd` shows the
   sad face. The bubble is now anchored to the head line (`feet - rig height`) and
   `test_casa_scene.test_the_bubble_never_covers_the_character_on_either_aspect` pins it on both
   aspects.
6. **The oracle now fails closed**: a node in the `rig` group that is not a `Control`, or a rig that
   cannot report painted geometry (missing art, a renamed layer), is a *finding*, not a silent fall
   back to the box. `opaque_rect()` returns an empty rect and logs `rig.opaque_unreadable` when an
   image cannot be read, so an unmeasurable texture cannot pass as a frame. `required_groups` moved into `CARE_ROOM_SPEC` / `TITLE_SPEC`, so a scene that
   forgets `add_to_group` can no longer opt out.

Deferred reviewer items closed in the same commits: `Ids.PATTERN` and `WishBubble.ART_PATH_PATTERN` are
`\A…\z` with trailing-newline tests (`test_a_newline_suffixed_path_is_refused` for the art path); `GeometryOracle`'s dead `EDGE_INSET_TOLERANCE` and
`get_tree_nodes_in_group` are gone; `WishBubble.reset()` resets `_visual.scale`; `Log.event()` clears
`last_line` so a closed diary cannot leave a stale mirror (and `test_log.gd` reopens the diary in
`after_each()` so later suites never inherit a closed session); `QuiQuiRig._hits_character()` filters
`_gui_input` to `get_visual_global_rect()` so taps outside the painted character are ignored even on a
stretched box; `GeometryOracle._audit_rig_box_is_the_character` checks both vertical and horizontal
dead space; `LogSink`, `ProgressManager`, and `TapButton` deduplicate their helpers; and `quiqui_rig.gd`
is trimmed under the 300-line ceiling.

Not done, deliberately: `SceneBuilder.pin`'s `Vector4` slots keep their
`scene_builder.gd` docstring rather than a typed record — recorded here as accepted.

## Verification

`bash scripts/preflight.sh` → **PREFLIGHT GREEN**: 19 scripts, **165 tests, 647 asserts** on `fix/bug-013-hero-scale` (**24 scripts, 308 tests, 1429 asserts** after merging into `epic/e03-kitchen-feed-scene`).
New guards: `test_a_character_that_paints_smaller_than_its_box_is_caught`,
`test_a_character_with_horizontal_dead_space_in_its_box_is_caught`,
`test_a_character_that_fills_its_box_passes`, `test_an_oversized_scene_root_is_caught`,
`test_a_scene_that_forgets_a_declared_group_is_caught`,
`test_the_box_widens_with_the_height_on_a_centre_anchored_rig`,
`test_the_character_is_measured_on_its_opaque_pixels`, `test_every_base_pose_keeps_the_height_and_the_feet`,
`test_a_rig_that_cannot_report_painted_geometry_is_caught`,
`test_the_painted_character_keeps_the_design_height_on_ipad` (casa and titulo),
`test_a_trailing_newline_is_refused`, `test_reset_mid_pulse_returns_the_visual_to_rest`,
`test_last_line_never_survives_a_closed_diary`, `test_the_painted_rect_is_not_the_control_box`,
`test_taps_outside_the_painted_character_are_ignored`.

**Mutation-checked (round 5):** replacing the body of `get_visual_global_rect()` with
`return get_global_rect()` — the natural "cleanup" — now fails
`test_the_painted_rect_is_not_the_control_box` (`2048.0 expected to be < 1024.0`); before that test the
suite stayed 162/162 green.
