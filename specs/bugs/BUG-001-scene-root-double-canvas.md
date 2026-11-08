---
bug_id: BUG-001
status: fixed
severity: high
scope: ui
title: Scene roots pack at 2x the canvas and the geometry oracle cannot see it
---
# BUG-001: Scene roots pack at 2× the canvas; the oracle is blind to oversize

<!-- story: e01s05 -->

## Problem
**Actual:** `casa.tscn` and `titulo.tscn` roots measure 3840×2160 inside a 1920×1080 canvas
(3840×2520 in the 4:3 expanded 1920×1440 canvas). `Background` is a full-rect child of that
doubled root, so `STRETCH_KEEP_ASPECT_COVERED` renders the art at 2× and the player sees only
the top-left quadrant of `bg_home.jpg` / `bg_title.jpg`.
**Expected:** root rect == visible canvas; background full-bleed with the whole composition.
**Security impact:** NONE (no data path).

## Root cause (verified)
`build_{titulo,casa}_scene.gd` do `set_anchors_preset(PRESET_FULL_RECT)` **then**
`root.size = Vector2(1920, 1080)`. Godot's `set_anchors_preset` preserves the current rect by
rewriting offsets, so the packed scene carries `anchor_right/bottom = 1.0` **plus**
`offset_right = 1920, offset_bottom = 1080` → `right = parent_w + 1920`.
Verified headless (`SubViewport`, 2 frames): canvas 1920×1080 → root 3840×2160; canvas 1920×1440 →
root 3840×2520. A control built with `set_anchors_and_offsets_preset(PRESET_FULL_RECT)` measures
exactly the canvas at both sizes.

**Why green:** `GeometryOracle._audit_background` asserts only `rect covers canvas` (`≥`), never
`≤`, so any oversized background passes (see BUG-002's oracle extension).

## Fix (TDD)
- RED `test_geometry_oracle.test_an_oversized_background_is_caught` — a background 2× the canvas
  must produce a finding mentioning "oversized".
- GREEN `_audit_background` compares `rect.size` to the canvas within `COVER_TOLERANCE` both ways.
- RED `test_titulo_scene` / `test_casa_scene` oracle runs fail on the regenerated-but-unfixed scenes.
- GREEN builders call `set_anchors_and_offsets_preset(PRESET_FULL_RECT)` and drop `root.size`;
  regenerate both `.tscn` with the builders.

## Verification

`bash scripts/preflight.sh` → GREEN (19 scripts, 143 tests, 567 asserts, L0–L5b). The regression
test named in the fix plan is in the suite; see `specs/verifications/FIX-e01-e02-2026-11-04.md`
for the per-finding evidence, including the measured before/after layout.
