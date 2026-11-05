---
bug_id: BUG-008
status: fixed
severity: medium
scope: core
title: Three divergent resource-id contracts
---
# BUG-008: Three divergent resource-id contracts

<!-- story: e01s03 -->

## Problem
**Actual:** `SaveData.ID_PATTERN` = `^[a-z0-9_]{2,32}$`, `QuiQuiRig.ID_PATTERN` = the same literal
again, `CONVENTIONS.md:76` mandates `\A[a-z0-9_]{1,64}\z`, and `Log` uses
`^[a-z0-9_.:/-]{1,64}$` (the diary schema, fixed by `scripts/log_tool.py`).
**Expected:** one owner for the game-wide id contract; the diary pattern stays separate and is
documented as the audit contract.
**Security impact:** LOW — validation drift is the classic path-traversal enabler; BUG-012 closes
the one live consumer.

## Root cause (verified)
The pattern was copy-pasted per module instead of extracted.

## Fix (TDD)
- RED `test_ids.test_one_contract_for_every_module` + `test_save_data`/`test_quiqui_rig` keep their
  rejection cases.
- GREEN `game/scripts/core/ids.gd` (`class_name Ids`) owns `PATTERN`/`is_valid()`; `SaveData` and
  `QuiQuiRig` delegate; `Log` keeps its own pattern with a comment naming its owner
  (`scripts/log_tool.py`).

## Verification

`bash scripts/preflight.sh` → GREEN (19 scripts, 143 tests, 567 asserts, L0–L5b). The regression
test named in the fix plan is in the suite; see `specs/verifications/FIX-e01-e02-2026-11-04.md`
for the per-finding evidence, including the measured before/after layout.
