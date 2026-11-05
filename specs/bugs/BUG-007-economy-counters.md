---
bug_id: BUG-007
status: fixed
severity: medium
scope: persistence
title: Tickets clamp against MAX_COINS and complete_cycle emits three times
---
# BUG-007: Ticket cap reuses `MAX_COINS`; `complete_cycle` emits three signals

<!-- story: e01s03 -->

## Problem
**Actual:** `add_tickets` clamps to `SaveData.MAX_COINS` (999 999) — a ticket ceiling that exists
only by accident of naming; `complete_cycle` increments `completed_cycles` with no ceiling and
emits `progress_changed` three times for one logical change.
**Expected:** per-currency ceilings (`MAX_COINS`, `MAX_TICKETS`, `MAX_CYCLES`) and exactly one
`progress_changed` per mutation.
**Security impact:** NONE (local economy integrity, already clamped against inflation).

## Root cause (verified)
`progress_manager.gd:112-128` reuses `MAX_COINS` for tickets and calls the announcing mutators.

## Fix (TDD)
- RED `test_progress_manager.test_tickets_use_their_own_ceiling`,
  `test_complete_cycle_announces_once`, `test_cycles_are_clamped`.
- GREEN add `MAX_TICKETS`/`MAX_CYCLES` to `SaveData`; `complete_cycle` mutates and emits once.

## Verification

`bash scripts/preflight.sh` → GREEN (19 scripts, 143 tests, 567 asserts, L0–L5b). The regression
test named in the fix plan is in the suite; see `specs/verifications/FIX-e01-e02-2026-11-04.md`
for the per-finding evidence, including the measured before/after layout.
