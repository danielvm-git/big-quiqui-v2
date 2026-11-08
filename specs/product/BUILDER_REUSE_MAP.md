# Builder reuse map — what survives the restart, what replaces the 17 scenes

<!-- story: e12s01 -->

**Purpose:** before slicing the `quiqui_builder_restart` backlog (`specs/product/SCOPE_LATEST.yaml`), record
exactly which existing code is reused as-is, which is reused with a change, and which is deleted — with
the code evidence. Written from the tree at scope time (Godot 4.7, 606 GUT tests green, 77 test scripts).

Sources of the design: `QUIQUI_BUILDER_DESIGN.html` (layers, primitives, 44-template table) and
`TUTOTOONS_ARCHITECTURE.html` (what is common, the three game-layer forms).

---

## 1. Verdict in one table

| Region of the tree | Verdict | Why |
|---|---|---|
| `game/scripts/autoloads/` (5 singletons) | **keep**, 3 need a change | Log, AudioManager, ProgressManager, CareLoopManager are layer-0/L4 services the design keeps. Only `SceneManager` changes shape: it must open one player instead of 17 `.tscn`. |
| `game/scripts/core/fsm.gd` | **keep as-is** | Already the rule table the design asks for. StepRunner and every template instantiate it; nothing about it is scene-specific. |
| `game/scripts/components/` (17 files) | **10 keep, 7 die** | The 7 that exist only to serve one hand-built room (`BathRoomView`, `FoamBlob`, `GardenProp`, `IceLane`, `CatchItem`, `PuzzlePiece`, `FurnitureProp`) are template internals in the new model, so they become data-driven or disappear. |
| `game/scripts/core/*_catalog.gd`, `*_data.gd` | **keep** | Food/economy/furniture catalogs and the id contract are content, not scene plumbing. Only the path tables inside `SceneCatalog`, `PoiTable`, `FriendCatalog` switch from paths to ids. |
| `game/scripts/resources/` | **keep** | `SaveData`/`ItemData`/`FurnitureData` are the save and content contract. No change. |
| `game/scripts/scenes/*.gd` (17) | **delete** | Replaced by scene data (`SceneDef`) executed by one player. Each one's mechanic maps to a template; see §4. |
| `game/tools/build_*_scene.gd` (17) | **delete** | 17 generated `.tscn` files become 1. See §5. |
| `game/tools/scene_builder.gd` | **keep** (one builder still needs it) | `pin()` / `pack_and_save()` are exactly how the single player scene should be authored. |
| `game/scenes/*.tscn` (17) | **delete** | `find game/scenes -name '*.tscn'` must return exactly one file after migration. |
| `game/tests/**` (77 scripts) | **keep the framework, re-point the scene tests** | `TouchSim`, `FsmProbe`, `GeometryOracle`, `TestReset`, `MonkeyStream`, `SaveCorpus` are asset-value; ~17 per-scene integration tests assert node trees that no longer exist. |

---

## 2. The five autoloads

| Autoload | Reuse | Change the restart forces |
|---|---|---|
| `Log` (+`core/log_sink.gd`) | **as-is** | Nothing. New event ids only (`step.started`, `step.done`, `hint.shown`, `template.*`). Keys stay `lvl/ts/ev/seq/session/t_ms` and msg stays an id (BUG-004). |
| `AudioManager` | **as-is, plus a resolver** | `play_voice(stream)` takes a stream, so `vo.kitchen.intro` needs a key→path step. Its music crossfade, 8-channel SFX pool and `-9 dB` ducking are exactly what the reaction vocabulary needs. |
| `ProgressManager` | **as-is** | Coins/tickets/stars/equipped/placed already cover the reward layer. If a scene needs to remember "done today", it is a new `SaveData` field — version bump + migration per ADR-005, not an edit. |
| `CareLoopManager` | **as-is** | The five-step loop sits *above* the player and is untouched. The player reports `complete_step(step)`; the door dimming and the detour guard keep working. |
| `SceneManager` | **keep the machine, change the target** | Its FSM (`IDLE→FADING_OUT→SWAPPING→FADING_IN`), curtain, watchdog, pending slot and rejection codes are all still right. What changes is *where the swap points*: see §6. |

---

## 3. Components: 10 survive, 7 die

| Component | Lines | Now used by | Verdict |
|---|---|---|---|
| `touch_draggable.gd` | 326 | 29 files | **Keep.** Its four modes are already the design's gestures: `CONSUME_ON_DROP` = Give→Receive single, `SNAP_TO_SLOT` = slots, `FREE_PLACEMENT` = free_place, `CONTINUOUS_SCRUB` = Rub motor. Grandfathered at 326 lines — **may not grow**, so primitives wrap it. |
| `scrub_gesture.gd` + `scrub_loop.gd` | 56 + 32 | touch_draggable | **Keep.** Owns the hull test, the point count and the one loop channel; that *is* the Rub progress counter. |
| `quiqui_rig.gd` | 427 | 45 files | **Keep.** Body/outfit/expression composition, `tapped`, `set_expression`, `mouth_global_center()`, `scrub_hull_global()` are the anchors every template targets. Grandfathered at 427 — **may not grow**; the player targets it through those methods. |
| `wish_bubble.gd` | 202 | 15 files | **Keep.** Already has `set_urgency(0..2)` and pulses harder per level — the TutoTOONS `ReachedQuarter/ReachedHalf` escalation, half-built. |
| `coin_ticket_hud.gd` | 183 | 21 files | **Keep.** Listens to `progress_changed`, never writes. Reaction **coins** fly from here. |
| `tap_button.gd` (+`squash_spring.gd`) | 103 | 36 files | **Keep.** The Tap primitive's target and the "instant answer" feel. |
| `hint_manager.gd` | 57 | 7 files | **Keep.** Queue + `begin_cooldown` is already the TutoTOONS `HintManager` discipline. Needs one addition: the *trigger* (show after ~3 s without input) moves from the scene into the hint layer. |
| `drag_hint.gd` | 74 | 7 files | **Keep, upgrade.** It is the ghost hand (`Utility.HintHand`) but draws a pink `ColorRect`, not a hand, and is hardwired to one from→to. It must take (source rect, target rect) from step data. Art gap: no hand sprite exists (see scope, out_of_scope). |
| `care_dots_bar.gd` | 65 | 3 files | **Keep, re-source.** It mirrors `CareLoopManager.completed_steps()` (the 5-step loop). The player needs *step* dots (n of N inside a room). Same widget, new source — an adapter, not a fork. |
| `accessory_slots.gd` | 37 | quiqui_rig | **Keep.** Rig internal, unchanged. |
| `bath_room_view.gd`, `foam_blob.gd` | 86 + 44 | banheiro only | **Die.** Foam patches become a Rub target with a data-defined patch list (`t40_draw_fill` / `t23_erase`). |
| `garden_prop.gd` | 100 | jardim only | **Die.** Toys become `t21_touch_each` objects with ids and reactions. |
| `ice_lane.gd`, `catch_item.gd` | 23 / 30 | pinguim only | **Die** (or become the internals of `t50_lanes` in wave 3). |
| `puzzle_piece.gd` | 100 | urso only | **Die.** The 4 pieces become `t20_drag_snap` slots + pieces. |
| `furniture_prop.gd` | 39 | casinha only | **Die.** Placement is `t45_dress_decorate` free_place; `ProgressManager.place_furniture` already stores ratios. |
| `door_badge.gd` | 57 | **nothing** | **Already dead.** Zero references outside its own test. Delete on the first touching story. |

---

## 4. The 17 scene scripts → scene ids + templates

Every row is "what the room *is*" expressed as data. `template` comes from the wave table in
`QUIQUI_BUILDER_DESIGN.html`; `wave` is when that template exists in the library.

| Today (`*.gd` / `*.tscn`) | New scene id | Templates | Wave | Note |
|---|---|---|---|---|
| `titulo.gd` | `title` | t0_title | 1 | one glowing Play target |
| `casa.gd` | `home` | t25_map (doors as tap targets) | 1 | the hub is a map, not a special scene |
| `cozinha.gd` | `kitchen` | t20_drag_snap | 1 | **first slice**; the room that proves the loop |
| `banheiro.gd` | `bathroom` | t40_draw_fill (soap) + t23_erase (rinse) + t23_erase (dry) | 1 | 3 steps, 2 templates |
| `closet.gd` | `closet` | t45_dress_decorate | 1 | scrolling categories + slot snap |
| `jardim.gd` | `playroom` | t21_touch_each | 1 | "three distinct toys" is a step rule, not code |
| `quarto_sono.gd` | `bedroom` | t21_touch_each | 1 | lamp + plush in any order |
| `celebracao.gd` | `celebration` | t32_reward | 1 | payment stays in `CareLoopManager`, not in the scene |
| `urso_puzzle.gd` | `bear_puzzle` | t20_drag_snap (slots) | 1 | 4 pieces, ghost slots |
| `vila.gd` | `village` | t25_map + t20_drag_snap (recycling) | 1 | POI table becomes an id table |
| `casinha.gd` | `playhouse` | t45_dress_decorate (free_place) | 1 | |
| `festa.gd` | `party` | t22_play_beat + t21_touch_each | 1 (needs the T22 decision) | party opens when pieces are placed |
| `roda.gd` | `wheel` | t51_prize_pick | **2** | depends on a wave-2 template |
| `mercado.gd` | `market` | t21_touch_each + coin gate | 1 | price table untouched (`EconomyData`) |
| `pinguim_jogo.gd` | `penguin_lanes` | t50_lanes | **3** | depends on wave 3 (Steer) |
| `pato_danca.gd` | `duck_dance` | `t_rhythm_pose` (custom slot) | 1b | no TutoTOONS template; id settled in D5 |
| `album.gd` | `album` | `t_album` (custom slot) | 1b | collection screen; no template in TutoTOONS; id settled in D5 |

**Ordering constraint (open as D6):** with the old layer removed in a single commit at the end of the
migration (D1a), every room must be converted first — but `wheel` needs t51_prize_pick (wave 2) and
`penguin_lanes` needs t50_lanes (wave 3). Either those two templates pull forward into wave 1b, or the
removal commit moves to the end of wave 3. The care day itself (title → home → feed/bath/dress/play/sleep
→ celebration) plus `playhouse`, `party`, `market` and the two custom slots is entirely wave-1+ and
migratable inside e14.

---

## 5. The 17 builders → one builder

Today each room has a `build_*_scene.gd` (~100–260 lines) that constructs a node tree in code, pins nodes
as canvas ratios (`SceneBuilder.pin`, ADR-008) and packs it to `.tscn`. That duplication exists because a
`.tscn` cannot describe a scene whose layout is content.

After the restart:

| Now | After |
|---|---|
| 17 × `build_<room>_scene.gd` | `build_scene_player_scene.gd` — builds `res://scenes/scene_player.tscn` once: background layer, `QuiQuiRig`, tray zone, hint layer, HUD, home button, step dots. |
| 17 × `res://scenes/<room>.tscn` committed | 1 × `res://scenes/scene_player.tscn` committed |
| room layout in builder constants | room layout in `SceneDef`/`StepDef` `.tres` (`res://data/scenes/<id>.tres`) |
| nothing | `SceneBuilder.pin/pack_and_save` reused unchanged by that one builder |

The CONVENTIONS rule ("hand-edit no generated files; change the builder, regenerate, commit both") keeps
its full force — there is simply one generated scene instead of seventeen.

---

## 6. How navigation changes: `SceneManager` opens the player, not a room

**Today** (`game/scripts/autoloads/scene_manager.gd`):

```gdscript
func request_scene(path: String) -> bool      # ".../scenes/cozinha.tscn"
    _close_celebrate_for_detour(path)         # compares CASA_PATH / CELEBRACAO_PATH
    ...                                       # same FSM, curtain, watchdog, pending slot
func _swap_production(path: String) -> void
    get_tree().change_scene_to_file(path)     # <- the one room, by file path
```

**After:**

```gdscript
func request_def(id: String) -> bool          # "kitchen" — validated against Ids.PATTERN
    # reject unknown id, same-id, busy -> pending (unchanged semantics)
    _current_def_id = id
    # the FSM, curtain, watchdog and pending slot are untouched
func _swap_production(_id: String) -> void
    get_tree().change_scene_to_file("res://scenes/scene_player.tscn")   # always the same file
```

The def itself cannot be passed as an argument — `change_scene_to_file` takes none and the swap is
deferred to the end of the frame — so `SceneManager` publishes it on the autoload
(`pending_def` / `current_def`, plus `consume_def()` which clears after the read so a reload cannot
silently reuse a stale def). `ScenePlayer._ready()` consumes it, loads
`res://data/scenes/<id>.tres` as a `SceneDef`, validates it, builds the room and starts `StepRunner`.

What else has to move with it:

| Artifact | Change |
|---|---|
| `SceneManager.CASA_PATH` / `CELEBRACAO_PATH` | become `ID_HOME` / `ID_CELEBRATION` (`_close_celebrate_for_detour` compares ids) |
| `SceneManager._slug(path)` | for an id it already yields `scene.kitchen`, so the diary vocabulary survives unchanged |
| `signal scene_changed(path)` | becomes `scene_changed(id)`; `test_scene_manager.gd` asserts `production_swap_path`, which becomes the player path — the test must assert *id + player path* |
| `core/scene_catalog.gd` | `ALL_PATHS: Array[String]` (17 `.tscn`) → `ALL_IDS: Array[String]` (17 ids) |
| `core/poi_table.gd` | `SCENES` maps POI → path → becomes POI → id |
| `core/friend_catalog.gd` | friend → minigame path → becomes friend → scene id |
| 4 test files + `gallery_capture.gd` | they `load(path).instantiate()` from `ALL_PATHS`; they must instantiate the player with an injected def (`ScenePlayer.def_override` set before `add_child`, same seam discipline as `manual_step`/`loader`) — this is the single biggest test-side change in the migration |
| `test_scene_contracts.gd` | asserts every shipped scene has a Control root at `PRESET_FULL_RECT`; the assertion moves to the player + a data-level check that every `SceneDef` id is valid |

**Why this keeps the green gate:** the state machine, curtain, watchdog, pending queue, rejection codes and
log ids are all reused verbatim. Only the *target resolver* and the payload channel are new, and both are
testable without touching the scene tree (`loader` / `production_swap` seams already exist).

---

## 7. Test surface impact

| Area | Now | After |
|---|---|---|
| Unit (76 scripts) | component-level: Fsm, rig, draggable, HUD, save, economy | **mostly keep**; add: `SceneDef` schema validation, `StepRunner` FSM tables, one unit test per template |
| Integration (~17 scene tests) | assert each room's node tree and pixel geometry | **replaced** by per-template tests + one player test + 17 data-driven scene tests (same `TouchSim`/`FsmProbe`/`GeometryOracle` helpers) |
| MBT / gallery / monkey fuzz | iterate `SceneCatalog.ALL_PATHS` | iterate `ALL_IDS`, instantiating the player per def — coverage becomes template coverage instead of scene coverage |
| Helpers (`TouchSim`, `GeometryOracle`, `MonkeyStream`, `TestReset`, `SaveCorpus`, `FsmProbe`) | — | **unchanged**; this is the durable part of the harness |

---

## 8. Reused, unchanged, and worth stating

- `game/scripts/core/save_file.gd`, `resources/save_data.gd`, `core/economy_data.gd`,
  `core/food_catalog.gd`, `core/furniture_catalog.gd`, `core/furniture_ledger.gd`, `core/care_steps.gd`,
  `core/ids.gd` — content, save and id contracts. **Zero changes.** The restart is a scene-shape change,
  not a data-model change.
- `scripts/log_tool.py`, `scripts/logs.sh`, `scripts/preflight.sh`, `scripts/traceability.py`,
  `.github/workflows/ci-cd.yml` — the observability and gate stack stays as it is; the new player logs
  through the same `Log` API.
- `CONVENTIONS.md` §3 (`Fsm`, Control roots, `device == -1` filter, 120 px targets) — the design's
  adaptation rules (no lives, no timers, no ads, instant answer) are enforced *inside the player*, so they
  are one code site instead of seventeen.
