---
bug_id: BUG-005
status: fixed
severity: medium
scope: ui
title: A hidden wish bubble reports scale 1.0 but keeps the last pulse
---
# BUG-005: `WishBubble` transform diverges from its reported state

<!-- story: e02s02 -->

## Problem
**Actual:** after `hide_wish()` mid-pulse, `pulse_scale()` returns 1.0 while `_visual.scale` keeps
the last pulse value; on the next `show_wish()` the bubble starts from a stale scale.
**Expected:** hidden ⇒ the visual is exactly 1.0, matching the reported invariant.
**Security impact:** NONE.

## Root cause (verified)
`wish_bubble.gd:50-60`: the hidden branch of `advance()` zeroes `_pulse_scale` only; the transform
is written in the shown branch alone. The unit test asserted `pulse_scale()`, never the transform.

## Fix (TDD)
- RED `test_wish_bubble.test_hiding_mid_pulse_returns_the_visual_to_rest`.
- GREEN the hidden branch resets `_visual.scale` to `Vector2.ONE` (and `hide_wish()` too).

## Verification

`bash scripts/preflight.sh` → GREEN (19 scripts, 143 tests, 567 asserts, L0–L5b). The regression
test named in the fix plan is in the suite; see `specs/verifications/FIX-e01-e02-2026-11-04.md`
for the per-finding evidence, including the measured before/after layout.
