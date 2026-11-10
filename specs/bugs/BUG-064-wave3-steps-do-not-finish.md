---
bug_id: BUG-064
status: fixed
severity: high
scope: player
title: Wave-2 and wave-3 steps finished only because the test wrote progress
---

# BUG-064

Review round 1 of `5f99501..6b2a661` (Reviewer A 41.4, Reviewer B 40). A child could not finish ride, slice, serve, or the outro. The child-play helper wrote `progress = 1.0`.

## Fix

- Ride draws a rider and toys inside the steer bounds and collects on overlap.
- Slice draws the cut marks and scrubs a hull that contains the polyline. Threshold is honored.
- Serve places the guest before Give binds the drop target, and exposes the food chips.
- Outro is finished by tapping the home button. The progress nudge is gone.
- Groom resets the rub between comb, dry, and trim.
- Paint registers and sizes the canvas and tints it. The brush id is `sponge`.
- The progress probe keeps the tap step and draws `t49` beside it. The holder does not complete the step.
- The 28-slot gate reads the template table and the script directory. A reserved number with a real script fails it.
- Memory ignores a second tap on the same card. Cups use their own picture. Movers use lanes.

## Verify

`bash scripts/preflight.sh` → GREEN. `test_child_can_play` passes ride and serve at both aspects.
