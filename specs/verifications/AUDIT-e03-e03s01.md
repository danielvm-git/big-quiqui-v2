# Audit — e03s01 (gate mode)

<!-- story: e03s01 -->
**Target:** working tree of `feat/e03s01-touch-draggable` against `epic/e03-kitchen-feed-scene` · **Date:** 2026-11-05 · **Auditor:** the coding agent (self-review, no second agent)

VERDICT: PASS

## History

The first pass **failed**. It was fixed and the gate was re-run, not waived.

| First-pass finding | Fix |
|---|---|
| `test_touch_draggable.gd` was 597 lines (limit 300) | split into two test files (234 and 267 lines) with a shared fixture (114 lines) |
| `test_conversion_holds_inside_a_canvas_layer` was 23 lines (limit 20) | split into two tests and a setup helper |
| Duplicated Code: `{"item": name.to_lower()}` four times | `_emit` adds `item` once |

## Summary

| Section | Result | Evidence |
|---|---|---|
| Supply Chain & Security | PASS | no new dependencies; diff scan for key patterns and network classes found nothing |
| Provenance & Metadata | PASS | no new plan artefacts; code cites ADR-004 and T-E03-01 |
| Law of Demeter | PASS | the component talks only to its `fsm`, `drop_target` and `LogSink` |
| CONVENTIONS.md Compliance | PASS | reports are in `specs/verifications/`; no `gh` or API use |
| Scope | PASS, see note 1 | contract followed; no out-of-bounds file touched |
| Boy Scout Rule | PASS | no dead or commented-out code; the RED stub is fully replaced |
| Types and Safety | PASS | type_gate: 48 checked, 0 failed |
| Test Coverage | PASS | 37 new tests; 16/16 mutants killed; every private path reached through `_gui_input`, `_process`, `advance` |
| SOLID and Heuristics | PASS, see note 2 | one responsibility: the drag gesture |
| Refactoring Smells | PASS | none named after the fix above |
| Code Style | PASS, see note 3 | component 179 lines; no function over 20 lines; max indent 3 tabs |

## Security

The diff handles no user data, auth or external API. Trust boundary 2 (input to game logic) is the only one touched:

- **T-E03-01 (HIGH), wedged lock:** closed. The lock is released on drop and on `_exit_tree`, and `enabled` cannot block release. Three tests cover it, and two mutants confirm those tests fail without the release.
- **T-E03-02 (HIGH), exactly-once:** closed for the component. `CONSUMED` is terminal, tested by a full replay. The scene part is e03s03 and e03s04.
- **T-E03-06 (LOW), diary flood:** closed. 30 motions write 0 lines.
- **Diary values:** only `item` (the node name, lowercased) and a const `outcome` are written. `Log` replaces any value that is not id-shaped with `<redacted>`. No coordinates are logged.

## F.I.R.S.T.

| Property | Result |
|---|---|
| Fast | full suite about 2.6 s; no waits or frames in the new tests |
| Isolated | each file passes alone (19 and 18 tests); the static lock is cleared when `autofree` frees the nodes, and a test proves that release |
| Repeatable | 3 full runs identical (180/180, 694 asserts); `manual_step` drives time |
| Self-validating | assertions only; `FsmProbe` for the machine |
| Timely | RED shown before implementation: 29 of 36 failing against the stub |

**Residual real-clock input:** the dwell check reads the `Fsm` wall clock. A test would have to spend over 1.0 s inside `RETURNING` to trip it; suite time makes that unlikely, and it is noted here, not hidden.

## Notes

1. **Scope:** the brief listed one test file. The split adds `test_touch_draggable_input.gd` and `touch_draggable_test_case.gd`. Both are test-only and exist to pass this gate.
2. **Dependency Inversion:** the `static` lock is global state on purpose. AC 9 requires it and the contract freezes it.
3. **Functions of 4–20 lines:** a few are shorter (`state_id`, `_owns`, `_to_global`, `_emit`). The rule's action is to split long functions, so these are not counted as failures. This is a judgement call.

## Red flags (rationalizations caught)

- "The 300-line limit is not in this repo's CONVENTIONS.md, so waive it." Rejected: the gate says any failure fails.
- "Isolation is proven": the first "run alone" command still loaded the config dirs and ran all 180 tests. It was re-run with `-gconfig=`.

## Checks that could not run

`scripts/bp-churn-rank.sh` and `audit-code/HEURISTICS.md` checks by script are not available here, and all changed code is new, so churn ranking adds nothing. `request-review` (a second agent) was not run: it is not in this task's process. This audit is the author reviewing their own code.
