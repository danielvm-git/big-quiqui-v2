---
bug_id: BUG-013
status: open
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

## Fix plan (TDD, red first)
1. **RED** in `game/tests/integration/test_geometry_oracle.gd`: a `QuiQuiRig` whose box is 640×881 on a
   2048×1536 canvas must be *caught* for painted height 0.418 < 0.55; add the same case to
   `test_casa_scene.gd` next to the existing `has_area()` assertion.
2. Change `_audit_rig_height` / `_audit_rig_feet` to measure `rig.get_visual_global_rect()` when the
   node is a `QuiQuiRig`, keeping the box assertion as a second, separate check.
3. Fix the layout: drive the art scale from height (`factor = box.y / art.y`) and let the **width track
   the height** (`offset_left/right = ±size.y * RIG_ASPECT / 2` in `_notification(NOTIFICATION_RESIZED)`),
   or use an `AspectRatioContainer`. Measured clear width at 1920×1440: art would span x ≈ 547…1373;
   door columns end at 232 / start at 1688, so it fits.
4. Reject taps outside `get_visual_global_rect()` in `_gui_input` (one `has_point` test).
5. Re-measure and correct every affected record (see BUG-014).

## Deferred should-fix items from the same reviews (fix in this cycle if cheap)
- `Ids.PATTERN` uses `^…$`; `CONVENTIONS.md:78` mandates `\A…\z` — `Ids.is_valid("base\n") == true`
  (REVIEW-A should-fix 1). Same for `WishBubble.ART_PATH_PATTERN`. Add the newline case to the tests.
- `GeometryOracle` group checks are silent no-ops when a group is empty, and the root rect is never
  audited directly; a scene can opt out of its own layout gate by forgetting `add_to_group`
  (REVIEW-A should-fix 2). Add `required_groups` to the spec.
- Dead code the cycle added: `EDGE_INSET_TOLERANCE` and `get_tree_nodes_in_group`
  (REVIEW-B should-fix 4).
- `WishBubble.reset()` does not reset `_visual.scale` (REVIEW-B consider 7); `Log.event()` returns
  before assigning `last_line` when no session file is open (consider 10).

## Verification
Pending — this bug is open. The cycle closes when both reviewers pass the AND gate (round 2/5) with
zero must-fix each.
