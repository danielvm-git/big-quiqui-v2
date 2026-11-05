---
bug_id: BUG-004
status: wontfix
severity: medium
scope: telemetry
title: Every human-readable log message is redacted away
---
# BUG-004: Every human-readable `msg` is redacted away

<!-- story: e01s01 -->

## Problem
**Actual:** `Log.event(ev, {"msg": "hora do banho"})` stores `<redacted>`: the writer applies the
id-shape rule (`^[a-z0-9_.:/-]{1,64}$`, no spaces) to `msg`.
**Expected:** prose survives redaction+truncation; the external auditor explicitly exempts `msg`
from the id rule (`scripts/log_tool.py:37,191`) and still forbids PII in it.
**Security impact:** LOW — over-redaction, not disclosure.

## Root cause (verified)
`log.gd:160-171` reuses `is_safe_id()` for the one key designed for prose. `test_log.gd` only feeds
id-shaped `msg` values ("nhami"), so the contract was never exercised with a space.

## Resolution — WONTFIX (deliberate PII policy, now documented and tested)

Allowing prose would mean storing `"Maria Clara"`, which no PII regex can catch — the strictness is
the control, not the bug. What *was* wrong is that the policy was invisible: the writer appeared to
silently lose data and no test pinned the behaviour.

- The class doc and `_safe_value` now state the policy: `msg` carries a message **id**, never prose.
- `MSG_MAX_CHARS` and the dead two-branch `msg` special case are gone (`_safe_id` already bounds
  length), so the stricter-than-the-auditor rule is one line with one reason.
- `test_log.test_prose_under_msg_is_refused_by_policy` pins both halves: prose → `<redacted>`,
  `hora_do_banho` → stored. Reopening this needs an explicit PII decision, not a refactor.

## Verification

`bash scripts/preflight.sh` → GREEN (19 scripts, 143 tests, 567 asserts, L0–L5b). The regression
test named in the fix plan is in the suite; see `specs/verifications/FIX-e01-e02-2026-11-04.md`
for the per-finding evidence, including the measured before/after layout.
