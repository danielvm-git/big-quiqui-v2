# Technical Architecture & Stack (`tech-stack.md`)

<!-- story: e01s01 -->

## 1. Runtime & Engine
- **Engine:** Godot 4.7 (`config_version=5`, `Mobile` renderer for iPad Metal / desktop Vulkan compatibility).
- **Language:** GDScript 2.0 with mandatory static typing (`strict` warnings-as-errors in `gdlint`).
- **Display & Viewport:**
  - Base width/height: `1920×1080`
  - Stretch mode: `canvas_items`
  - Stretch aspect: `expand` (renders `1920×1440` logical canvas on `2048×1536` 4:3 iPad with zero letterbox bars).
  - Input: `pointing/emulate_touch_from_mouse = true` (with mandatory `device == -1` mouse-echo filtering in `TapButton` and `TouchDraggable`).

## 2. Autoload Singletons (Initialization Order)
1. **`Log` (`res://scripts/autoloads/log.gd`)**:
   - Schema-validated JSONL local session diary (`user://logs/quiqui-<ts>-<sid>.jsonl`).
   - Automatic PII redaction (`redact_pii`), `OS.add_logger` engine error/warning hook, `session.marker` crash detection.
2. **`ProgressManager` (`res://scripts/autoloads/progress_manager.gd`)**:
   - Owns a strongly-typed `SaveData` resource (`coins`, `tickets`, `equipped_outfits`, `owned_furniture`, `placed_furniture`, `friend_stars`, `completed_cycles`).
   - Atomic write (`user://progress.json.tmp` → `DirAccess.rename_absolute`).
   - Redirected by `TestReset` to `user://test_progress.json` during all GUT runs.
3. **`AudioManager` (`res://scripts/autoloads/audio_manager.gd`)**:
   - Programmatic 4-bus layout (`Master`, `Music`, `SFX`, `Voice`).
   - Music crossfading (`0.4 s`), 8-channel round-robin `SFX` pool, and `-9.0 dB` automatic music/SFX ducking while a `Voice` stream is playing.
4. **`SceneManager` (`res://scripts/autoloads/scene_manager.gd`)**:
   - Driven by `Fsm` (`IDLE -> FADING_OUT -> SWAPPING -> FADING_IN -> IDLE`).
   - Persistent `CanvasLayer` (`layer = 128`) fade curtain, `2.0 s` watchdog recovery timer, and 1-slot `_pending_scene_path` queue so rapid transitions are never dropped.
5. **`CareLoopManager` (`res://scripts/autoloads/care_loop_manager.gd`)**:
   - Driven by `Fsm` (`IDLE -> FEED -> BATH -> DRESS -> PLAY -> SLEEP -> CELEBRATE -> IDLE`).
   - Scene-detour safety hook: navigating away from `CELEBRATE` to `vila` or `album` automatically finalizes the cycle reward (`+5 Coins, +1 Ticket`) and transitions to `IDLE`.

## 3. Core Reusable Components
- **`Fsm` (`res://scripts/core/fsm.gd`)**: Table-driven finite state machine with `legal_edges`, `transition_from(expected, next)`, idempotent same-state no-op, `max_dwell_sec` watchdog, and automatic `Log.event("fsm.transition", ...)` telemetry.
- **`QuiQuiRig` (`res://components/quiqui_rig.tscn`)**:
  - Outer `Control` box for layout anchoring + inner foot-pivoted `Node2D` rig.
  - Visual stack: `BodySprite` → `OutfitSprite` → `ExpressionSprite` → `HeadwearSprite` → `NeckSprite` → `GlassesSprite`.
  - Local-space interaction regions: `MouthZone` (`Area2D`/`ReferenceRect`), `ScrubHull` (`Polygon2D`), `TickleZone`.
  - Single-owner `MotionController` with monotonic `_motion_token: int` and `_rest_transform` restoration.
- **`TouchDraggable` (`res://scripts/components/touch_draggable.gd`)**:
  - Four modes: `CONSUME_ON_DROP` (food/trash), `CONTINUOUS_SCRUB` (sponge/shower/towel), `SNAP_TO_SLOT` (puzzle), `FREE_PLACEMENT` (casinha furniture with normalized `0..1` coordinates).
- **`TapButton` (`res://scripts/components/tap_button.gd`)**:
  - Enforces `>=120×120 px` hit box, filters `device == -1` mouse echo, plays jelly squash-and-stretch + `tap.ogg`.
