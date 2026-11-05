---
bug_id: BUG-011
status: fixed
severity: low
scope: tooling
title: Dead test_mode field and gate blind spots in type_gate / trace-stories
---
# BUG-011: Dead state and two gate blind spots

<!-- story: e02s01 -->

## Problem
**Actual:** `CareLoopManager.test_mode` is written by `set_test_mode()` and read by nothing.
`type_gate.gd:14-19` scans `res://components` and `res://scenes` (neither exists) and omits
`res://tools`, so both scene builders — the code that produced BUG-001 — never pass the strict
typing gate. `scripts/trace-stories.sh` ignores `game/tools` for the same reason.
**Expected:** no dead state; every first-party `.gd` under `game/` is type-checked and tagged.
**Security impact:** NONE.

## Fix (TDD)
- RED `test_preflight_guard.test_type_gate_covers_the_tools_directory`.
- GREEN `ROOTS` = `scripts, tests, tools`; `trace-stories.sh` walks `game/scripts game/tests game/tools`.
- GREEN delete `CareLoopManager.test_mode`/`set_test_mode` (TestReset already tolerates managers
  without it) and keep the ADR-003 layer placeholders, which are the layering contract asserted by
  `test_quiqui_rig.test_layer_order_keeps_the_expression_above_the_outfit`.

## Verification

`bash scripts/preflight.sh` → GREEN (19 scripts, 143 tests, 567 asserts, L0–L5b). The regression
test named in the fix plan is in the suite; see `specs/verifications/FIX-e01-e02-2026-11-04.md`
for the per-finding evidence, including the measured before/after layout.
