---
bug_id: BUG-041
status: fixed
severity: low
scope: code
title: vila._ready (25), roda._ready (22) and CoinTicketHud.fly_coin (28) exceed the 20-line bar in CONVENTIONS section 5
---
# BUG-041: vila._ready (25), roda._ready (22) and CoinTicketHud.fly_coin (28) exceed the 20-line bar in CONVENTIONS section 5

<!-- story: e08s01 -->

**Found by:** e08 post-epic review (whole-epic diff 272c722..844884d).

## Evidence

The bar has been enforced in every previous audit. Fix: extract wiring helpers; no behaviour change.

## Fix

`_ready` split in vila/roda, `fly_coin` split into `_make_fly_sprite`/`_land_coin`.
