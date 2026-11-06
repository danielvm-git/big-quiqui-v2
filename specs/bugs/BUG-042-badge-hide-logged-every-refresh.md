---
bug_id: BUG-042
status: fixed
severity: low
scope: code
title: wheel.badge_hide is logged on every progress_changed while the badge is hidden, with a reason that is only true once
---
# BUG-042: wheel.badge_hide is logged on every progress_changed while the badge is hidden, with a reason that is only true once

<!-- story: e08s03 -->

**Found by:** e08 post-epic review (whole-epic diff 272c722..844884d).

## Evidence

roda.gd:_refresh_badge logs 'first_spin_done' whenever show_badge is false, including before any
spin when the child has 0 tickets, and again on each coin change. Misleading diary and log noise.
Fix: log once, on the visible->hidden transition.

## Fix

log only on the visible->hidden transition after a spin.
