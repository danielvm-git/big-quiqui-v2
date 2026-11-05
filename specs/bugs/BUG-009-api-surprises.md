---
bug_id: BUG-009
status: fixed
severity: low
scope: core
title: complete_step(IDLE) starts FEED and the Vila door is permanently dimmed
---
# BUG-009: Two misleading affordances

<!-- story: e02s03 -->

## Problem
**Actual:** (1) `CareLoopManager.complete_step("IDLE")` begins FEED — "complete" starts a cycle.
(2) `CasaScene` dims every door that is not the next care step, and the next step is never
`VILA`, so the recycling door renders permanently disabled while staying fully tappable.
**Expected:** `complete_step` only completes an in-cycle step; only the five care doors carry the
"waiting" dim.
**Security impact:** NONE.

## Root cause (verified)
`care_loop_manager.gd:135-142` `_successor(IDLE)` returns the first non-IDLE edge.
`casa.gd:134-139` iterates `DOOR_SCENES`, which includes `VILA`.

## Fix (TDD)
- RED `test_care_loop_manager.test_complete_step_from_idle_is_refused`.
- RED `test_casa_scene.test_the_vila_door_is_never_dimmed`.
- GREEN `_successor(STATE_IDLE)` → `""`; dim only the care doors.

## Verification

`bash scripts/preflight.sh` → GREEN (19 scripts, 143 tests, 567 asserts, L0–L5b). The regression
test named in the fix plan is in the suite; see `specs/verifications/FIX-e01-e02-2026-11-04.md`
for the per-finding evidence, including the measured before/after layout.
