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

## 6. Domain Model (ubiquitous language)

`model-domain` record — terms that a domain expert (the family) uses, and the one code
identifier each maps to. Source of truth for the glossary: `specs/product/GLOSSARY_LATEST.yaml`.

| Term (PT-BR) | Meaning | Code identifier | Never call it |
|---|---|---|---|
| Coelinha QuiQui | the protagonist rabbit | `QuiQuiRig` | "pet", "avatar" |
| Casa da QuiQui | indoor care hub | `CasaScene` (`casa.tscn`) | "home screen", "menu" |
| Ciclo de cuidado | FEED → BATH → DRESS → PLAY → SLEEP → CELEBRATE | `CareLoopManager` state names | "level" |
| Moedinha | soft currency | `SaveData.coins` | "money", "cash" |
| Bilhete da roda | wheel ticket | `SaveData.tickets` | "token" |
| Casinha | decoratable house in the village | `CasinhaScene` | "house" (reserved for Casa) |
| Vila QuiQui | outdoor economy hub | `VilaScene` (`vila.tscn`) | "map" |
| Balão de desejo | the wish bubble telling the child what QuiQui wants | `WishBubble` | "tooltip" |
| Nhami | the eating sound/word | `sfx_nhami` | "chomp" |
| Careta | facial expression overlay | `ExpressionOverlay` | "sprite", "face" |
| Diário | the local JSONL play diary | `Log` / `user://logs/` | "telemetry", "analytics" |

## 7. Entry points
| Entry point | What it is | Where |
|---|---|---|
| `game/project.godot` | the application: window, stretch mode, autoload order, input emulation | root of the Godot project |
| `game/scenes/titulo.tscn` | the first scene a child sees (Play → Casa) | shipped |
| `game/scenes/casa.tscn` | the hub: door table → `cozinha`, `banheiro`, `closet`, `jardim` | shipped |
| `scripts/preflight.sh` | the gate every change must pass | repo root |
| `scripts/setup.sh` | idempotent dev bootstrap | repo root |
| `game/tools/build_*_scene.gd` | scene builders; `.tscn` files are generated, never hand-edited | tooling |

## 8. Module map
| Module | Responsibility | Depends on |
|---|---|---|
| `scripts/autoloads/log.gd` | schema-validated JSONL diary, PII redaction | `core/log_sink.gd` (consumers) |
| `scripts/autoloads/progress_manager.gd` | typed save, atomic write, equip/dress | `resources/save_data.gd`, `core/ids.gd` |
| `scripts/autoloads/care_loop_manager.gd` | `IDLE→FEED→BATH→DRESS→PLAY→SLEEP→CELEBRATE` | `core/fsm.gd`, `core/care_steps.gd` |
| `scripts/autoloads/scene_manager.gd` | table-driven scene transitions, 1-slot pending queue, watchdog | `core/fsm.gd` |
| `scripts/autoloads/audio_manager.gd` | music crossfade, 8-channel SFX pool, voice ducking | engine only |
| `scripts/core/*` | `Fsm`, `Ids`, `CareSteps`, `FoodCatalog`, `LogSink`, `SquashSpring` | none (leaves) |
| `scripts/components/*` | `QuiQuiRig`, `TouchDraggable`, `TapButton`, `WishBubble`, `FoamBlob`, `GardenProp`, `BathRoomView`, `AccessorySlots` | `core/*` |
| `scripts/scenes/*` | one script per playable room; owns its `Fsm` and its devices | components, autoloads |
| `tests/helpers/*` | `GeometryOracle`, `TouchSim`, `FsmProbe`, `TestReset`, per-journey fixtures | components |

## 9. Data stores
| Store | Format | Location | Owner |
|---|---|---|---|
| Save | JSON, atomic `.tmp` rename | `user://progress.json` | `ProgressManager` / `SaveData` (ADR-005) |
| Diary | JSONL, one line per event | `user://logs/quiqui-<sid>.jsonl` | `Log` |
| Art / audio | imported Godot resources | `res://assets/**` | build |

No database, no remote store. Tests are isolated through `TestReset` (`user://test_progress.json`).

## 10. External services
**None, by construction.** No HTTP, WebSocket, telemetry or ads: `HTTPRequest`, `HTTPClient`,
`WebSocketPeer` and `OS.shell` never appear in `game/` — enforced by preflight (no-grep stage),
`scripts/health.sh` and CONVENTIONS' Never list. Releases are the only network participant and they run
in CI, not in the game.

## 11. Error handling conventions
| Situation | Convention |
|---|---|
| Autoload or manager missing | degrade silently through `LogSink` (never `get_node` without a null check on a path a test can run before `_ready`) |
| Missing art or audio | log `*.missing_art` with the **id**, keep the scene playable |
| Save read failure or corrupt file | fall back to defaults, log `save.load_failed`, never crash the room |
| Invalid id from disk | drop it at load (`Ids`), log once |
| State-machine violation | impossible by construction: `Fsm` has declared edges; an illegal call logs `fsm.illegal_transition` and the probe fails the test |

## 12. Contract and API shape
- **No public API.** The contract surface is internal: `Fsm` edges, signal names, and the save schema.
- Every signal carries typed arguments; every manager exposes `state_id()` for tests.
- Ids are `\A[a-z0-9_]{1,64}\z` (`Ids`) and are the only thing that may reach a `res://` path.
- The diary schema is fixed by the external auditor (`scripts/log_tool.py`), not by the game.
