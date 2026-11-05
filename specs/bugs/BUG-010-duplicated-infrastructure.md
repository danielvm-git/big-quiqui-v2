---
bug_id: BUG-010
status: fixed
severity: low
scope: core
title: Log bridge, squash spring, scene-builder scaffolding and care-step names are duplicated
---
# BUG-010: Duplicated infrastructure (G5)

<!-- story: e01s04 -->

## Problem
**Actual:** the 5-line `_emit`/`_log` diary bridge is copy-pasted in 10 files; the 3-keyframe
squash spring (constants + ~20-line stepper) in `tap_button.gd` and `quiqui_rig.gd`; ~55 lines of
pack/save/owner/count scaffolding in the two scene builders; the five care-step names as bare
strings in `CareLoopManager`, `casa.gd` and `build_casa_scene.gd`.
**Expected:** one owner per concept.
**Security impact:** NONE.

## Fix (TDD)
- RED every existing unit/integration test must stay green through the refactor (no behaviour
  change allowed): `test_tap_button`, `test_quiqui_rig`, `test_casa_scene`, `test_*` managers.
- GREEN `game/scripts/core/log_sink.gd`, `game/scripts/core/squash_spring.gd`,
  `game/scripts/core/care_steps.gd`, `game/tools/scene_builder.gd`.

## Verification

`bash scripts/preflight.sh` → GREEN (19 scripts, 143 tests, 567 asserts, L0–L5b). The regression
test named in the fix plan is in the suite; see `specs/verifications/FIX-e01-e02-2026-11-04.md`
for the per-finding evidence, including the measured before/after layout.
