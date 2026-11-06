---
bug_id: BUG-043
status: fixed
severity: low
scope: docs
title: e08 left no threat model, README/TEST_PLAN/state counters stale, and frozen contracts that never shipped are not recorded
---
# BUG-043: e08 left no threat model, README/TEST_PLAN/state counters stale, and frozen contracts that never shipped are not recorded

<!-- story: e08 -->

**Found by:** e08 post-epic review (whole-epic diff 272c722..844884d).

## Evidence

No specs/security/epics/e08/THREAT_MODEL.md (e01-e07 have one). README says v0.9.0 and 38 scripts /
408 tests; state.yaml says 41/426 (real 42/425). TEST_PLAN has no e08 section. Contracts that differ
from the code: `_roll_prize()`, defaults loaded from a .tres, the `DragHint.play` third argument,
`mao_dica.png` (a ColorRect ships), a spawn->drag->drop->reward->respawn Fsm (two states ship, no
respawn). Fix: threat model, counters, test plan, and ADR-010 recording the deliberate trade-offs.

## Fix

threat model, ADR-010, TEST_PLAN section 5, README and state counters.
