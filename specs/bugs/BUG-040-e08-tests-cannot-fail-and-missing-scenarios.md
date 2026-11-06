---
bug_id: BUG-040
status: open
severity: medium
scope: tests
title: "e08 tests: hint-once test never recycles, miss test does not check the bag returned, SC-E08-P0-20 and SC-E08-P1-15 are absent"
---
# BUG-040: e08 tests: hint-once test never recycles, miss test does not check the bag returned, SC-E08-P0-20 and SC-E08-P1-15 are absent

<!-- story: e08s02 -->

**Found by:** e08 post-epic review (whole-epic diff 272c722..844884d).

## Evidence

test_hint_runs_once_then_skips_after_success declares bag and bin and never uses them (the name
promises 'after success'); test_miss_returns_without_paying never asserts the start position (AC11);
test_economy_properties has no wheel/recycle interleave (SC-E08-P0-20), no seeded-determinism case
(SC-E08-P1-15) and no insufficient-tickets case. Fix: add the missing assertions and scenarios.
