---
bug_id: BUG-015
status: fixed
severity: medium
scope: core
title: Residual e01-e03 audit advisories, unwired kitchen dwell check, rig input/pre-ready guards, and doc/size drift
---
# BUG-015: Residual e01-e03 audit advisories, unwired kitchen dwell check, rig input/pre-ready guards, and doc/size drift

<!-- story: e03s03 -->
<!-- story: e03s04 -->

## Problem

Across `AUDIT-e01-e02-2026-11-04.md`, `AUDIT-e03-e03s02.md`, `AUDIT-e03-e03s03.md`, `AUDIT-e03-e03s04.md`, `AUDIT-e03-review-fixes.md`, and `REVIEW-e03-2026-11-05.md`, six residual gaps and advisories were left as open notes instead of being closed in code and tests:

1. **Unwired kitchen dwell watchdog (`KitchenScene`):** `KitchenScene` configures `MAX_DWELL_SEC = {CHEWING: 2.0, PLEASURE: 2.0}` on its `Fsm`, and `EXPLICIT_STATE_MACHINES.md §6` documents the 2.0 s dwell deadline, but `KitchenScene.advance()` never calls `fsm.check_dwell()`. A long frame (`advance(2.1)`) during `CHEWING` or `PLEASURE` advances without emitting `dwell_exceeded` or logging `fsm.dwell_timeout`.
2. **`QuiQuiRig` mouse-button filter and pre-`_ready` guard:**
   - `QuiQuiRig._gui_input` accepts any `InputEventMouseButton` (including right-click and wheel events) as a tap, unlike `TapButton` and `TouchDraggable` which only accept `MOUSE_BUTTON_LEFT`.
   - `QuiQuiRig.mouth_global_center()` dereferences `mouth_zone` without a null guard before `_ready()`.
3. **`SceneManager` redundant `_swapped: bool` flag and unreachable branch:** `SceneManager` carried `_swapped: bool` alongside `Fsm`, creating an untestable `if not _swapped` check in `recover_from_watchdog()` because `SWAPPING` transitions immediately to `FADING_IN`.
4. **`FoodCatalog.get_item` untested `item.missing_data` branch:** `FoodCatalog.get_item()` had no directory seam to exercise the `item.missing_data` degradation path without deleting shipped `.tres` files.
5. **`CoinTicketHud` Law of Demeter & `ProgressManager` reward constants:** `CoinTicketHud.refresh()` reached into `_manager.get("data")` instead of calling `get_coins()` / `get_tickets()` on `ProgressManager`, and `ProgressManager.complete_cycle()` used inline magic numbers `5` and `1`.
6. **Spec drift and `audit-code` 300-line / 20-line advisories:** `EXPLICIT_STATE_MACHINES.md` §1 listed `SWAPPING: 1.0s` instead of `2.0s`, and 6 test files plus several functions exceeded the 300-line file / 20-line function ceilings noted in the `e03` audit advisories.

**Security impact:** LOW — no security exploit path identified (input hygiene and defensive pre-`_ready` / missing-resource degradation).

## Root Cause Analysis (4-Phase `diagnose-root`)

- **Reproduce:**
  1. Stepping `KitchenScene` by `advance(2.1)` in `CHEWING` or `PLEASURE` emits 0 `fsm.dwell_exceeded` signals and writes no `fsm.dwell_timeout` diary entry.
  2. Sending an `InputEventMouseButton` with `button_index = MOUSE_BUTTON_RIGHT` to `QuiQuiRig._gui_input` increments `rig.taps`. Calling `QuiQuiRig.new().mouth_global_center()` before `_ready()` fails with a null-instance call on `mouth_zone`.
  3. Calling `FoodCatalog.get_item("carrot", "res://resources/foods/missing/")` is rejected at parse time because `get_item` accepts only `id`.
- **Isolate:** `cozinha.gd`, `quiqui_rig.gd`, `scene_manager.gd`, `food_catalog.gd`, `progress_manager.gd`, `coin_ticket_hud.gd`, and `specs/tech-architecture/EXPLICIT_STATE_MACHINES.md`.
- **Hypothesize:** Story-scoped audits recorded non-blocking advisories as "accepted" or "drift left alone" rather than closing them in-place.
- **Verify:** Each root cause is directly confirmed in the source and reproduced by unit/integration tests.
- **Risk level:** Low.

## TDD Fix Plan

1. **RED:** Add tests for:
   - `KitchenScene` logging `fsm.dwell_timeout` when a single step exceeds 2.0 s in `CHEWING` or `PLEASURE`.
   - `QuiQuiRig` ignoring non-left mouse buttons (`MOUSE_BUTTON_RIGHT`) and returning `global_position` safely when `mouth_global_center()` is called before `_ready()`.
   - `FoodCatalog.get_item("carrot", "res://resources/foods/missing/")` returning `null` and logging `item.missing_data`.
   - `ProgressManager.get_coins()` / `get_tickets()` and `CYCLE_COINS_REWARD` / `CYCLE_TICKETS_REWARD`.
   **GREEN:** Implement the minimal fixes in `cozinha.gd`, `quiqui_rig.gd`, `scene_manager.gd`, `food_catalog.gd`, `progress_manager.gd`, and `coin_ticket_hud.gd`.
   **verify:** `godot --headless --path game -s addons/gut/gut_cmdln.gd -gexit`
2. **REFACTOR:** Update `specs/tech-architecture/EXPLICIT_STATE_MACHINES.md` (`SWAPPING: 2.0s`) and trim/split files and functions so every `.gd` file in `game/` is ≤ 300 lines and every function in `game/scripts/` and `game/tools/` is ≤ 20 non-comment/non-blank lines.
   **verify:** `bash scripts/preflight.sh`

## Acceptance Criteria

- [x] `KitchenScene.advance()` checks `fsm.check_dwell()` in `CHEWING` and `PLEASURE`.
- [x] `QuiQuiRig` ignores non-left mouse buttons and `mouth_global_center()` is safe before `_ready()`.
- [x] `SceneManager` has no redundant `_swapped` boolean flag.
- [x] `FoodCatalog.get_item` `item.missing_data` branch is covered by unit test.
- [x] `ProgressManager` exposes `get_coins()`, `get_tickets()`, `CYCLE_COINS_REWARD`, and `CYCLE_TICKETS_REWARD`, used by `CoinTicketHud`.
- [x] `EXPLICIT_STATE_MACHINES.md` matches `SceneManager.MAX_DWELL_SEC` (`2.0s`), and all `game/` `.gd` files are ≤ 300 lines.
- [x] All new and existing tests pass under `bash scripts/preflight.sh`.

## Resolution

**Fixed:** 2026-11-05
**Root cause confirmed:** Residual advisories from `e01`–`e03` audits were left as notes instead of being closed in code, tests, and docs.
**Fix applied:** Wired `fsm.check_dwell()` in `KitchenScene.advance()`; restricted `QuiQuiRig` mouse taps to `MOUSE_BUTTON_LEFT` and guarded `mouth_global_center()` before `_ready()`; removed redundant `_swapped` boolean from `SceneManager`; added directory seam to `FoodCatalog.get_item()` and tested `item.missing_data`; added `get_coins()`/`get_tickets()` and reward constants to `ProgressManager` for `CoinTicketHud`; updated `EXPLICIT_STATE_MACHINES.md`; split oversized test files so every `.gd` file in `game/` is ≤ 300 lines and every production/tool function is ≤ 20 lines.
**Hardening added:** Unit and integration tests covering `KitchenScene` dwell timeout, `QuiQuiRig` right-click filtering and pre-`_ready` `mouth_global_center()`, `FoodCatalog` `item.missing_data`, and `ProgressManager` getters.
**Evidence:** `bash scripts/preflight.sh` → GREEN.
