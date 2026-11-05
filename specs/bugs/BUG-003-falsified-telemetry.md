---
bug_id: BUG-003
status: fixed
severity: medium
scope: telemetry
title: care.abandon and fsm.dwell_timeout log falsified payloads
---
# BUG-003: Two diary events carry falsified payloads

<!-- story: e02s01 -->

## Problem
**Actual:** `care.abandon` always records `step=idle` (the state is read **after** the transition
to IDLE), and `fsm.dwell_timeout` records `limit_sec=2000` for a 2.0 s limit.
**Expected:** the abandoned step and a truthful unit.
**Security impact:** LOW — the e02 threat model's repudiation mitigation ("a parent can tell which
care steps happened") is defeated for detours; no exploit path (local file only).

## Root cause (verified)
`care_loop_manager.gd:74-80` reads `fsm.state` after `fsm.transition_to(STATE_IDLE)`.
`fsm.gd:105` multiplies by 1000 but keeps the `_sec` suffix. No test asserted either payload, so
both survived a green suite.

## Fix (TDD)
- RED `test_care_loop_manager.test_abandon_event_names_the_step_it_left` and
  `test_fsm.test_dwell_timeout_logs_milliseconds_truthfully` read `Log.last_line`.
- GREEN capture the state before the transition; rename the key to `limit_ms`.

## Verification

`bash scripts/preflight.sh` → GREEN (19 scripts, 143 tests, 567 asserts, L0–L5b). The regression
test named in the fix plan is in the suite; see `specs/verifications/FIX-e01-e02-2026-11-04.md`
for the per-finding evidence, including the measured before/after layout.
