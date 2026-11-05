---
bug_id: BUG-012
status: fixed
severity: low
scope: core
title: Managers dereference internals before _ready and show_wish validates paths loosely
---
# BUG-012: Pre-`_ready` dereferences and prefix-only path validation

<!-- story: e02s03 -->

## Problem
**Actual:** (1) `CareLoopManager.state_id()/next_step()/completed_steps()` and
`AudioManager.play_*`/`reset()` dereference `fsm`/players that `_ready()` has not built yet — a
`SceneTree` script that instantiates `casa.tscn` before the autoload frames gets
"Invalid access to property 'state' on a base object of type 'Nil'". (2)
`WishBubble.show_wish()` accepts any string with the `res://assets/art/` prefix and a `.png`
suffix, including `res://assets/art/../../x.png`.
**Expected:** managers degrade like every other autoload (CONVENTIONS §4); art paths are built
from a validated id, as the e02 threat model claims.
**Security impact:** LOW — shadowed threat-model claim; no remote input reaches the path.

## Root cause (verified)
`_ready()` is the only initialiser and no caller guards for it; `show_wish` used string
prefix/suffix instead of the id contract.

## Fix (TDD)
- RED `test_care_loop_manager.test_reads_do_not_crash_before_ready`,
  `test_audio_manager.test_calls_before_ready_degrade`, `test_wish_bubble.test_a_traversal_path_is_refused`.
- GREEN null guards (`if fsm == null: return`) and `Ids`-based path construction for the wish icon.

## Verification

`bash scripts/preflight.sh` → GREEN (19 scripts, 143 tests, 567 asserts, L0–L5b). The regression
test named in the fix plan is in the suite; see `specs/verifications/FIX-e01-e02-2026-11-04.md`
for the per-finding evidence, including the measured before/after layout.
