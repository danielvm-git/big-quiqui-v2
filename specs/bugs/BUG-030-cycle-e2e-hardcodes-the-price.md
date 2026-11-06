---
bug_id: BUG-030
status: fixed
severity: low
scope: tests
title: The cycle E2E asserted the reward against literals 5 and 1 instead of the economy's constants
---
# BUG-030: the reward written twice in the E2E

<!-- story: e07s04 -->

**Found by:** e07 post-epic review, second pass (same defect class as BUG-026 #5, found one file over).

## Problem

`test_cycle_e2e.gd` asserted `get_coins() == 5` and `get_tickets() == 1`. The price lives in
`ProgressManager.CYCLE_COINS_REWARD` / `CYCLE_TICKETS_REWARD` (where BUG-007's clamps and BUG-016's
release work also read it). Two literal copies of a tuning value in a test means a designer changing the
reward gets a red test that implies a regression, instead of the assertion following the constant.

## Root Cause

The numbers were typed when the test was written; BUG-026 removed the same duplication from
`CelebrationScene` but not from the E2E.

## Fix

Both assertions (and the iPad one) read `pm.CYCLE_COINS_REWARD` / `pm.CYCLE_TICKETS_REWARD`.

## Verification

408/408 green; `grep '\b5\b'` over the file leaves only the step counts and `STEP_SEC`.
