---
bug_id: BUG-014
status: fixed
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
   sizes, and the rig's art-fitted half-width), **and the rig box height is a ratio**.
3. Fix the test name in `BUG-002:34`; keep BUG-002 `fixed` only for the root-size half and point its
   hero-scale half at BUG-013.

## Resolution

1. `FIX-e01-e02` gained a **Corrected measurements** section with a `box` *and* `painted` column and the
   command that reproduces it (`game/tools/measure_hero_scale.gd`); the old table stays, labelled as box
   geometry, so the before/after series can no longer be read as one series.
2. `DESIGN.md` §3 now states the rule the builders actually follow: anchors are ratios, offsets are
   absolute pixels, and the rig box width follows its height.
3. `BUG-002` names the shipped test (`test_a_rig_off_the_feet_line_is_caught`) and hands its hero-scale
   half to BUG-013.
4. `ADR-008` consequences now say the painted character **equals** the box at rest (0.574) and record
   the box-fitting rule — the earlier "painted 0.575 vs box 0.574" implied a structural difference that
   cannot exist.
5. **Round 2** found two more instances: `DESIGN.md` still carried the `~600–700 px` reading (true only
   on 16:9, false — 830 px — on the iPad the game targets); it now names the ratio as the contract and
   the px figure per canvas. `BUG-013` also claimed `WishBubble.ART_PATH_PATTERN` had been changed to
   `\A…\z` and tested when it had not; the pattern is now `\A…\z` and the newline case is pinned.
   The old "Before / after" column in `FIX-e01-e02` is now labelled **Box** height ratio, because it is
   art-before vs box-after, a mixed series kept only for the record.

## Verification

`bash scripts/preflight.sh` → PREFLIGHT GREEN (19 scripts, 165 tests, 647 asserts on `fix/bug-013-hero-scale`; 24 scripts, 308 tests, 1429 asserts on `epic/e03-kitchen-feed-scene`). Every number quoted in these records **for the current layout** comes from `game/tools/measure_hero_scale.gd`, which is committed and pins the rest pose
(`manual_step` + `pivot.scale = ONE`), so a reviewer reproduces 0.574 exactly.
