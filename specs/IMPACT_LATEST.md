# Impact — e01s01 (Godot 4.7 Expand Viewport, Fsm Core, Log JSONL & Test Helpers)

<!-- story: e01s01 -->
**Skill:** `assess-impact` (lightweight) · **Date:** 2026-11-04 · **Mode:** pre-build

## Verdict

**Risk: 3 / 10 — LOW. Proceed without a `grill-me` gate.**
Net-new code on an empty `game/scripts` tree: no existing dependents, no runtime
surface to break. The risk that matters is *irreversibility of decisions*, not blast
radius — and those decisions are already frozen in ADR-001..006.

## Blast radius

| Area | Dependents today | What e01s01 changes |
|---|---|---|
| `game/scripts/core/fsm.gd` | none (0 `.gd` files) | creates the FSM every later manager must use (ADR-001) |
| `game/scripts/autoloads/log.gd` | none | creates `Log`; every later `Log.event()` call depends on its schema |
| `game/tests/helpers/*` | none | creates `TestReset`, `FsmProbe`, `TouchSim`, `GeometryOracle`; all 43 stories' tests depend on these APIs |
| `game/project.godot` | CI, big-release, preflight | adds autoloads + `run/main_scene` stays unset until e01s05 |
| `scripts/preflight.sh` | hooks + CI | unchanged; becomes non-vacuous for the first time |

## Downstream stories touched by the interfaces this story freezes

| Story | Depends on | Coupling |
|---|---|---|
| e01s02 | `Fsm` API (`transition_from`, `legal_edges`, `max_dwell_sec`) | HIGH — a change to `Fsm` breaks SceneManager/AudioManager |
| e01s03 | `TestReset` (save-path redirection), `Log` schema | HIGH |
| e01s04 | `TouchSim`, `GeometryOracle`, `Fsm` | HIGH |
| e01s05 | all four helpers + `Log` + autoload set | HIGH |
| e02–e11 (38 stories) | all of the above | HIGH at the API level, low in volume |

This is why the four helper APIs are treated as ADR-level decisions rather than
implementation detail: they are the contract for 42 downstream stories.

## Test coverage that must exist before the code

| Layer | Required by `TEST_PLAN_LATEST.md` | Planned in `e01-TEST_PLAN_LATEST.md` |
|---|---|---|
| Unit | Fsm legal edges, idempotency, dwell timeout | SC-E01-P0-01..03 |
| Integration | autoload boot, Log JSONL schema + PII, atomic save round-trip | SC-E01-P0-04..06 |
| E2E / geometry | dual aspect 1920×1080 + 2048×1536, ≥120 px hit targets | SC-E01-P0-07 |
| Control (anti-vacuity) | preflight must go RED when the suite is empty | SC-E01-P0-08 |

## Migration / rollback

No data migration: `user://` is untouched until e01s03 introduces `SaveData`.
Rollback is `git revert` of a single story branch; no schema or save-format debt.

## Recommendation

Proceed to `kickoff-branch` → `develop-tdd` for e01s01 in this order:
`Fsm` (unit) → `Log` (unit + PII) → helpers (`TestReset`, `FsmProbe`) → `TouchSim` /
`GeometryOracle` (integration) → autoload wiring (integration). Write the control test
(empty-suite → preflight RED) first: it protects every later story from the vacuity
mode found in Phase 1.

`plan-consistency-check.sh` for the e01 capsule: **CRITICAL=0 HIGH=0 MED=0** (PASS).
