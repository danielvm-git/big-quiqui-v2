---
bug_id: BUG-044
status: open
severity: low
scope: code
title: A zero or negative EconomyData.wheel_spin_ticket_cost gives free spins or mints tickets
---
# BUG-044: A zero or negative EconomyData.wheel_spin_ticket_cost gives free spins or mints tickets

<!-- story: e08s03 -->

**Found by:** e08 post-epic review (whole-epic diff 272c722..844884d).

## Evidence

roda.gd uses `economy.wheel_spin_ticket_cost` raw: 0 means free endless spins, negative means
add_tickets(+n) on every spin. Tuning tables are data (FIX-05) and will be edited by hand. Fix: the
scene spends at least 1 ticket.
