---
bug_id: BUG-038
status: fixed
severity: medium
scope: code
title: Tapping Home while the wheel is SPINNING debits the ticket and never pays the prize
---
# BUG-038: Tapping Home while the wheel is SPINNING debits the ticket and never pays the prize

<!-- story: e08s03 -->

**Found by:** e08 post-epic review (whole-epic diff 272c722..844884d).

## Evidence

roda.gd debits the ticket at spin start and grants coins 0.35 s later in advance(). `_on_home` has
no guard, so leaving inside that window loses the ticket and the coins. A 4-7 year old taps Home
constantly. Fix: Home is inert while the wheel is not IDLE (the single-spin lock extends to exit).

## Fix

Home inert unless the wheel is IDLE.
