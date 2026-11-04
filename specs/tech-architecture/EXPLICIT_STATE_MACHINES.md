# Explicit State Machines Catalog (`EXPLICIT_STATE_MACHINES.md`)

<!-- story: e01s02 -->

Every stateful subsystem in `big-quiqui-v2` is powered by `Fsm` (`res://scripts/core/fsm.gd`) and verified by `FsmProbe` (`res://tests/helpers/fsm_probe.gd`).

---

## 1. `SceneManager` Transition Machine (`fsm_id = "scene_manager"`)
- **States:** `IDLE`, `FADING_OUT`, `SWAPPING`, `FADING_IN`
- **Legal Edges:**
  - `IDLE -> [FADING_OUT]`
  - `FADING_OUT -> [SWAPPING, IDLE]`
  - `SWAPPING -> [FADING_IN, IDLE]`
  - `FADING_IN -> [IDLE]`
- **Max Dwell Deadlines:** `FADING_OUT: 2.0s`, `SWAPPING: 1.0s`, `FADING_IN: 2.0s` (watchdog forces `-> IDLE` and logs `fsm.dwell_timeout`).
- **Pending Target Queue:** If `change_scene(next_path)` is called while state is `FADING_OUT`, `SWAPPING`, or `FADING_IN`, `_pending_scene_path = next_path` is queued and executed upon reaching `IDLE`.

---

## 2. `CareLoopManager` Care Cycle Machine (`fsm_id = "care_loop"`)
- **States:** `IDLE`, `FEED`, `BATH`, `DRESS`, `PLAY`, `SLEEP`, `CELEBRATE`
- **Legal Edges:**
  - `IDLE -> [FEED]`
  - `FEED -> [BATH, IDLE]`
  - `BATH -> [DRESS, IDLE]`
  - `DRESS -> [PLAY, IDLE]`
  - `PLAY -> [SLEEP, IDLE]`
  - `SLEEP -> [CELEBRATE, IDLE]`
  - `CELEBRATE -> [IDLE]`
- **Invariants:**
  1. `complete_step(expected_state)` uses `fsm.transition_from(expected_state, next_state)`. Duplicate calls with the same `expected_state` after the transition has occurred return `false` (idempotent).
  2. Entering `CELEBRATE` immediately grants `+5 Coins` and `+1 Ticket` once per cycle ID so that any detour (`Album`, `Vila`, `Casa`) transitions `CELEBRATE -> IDLE` without losing rewards or soft-locking `CasaScene`.

---

## 3. `TouchDraggable` Gesture Machine (`fsm_id = "touch_draggable"`)
- **States:** `REST`, `DRAGGING`, `RETURNING`, `CONSUMED`
- **Legal Edges:**
  - `REST -> [DRAGGING]` (claims `_owner_touch_index`)
  - `DRAGGING -> [REST, RETURNING, CONSUMED]`
  - `RETURNING -> [REST, DRAGGING]`
  - `CONSUMED -> []` (terminal in `CONSUME_ON_DROP` mode)
- **Max Dwell Deadlines:** `RETURNING: 1.0s`

---

## 4. `BathScene` Activity Machine (`fsm_id = "bath_activity"`)
- **States:** `SOAP`, `RINSE`, `DRY`, `COMPLETE`
- **Legal Edges:**
  - `SOAP -> [RINSE]` (when `foam_spawned_count == 8`)
  - `RINSE -> [DRY]` (when `foam_remaining_count == 0`)
  - `DRY -> [COMPLETE]` (when `dry_progress >= 1.0`)
  - `COMPLETE -> []` (triggers `CareLoopManager.complete_step(BATH)`)

---

## 5. `WheelScene` Spin Machine (`fsm_id = "wheel_spin"`)
- **States:** `READY`, `SPINNING`, `REWARD_PRESENTATION`
- **Legal Edges:**
  - `READY -> [SPINNING]` (requires `ProgressManager.spend_ticket() == true`)
  - `SPINNING -> [REWARD_PRESENTATION]` (max dwell `5.0s`)
  - `REWARD_PRESENTATION -> [READY]` (max dwell `3.0s`)
