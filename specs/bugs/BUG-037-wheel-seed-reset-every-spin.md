---
bug_id: BUG-037
status: open
severity: medium
scope: code
title: WheelScene re-seeds its RNG to 42 on every spin, so the shipped wheel pays the same prize forever
---
# BUG-037: WheelScene re-seeds its RNG to 42 on every spin, so the shipped wheel pays the same prize forever

<!-- story: e08s03 -->

**Found by:** e08 post-epic review (whole-epic diff 272c722..844884d).

## Evidence

roda.gd:_on_spin_tapped sets `_rng.seed = 42` before each pick_prize. The roll is then a constant,
so every spin of every session pays the same prize. The spec wants a seeded RNG field that tests can
set (SC-E08-P1-15), not a game that is deterministic. Review B called it intentional; it is a
gameplay defect. Fix: seed once per scene (randomize in production, `rng_seed` for tests).
