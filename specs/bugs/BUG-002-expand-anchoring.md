---
bug_id: BUG-002
status: fixed
severity: high
scope: ui
title: Interactive UI is not anchored for the expanded 4:3 canvas
---
# BUG-002: Interactive UI is not anchored for the expanded 4:3 canvas

<!-- story: e02s03 -->

## Problem
**Actual:** on the 4:3 expanded canvas (1920×1440) the hub keeps 16:9 pixel coordinates: QuiQui's
feet land at 58 % of the height (DESIGN §layout: 78 % of stage), the rig occupies 43 % of the
height (DESIGN: 55–65 %), and `CareDotsBar` floats 396 px above the bottom edge — a dead band at
the bottom of the primary target device.
**Expected:** ADR-002 / `DESIGN.md:27-31` — interactive UI anchors to the viewport edges or a
centered `SafeStage`; QuiQui keeps 55–65 % of height with feet at 78 %.
**Security impact:** NONE.

## Root cause (verified)
`build_*_scene.gd` position every node with `position`/`size` only (anchors 0,0). DESIGN offers
two compliant options (edge anchoring **or** `SafeStage`); the implementation used neither, and
`GeometryOracle` had no aspect-aware assertion (it only checked letterbox + hit-target size), so
the deviation shipped green. `e02s03-2026-11-04.md:62` recorded the trade-off but no ADR/exception
carries it, and `QuiQuiRig` never re-lays out after a size change.

## Decision
Edge anchoring (DESIGN's first option). Layout is expressed as ratios of the canvas, which keeps
the 16:9 composition pixel-identical and makes the 4:3 canvas compose correctly. Recorded in
`specs/adr/ADR-008-edge-anchored-responsive-composition.md`.

## Fix (TDD)
- RED `test_geometry_oracle.test_a_rig_off_the_78_percent_feet_line_is_caught` and
  `test_a_bottom_bar_that_floats_is_caught` — spec-driven findings.
- GREEN `GeometryOracle.audit(root, size, spec)` gains `rig`/`ui_bottom`/`ui_top_right` group
  checks; scene tests pass the DESIGN ratios explicitly.
- GREEN builders anchor: rig (`anchor_top = 0.78 - 620/1080`, `anchor_bottom = 0.78`, width fixed
  and centred), doors (edge columns, row centres as ratios), dots (bottom, 36 px inset), HUD
  (top-right, 36 px inset), bubble (relative to the feet line), Play (bottom, 72 px inset).
- GREEN `QuiQuiRig._notification(NOTIFICATION_RESIZED)` re-anchors the foot pivot and re-runs
  `_update_layout()`, so a taller box grows the art instead of leaving it stranded.

## Verification

`bash scripts/preflight.sh` → GREEN (19 scripts, 143 tests, 567 asserts, L0–L5b). The regression
test named in the fix plan is in the suite; see `specs/verifications/FIX-e01-e02-2026-11-04.md`
for the per-finding evidence, including the measured before/after layout.
