---
bug_id: BUG-006
status: fixed
severity: medium
scope: ui
title: QuiQuiRig.reset leaves the previous outfit visible
---
# BUG-006: `QuiQuiRig.reset()` leaves the previous outfit visible

<!-- story: e01s04 -->

## Problem
**Actual:** `reset()` clears `outfit_id` but the outfit sprite stays visible and textured, so a
reset rig renders an outfit it does not claim to wear.
**Expected:** reset returns the rig to the neutral, outfit-less pose (`set_outfit("")`).
**Security impact:** NONE.

## Root cause (verified)
`quiqui_rig.gd:225-235` resets `outfit_id` directly instead of calling the one method that owns the
outfit layer. `test_quiqui_rig` clears the outfit in the test body before `reset()`, hiding it.

## Fix (TDD)
- RED `test_quiqui_rig.test_reset_takes_the_outfit_off`.
- GREEN `reset()` delegates to `set_outfit("")`.

## Verification

`bash scripts/preflight.sh` → GREEN (19 scripts, 143 tests, 567 asserts, L0–L5b). The regression
test named in the fix plan is in the suite; see `specs/verifications/FIX-e01-e02-2026-11-04.md`
for the per-finding evidence, including the measured before/after layout.
