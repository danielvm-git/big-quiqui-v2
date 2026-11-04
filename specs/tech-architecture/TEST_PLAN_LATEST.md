# Test Architecture & 9-Layer Pyramid (`TEST_PLAN_LATEST.md`)

<!-- story: e01s01 -->

## 1. Core Test Helpers (Built in Epic `e01`)
1. **`TestReset` (`res://tests/helpers/test_reset.gd`)**:
   - Redirects `ProgressManager` save path to `user://test_progress.json` and deletes it before/after each test.
   - Resets `CareLoopManager`, `SceneManager`, and `AudioManager` to clean `IDLE` states.
2. **`FsmProbe` (`res://tests/helpers/fsm_probe.gd`)**:
   - Attaches to any `Fsm` instance and asserts zero `fsm.illegal_transition` and zero `fsm.dwell_timeout` events.
3. **`TouchSim` (`res://tests/helpers/touch_sim.gd`)**:
   - `tap_control(control, with_mouse_echo = true)`: pushes `InputEventScreenTouch(pressed=true)` + synthesized `InputEventMouseButton(device=-1)` + release.
   - `drag_control_to(control, target_global_pos, steps = 12, with_mouse_echo = true)`: simulates smooth finger drag across `Viewport.push_input`.
4. **`GeometryOracle` (`res://tests/helpers/geometry_oracle.gd`)**:
   - Resizes root viewport to `1920×1080` (16:9) and `2048×1536` (4:3 iPad) and asserts:
     - Background `TextureRect` covers 100% of viewport rect.
     - All interactive buttons/draggables have `size.x >= 120` and `size.y >= 120` and lie strictly within the visible viewport.
     - All `QuiQuiRig` child zones (`MouthZone`, `ScrubHull`, foam blobs, accessories) lie strictly within `QuiQuiRig.get_visual_global_rect()`.

## 2. Per-Epic Vertical Slice Gate
Every epic `e01`..`e10` MUST pass:
- **L0 Static Gate:** `gdlint game/ && gdformat --check game/`
- **L1 Unit & Property Gate:** `Fsm` legal edges, idempotency, and `SaveData` round-trip (`save -> reset_ram -> load == original`).
- **L2 Scene Integration Gate:** Boot the epic's playable `.tscn`, drive the complete user interaction via `TouchSim`, assert state transition via `FsmProbe`, and assert dual-aspect layout via `GeometryOracle`.
- **L3 Observability & Privacy Gate:** `bash scripts/logs.sh audit --self-test` exits `0`.
- **L4 Traceability Gate:** `bash scripts/trace-stories.sh --strict` exits `0`.
