# Audit: e03 review fixes

<!-- story: e03s03 -->
<!-- story: e03s04 -->
**Skill:** `audit-code --gate` · **Date:** 2026-11-05 · **Target:** the working tree of `fix/e03-review-findings` against `origin/epic/e03-kitchen-feed-scene`

VERDICT: PASS

## Gate summary

| Section | Result | Evidence |
|---|---|---|
| Supply chain and security | PASS | No new dependencies, so `slopcheck` does not apply. No secrets and no network classes in the diff. F1 reduces a diary flood. The one new real `change_scene_to_file` call in a test uses a constant path that does not exist. |
| Provenance | PASS | `REVIEW-e03-2026-11-05.md` maps each finding to its fix and tests. ADR-008 is named for L3. |
| Law of Demeter | PASS | No new chains. The kitchen reaches its own children through `food()` and `tray`. |
| Conventions | PASS | Strict typing, `Fsm` unchanged, `# story` tags present, no text added, no AI attribution. Reports are in `specs/`. |
| Scope | PASS, with advisory | Production changes are the three scripts the brief names (`scene_manager.gd`, `cozinha.gd`, `quiqui_rig.gd`), plus the 5 import files. `TouchDraggable` and all audio files are untouched. See advisory 1. |
| Boy Scout | PASS | `WISH_ICON` is removed. `_load_pending_or_current` now has one job and shares `_swap_to_current`. No commented-out code. |
| Types and safety | PASS | L0b type gate is green. |
| Test coverage | PASS | Every fix has a test seen failing first. See the red table and mutation table in the review report. |
| SOLID and heuristics | PASS | One guard in the recovery. `_next_wish_art` is one small query. |
| Refactoring smells | PASS | No new smell named. `complete_step` for FEED now has two callers, with one line each, which is too small to extract. |
| Code style | PASS, with advisories | See below. |

## Advisories

The skill's generic size limits do not appear in this project's `CONVENTIONS.md`, so they did not fail the gate. They are listed here so that a reviewer can overrule that reading.

1. Tests go somewhat beyond the brief's list (see the deviations in the review report). Each one pins a boundary of a briefed fix.
2. Files above the skill's 300-line limit, all already over or close to it: `test_cozinha_scene.gd` 699, `test_feed_e2e.gd` 424, `test_quiqui_rig.gd` 371, `quiqui_rig.gd` 333, `test_scene_manager.gd` 317. Only `test_scene_manager.gd` crossed it in this change.
3. The `not _swapped` check in `recover_from_watchdog` cannot be false today. It stays because the brief names it.
4. `_on_home_tapped` has a nested `if`, two levels deep, which is inside the limit.
5. **Product risk, not a code defect:** looping is now on for music clips of 0.111 s to 0.692 s. See "Open item" in the review report.

## Churn

`scripts/bp-churn-rank.sh` is not in this repository, so `git log --since=90.days` was used instead. Among the changed scripts: `quiqui_rig.gd` 4 commits, `scene_manager.gd` 4, `cozinha.gd` 1. `scene_manager.gd` was reviewed first because H1 is there. The whole machine was read, not only the changed lines.

## F.I.R.S.T.

| Rule | Result |
|---|---|
| Fast | The whole suite takes about 10 s. |
| Isolated | `TestReset` runs before each test. Tests that inject `loader` clear it. |
| Repeatable | Every new watchdog test is stepped by `advance(2.1)` on the stepped clock. Two audio tests no longer race a short clip. 3 runs in a row were green. |
| Self-validating | Assertions only, with `FsmProbe` on the care loop. |
| Timely | Tests were written first and seen failing, except those that pin a guarantee already true, which the mutation table covers. |

## Skipped items and rationalizations

- `verify-adversarial.sh`, `check-blind-spots.sh` and `completeness-critic.sh` are not in this repository, so they did not run. Mutation testing was the adversarial check instead.
- A second-opinion `request-review` did not run, because this change responds to one and the brief does not ask for another.
- A new test ran the real `change_scene_to_file`. I noticed the temptation to use the `production_swap` seam there, which would have proved nothing about a real failure. The real call stays, because the path cannot resolve.
- I noticed the temptation to call the size limits "not a project rule" so the gate would pass. The advisories above keep that decision visible.
- I noticed the temptation to call M1 simply fixed. The flag is correct, but nobody has heard the result, and the report says so.
