# Impact — e07 (SleepScene + CelebrationScene, close the care cycle)

<!-- story: e07s01 -->
**Skill:** `assess-impact` (lightweight) · **Date:** 2026-11-06 · **Mode:** pre-build, brownfield

## Verdict

**Risk: 5 / 10 — MEDIUM.** Net-new scenes, but the first epic that **closes a care cycle**, so it touches
the two modules every other epic depends on: `CareLoopManager` (its `CELEBRATE → IDLE` edge and
`complete_cycle`) and `ProgressManager` (the reward path with the BUG-007 clamps).

## Modules on the change path

| Module | Why it changes | Dependents | Existing tests | Coverage note |
|---|---|---|---|---|
| `game/scripts/scenes/quarto_sono.gd` (new) | SLEEP scene: lamp toggle, `sono` expression, SLEEP credit | `casa.gd` door table | none yet | new |
| `game/scripts/scenes/celebracao.gd` (new) | CELEBRATE scene: confetti, voice, closing the cycle. **The planned "reward reveal" did not ship** — see BUG-031 (deferred: it changes e07s02's frozen contract) | `casa.gd` door table | `test_celebracao_scene.gd` | direct |
| `scripts/autoloads/care_loop_manager.gd` | ensure `SLEEP → CELEBRATE → IDLE` is walked exactly once and the cycle id increments | every scene's credit path, `casa.gd` dots | `test_care_loop_manager.gd` (13) | direct |
| `scripts/autoloads/progress_manager.gd` | `complete_cycle` reward once per cycle (BUG-007 clamps) | `casa.gd` HUD, celebration scene | `test_progress_manager.gd` (16) | direct |
| `game/scripts/components/quiqui_rig.gd` | `sono`/`celebrando` expressions exist already; no API change expected | every scene | `test_quiqui_rig.gd` (404 lines) | direct, hotspot #3 |
| `game/tools/build_quarto_sono_scene.gd`, `build_celebracao_scene.gd` (new) | generate the two `.tscn` | n/a | builders are tooling | gap by design (see `COVERAGE_MAP_LATEST.md`) |

## Affected stories

`e07s01`–`e07s04` (this epic). No earlier story reopens: `e02`'s Casa doors already declare `SLEEP` as the
last pending door, and both new `.tscn` files make their doors navigate — the same "adding a scene is an
integration change" pattern that D? fired on e04/e05/e06, now expected here.

## Test coverage on the path

| Surface | Today | Planned |
|---|---|---|
| `CareLoopManager` cycle close | `test_care_loop_manager.gd` covers edges and `complete_step`, not a full `IDLE→…→CELEBRATE→IDLE` walk | one unit test for the full walk + `completed_cycles` increment |
| `ProgressManager.complete_cycle` | covered incl. clamps and single emit (BUG-007) | a reward-once assertion from the celebration scene |
| Door table | `test_casa_scene.gd` asserts doors per step | the SLEEP door navigates once; "doors stay pending" retires |
| Layout | `GeometryOracle` per scene type | both new scenes pass `STEP_ROOM_SPEC` on three canvases |

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Double reward if `complete_cycle` runs twice | existing `_rewarded_cycle_id` guard; assert from the scene |
| Cycle never closes (`CELEBRATE` without `→ IDLE`) | explicit test for the closing edge; the FSM already declares it |
| Two scenes in one epic means two builders, two layouts | one shared spec (`STEP_ROOM_SPEC`), builders mirror the existing pattern |
| `quiqui_rig.gd` is 427 lines and the #3 hotspot | no API change planned; if one is needed, extract rather than grow |

**No `grill-me` gate required** (risk ≤ 7). Recommended first commit: the failing `CELEBRATE → IDLE` walk
test, before either scene exists.
