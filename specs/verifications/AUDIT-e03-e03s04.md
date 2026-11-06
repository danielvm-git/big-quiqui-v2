# Audit: e03s04

<!-- story: e03s04 -->
**Skill:** `audit-code --gate` · **Date:** 2026-11-05 · **Target:** the working tree against `origin/epic/e03-kitchen-feed-scene`

VERDICT: PASS

## Gate summary

| Section | Result | Evidence |
|---|---|---|
| Supply chain and security | PASS | No new dependencies, so `slopcheck` does not apply. No secrets and no network classes in the diff. The one new `OS.execute` is in a test, with a constant command and project-derived paths. |
| Provenance | PASS | The verification report names ADR-004, T-E03-02, T-E03-03 and the AC 15 run that found the defect. |
| Law of Demeter | PASS | The test reaches the scene's own children through `door()`, `food()` and `rig`. |
| Conventions | PASS | `# story` tag on the new file, strict typing, `Fsm` unchanged, no AI attribution. §3.4 is updated. No output outside `specs/` except the one requested `CONVENTIONS.md` line. |
| Scope | PASS | Production change is the device filter in `TapButton` and `QuiQuiRig` only. `TouchDraggable`, `specs/release-plan.yaml` and `game/project.godot` were not edited. No production API was added for a test. |
| Boy Scout | PASS | The filter removes the nested mouse branch in both handlers. No dead code. |
| Types and safety | PASS | L0b type gate is green. |
| Test coverage | PASS | The fix has tests seen failing first. New `TouchSim` helpers have tests. See the mutation table in the verification report. |
| SOLID and heuristics | PASS | The filter is one guard at the top of each handler. |
| Refactoring smells | PASS, with advisory | Duplicated Code: the same guard in two components, listed below. |
| Code style | PASS, with advisories | See below. |

## Advisories

The skill's generic size limits do not appear in this project's `CONVENTIONS.md`, so they did not fail the gate. They are listed here so that a reviewer can overrule that reading.

1. `game/tests/integration/test_feed_e2e.gd` has 420 lines, above the skill's 300-line limit. The contract names this one file.
2. `_assert_full_journey` has about 35 lines, above the skill's 20-line limit. It reads as one journey, in order.
3. `TapButton` and `QuiQuiRig` each carry the two-line device guard. The brief names both, and extracting a helper would add code for two lines.
4. `QuiQuiRig` still accepts any mouse button as a tap, unlike `TapButton`. This behaviour is not new and no test or spec asks to change it, so it was left alone.

## Churn

`scripts/bp-churn-rank.sh` is not in this repository, so `git log --since=90.days` was used instead. The hottest changed file is `quiqui_rig.gd` (3 commits), and it was reviewed first. The `_gui_input` change does not touch the rest of the file.

## F.I.R.S.T.

| Rule | Result |
|---|---|
| Fast | The whole suite takes about 10 s. The E2E tests wait only on 3 layout frames per scene. |
| Isolated | `TestReset` runs before each test, signal spies connect once in `before_all`, and the audit copy is deleted after use. |
| Repeatable | The scene, rig, food and `SceneManager` timelines are stepped by hand, and the tray seed is fixed. 3 runs in a row were green. |
| Self-validating | Assertions only, with `FsmProbe` on the real machines and the real `logs.sh audit`. |
| Timely | The defect tests were written first and seen failing. The E2E tests passed on first run, so mutations prove they can fail. |

## Skipped items and rationalizations

- `verify-adversarial.sh`, `check-blind-spots.sh` and `completeness-critic.sh` are not in this repository, so they did not run. Mutation testing was the adversarial check instead.
- A second-opinion `request-review` did not run, because the brief does not ask for one.
- I noticed the temptation to treat the E2E tests passing on first run as proof enough. The mutation table is there because a test never seen failing proves little.
- I noticed the same temptation as e03s03 to call the size limits "not a project rule" so the gate would pass. The advisories above keep that decision visible.
