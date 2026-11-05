---
bug_id: BUG-014
status: open
severity: medium
scope: docs
title: BUG-002 closure evidence compares art-before with box-after; DESIGN §3 states a rule the builders break
---

# BUG-014: the e01/e02 records overclaim the 4:3 closure

<!-- story: e02s03 -->
**Opened by:** `request-review` round 1/5 — `REVIEW-A` must-fix 1 / should-fix 3, `REVIEW-B` must-fix 2 /
should-fix 5

## Problem

Three defects in the decision records, all of the same shape — a true statement about the rig's
`Control` box presented as a statement about the character:

1. **Mixed series.** `FIX-e01-e02:24-26` reads "Rig height ratio 0.430 → **0.574**" (1920×1440) and
   "0.400 → **0.574**" (2048×1536). The *before* values are the **art** ratio at `cc6a139` (the box was
   640×620 and equalled the art); the *after* values are the **box** ratio. Like-for-like the after
   values are 0.446 and 0.418 (BUG-013). `ADR-008:51-52` ("rig 0.574 of the height") and
   `AUDIT-e01-e02:310` repeat the same figure, and `BUG-002` is marked `status: fixed` with
   "QuiQui keeps 55–65 % of height" as its expectation.
2. **Traceability names a test that does not exist.** `BUG-002:34` names
   `test_a_rig_off_the_78_percent_feet_line_is_caught`; the shipped test is
   `test_a_rig_off_the_feet_line_is_caught` (`test_geometry_oracle.gd:100`).
3. **`DESIGN.md:29` states a rule both shipped scenes break.** It now reads "anchors **and offsets**
   are expressed as ratios of the canvas (never absolute `1920×1080` pixels)". The packed scenes
   anchor by ratio but keep **absolute pixel offsets** (`offset_left = 64.0`, `offset_right = 232`,
   `-320/320`) — which is the correct design: 36 px insets and 120×120 minimum hit targets must not
   scale with the canvas. Nine scenes will copy this line.

## Why it matters
A reviewer or the next epic reading these records would believe the HIGH layout finding is closed and
copy the pattern into e03–e10. This is the specific failure the cycle existed to fix, committed by the
cycle's own documentation.

## Fix plan
1. Land BUG-013 first, then **re-measure** and rewrite the three tables with two explicit columns —
   `box` and `painted` — labelled as such.
2. Correct `DESIGN.md:29` to: anchors are ratios, offsets are absolute pixels (insets, fixed hit-target
   sizes, feet-line offset), **and the rig box height is a ratio**.
3. Fix the test name in `BUG-002:34`; keep BUG-002 `fixed` only for the root-size half and point its
   hero-scale half at BUG-013.

## Verification
Pending — closes with BUG-013 in review round 2/5.
