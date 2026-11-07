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
4. **`GeometryOracle` (`res://tests/helpers/geometry_oracle.gd`)** — the caller mounts the scene in a
   `SubViewport` of the target size and passes a **spec**; the oracle never resizes the window:
   - **Scene root** rect equals the canvas (a packed `size` on a `FULL_RECT` root grows it to 2x — BUG-001).
   - **Background** `TextureRect` *equals* the canvas in both directions: smaller is letterbox bars, larger
     is an oversized root zooming the art (BUG-001/F18). `STRETCH_KEEP_ASPECT_COVERED` is required.
   - **Hit targets**: every node in `hit_target` is ≥ `120×120` and inside the canvas.
   - **Rig height and feet** are measured on `QuiQuiRig.get_visual_global_rect()` — the union of the
     visible sprites' **opaque** pixels, not the `Control` box and not the 1024×1024 texture frame
     (BUG-013). A box keeping > 3 % of the canvas height as dead space above the art is a finding.
   - **Fails closed**: a node in the `rig` group that is not a `Control`, or a rig that cannot report
     painted geometry (missing/renamed art, unreadable image), is a *finding* — never a silent fall back
     to the box. `opaque_rect()` returning empty logs `rig.opaque_unreadable`.
   - **`required_groups`**: a spec may name the groups its scene type must declare; an empty one is a
     finding, so a scene cannot opt out of its own gate by forgetting `add_to_group`.
   - **Rig child zones** (`MouthZone`, `ScrubHull`, foam blobs, accessories) lie inside
     `get_visual_global_rect()` (TEST_PLAN §1.4).

   Specs are per scene type, declared where they are asserted:

   | Spec | Scene type | Groups asserted |
   |---|---|---|
   | `CARE_ROOM_SPEC` | hub (`casa`) | rig + dots (`ui_bottom`) + HUD (`ui_top_right`) |
   | `STEP_ROOM_SPEC` | task rooms (`cozinha`, e04–e10 steps) | rig |
   | `TITLE_SPEC` | `titulo` | rig |

## 2. Per-Epic Vertical Slice Gate
Every epic `e01`..`e10` MUST pass:
- **L0 Static Gate:** `gdlint game/ && gdformat --check game/`
- **L1 Unit & Property Gate:** `Fsm` legal edges, idempotency, and `SaveData` round-trip (`save -> reset_ram -> load == original`).
- **L2 Scene Integration Gate:** Boot the epic's playable `.tscn`, drive the complete user interaction via `TouchSim`, assert state transition via `FsmProbe`, and assert dual-aspect layout via `GeometryOracle`.
- **L3 Observability & Privacy Gate:** `bash scripts/logs.sh audit --self-test` exits `0`.
- **L4 Traceability Gate:** `bash scripts/trace-stories.sh --strict` exits `0`.
- **L5 Benchmark Conformance Gate:** the mechanical subset of
  `specs/product/TUTOTOONS_REFERENCE.md` — see §3.

## 3. Benchmark Conformance Gate (all playable scenes)

The reference benchmark (`specs/product/TUTOTOONS_REFERENCE.md`) measured five TutoTOONS titles on the
same 4:3 canvas. Its **mechanical** findings are gated; its observational ones are review criteria.
A scene earns green only when every row below passes on `1920×1080`, `1920×1440` and `2048×1536`:

| # | Assertion | Where | Benchmark source |
|---|---|---|---|
| 1 | Scene root rect == canvas | `GeometryOracle` root check | BUG-001 class; every measured frame is full-bleed |
| 2 | Painted character 55–65 % of height, feet on the spec line, horizontally centred | `GeometryOracle` + `get_visual_global_rect()` | hero frames measured 55–65 % |
| 3 | Wish/state bubble anchored to the head line, never overlapping the character | `GeometryOracle` `wish_bubble` group + the scene's clearance test | every measured title anchors it to the head |
| 4 | Interactive targets ≥ 120×120 px and inside the canvas | `GeometryOracle` hit-target check | their chrome is 76–96 px — we are deliberately stricter |
| 5 | Top-right HUD and bottom strip within 36 px of their edges | `GeometryOracle` `ui_bottom` / `ui_top_right` | their insets are 7–19 px — we are deliberately stricter |
| 6 | No text node carries play meaning | the scene's `test_the_scene_has_no_text` | zero text in any measured gameplay frame |

A new scene starts by declaring groups (`rig`, and `wish_bubble`/`ui_*` as its type requires), passing
its spec to `GeometryOracle`, and adding the clearance test. It is not green until `preflight.sh` passes.

## 4. Declined benchmark patterns (do not "fix" us toward these)

| Pattern | Measured | Why declined |
|---|---|---|
| Multi-character rooms with depth scaling (15–44 % heights) | Fluvsies 4 pets, Dopples 16 characters | our slice is a single-hero care loop; revisit only if e10 minigames put friends on screen |
| Chrome buttons of 76–96 px (`px@1080`) | Fluvsies rail 96, Smolsies/Dopples/SBG 76–86 | our 120 px floor is for 4–7-year-olds, who miss small corner targets |
| HUD inset of 7–19 px | all four room frames | 36 px costs nothing and the top strip is the most mis-tap-prone region |
| Flat dark-outline art | Dopples | our art direction is glossy, 3D-shaded, no pure-black outlines (`DESIGN.md`) |

Recorded here so a future review does not flag our stricter numbers as divergence from the benchmark,
and so a future "alignment" pass does not quietly adopt them.

## 5. e08 — Vila, recycling, wheel (added by the e08 post-epic review)

| Scenario | Test |
|---|---|
| SC-E08-P0-01..05 hub, POIs, escalation | `test_vila_scene.gd` |
| SC-E08-P0-07..10 recycle, hint, miss, cosmetic juice | `test_vila_recycling.gd` (+ per-session earn, BUG-039) |
| SC-E08-P0-12..16 wheel layout, spend, double-tap, badge | `test_roda_scene.gd` |
| SC-E08-P1-15 seeded replay and variety | `test_seeded_spins_replay_and_vary` |
| SC-E08-P0-18..20 economy never negative, interleave | `test_economy_properties.gd` |
| Home locked mid-spin, cost floor, badge log once | `test_roda_scene.gd` (BUG-038, 044, 042) |


## 6. e09 — Store, casinha, party (added at the e09 epic close)

| Scenario | Test |
|---|---|
| SC-E09-P0-01..02 twelve catalog pieces, no path from outside text | `test_furniture_catalog.gd` |
| SC-E09-P0-03..04 atomic purchase, no overdraw, no double charge, reload | `test_furniture_purchase.gd` |
| SC-E09-P0-05..07 store layout, one debit per tap, sold badge, poor tap | `test_mercado_scene.gd` |
| SC-E09-P0-01..03 FREE_PLACEMENT keeps the piece, clamp, other modes unchanged | `test_touch_draggable_placement.gd` |
| SC-E09-P0-05..06 placements are owned-only, normalized, and reload | `test_furniture_placement.gd` |
| SC-E09-P0-04..06 casinha restores, drag persists, unowned absent | `test_casinha_scene.gd` |
| SC-E09-P0-01..04 party threshold, re-lock, deterministic bob | `test_festa_scene.gd` |
| SC-E09-P1-06..07 DoorBadge follows `progress_changed`; every Vila door opens | `test_door_badge.gd`, `test_vila_scene.gd` |
| SC-E09-P0-01..03, P1-05..06 cross-canvas ratio oracle (and that it can fail) | `test_placement_oracle.gd` |
| SC-E09-P0-04 epic walk: buy → place → re-mount → party still locked | `test_e09_epic_e2e.gd` |

**The oracle measures the painted centre, not the anchor box** — the same discipline `GeometryOracle`
adopted after BUG-013. `PlacementOracle` fails closed: an empty save is a finding ("nothing placed
proves nothing") and a test moves a piece by 10 % of the room to prove the oracle can fail (the e08
lesson, BUG-040).

## 7. e11s01/e11s02 — the invariant gate (pulled forward)

The 484 tests before this layer answered *"does this scene do what its story says?"*. These
answer *"can any tampered save, any random tap or any newly added scene reach a state the
model forbids?"* — the gap where all 54 earlier bugs lived. They run inside L1, so they are
merge-blocking; the seeds are fixed, so a failure reproduces exactly.

| Layer | Invariant | Where |
|---|---|---|
| INV-01 | `from_dictionary` is total; placements are owned-only, deduped, finite, in `0..1` | `unit/test_save_fuzz.gd`, `helpers/save_corpus.gd` |
| INV-02 | normalising twice == normalising once | `unit/test_save_fuzz.gd` |
| INV-03 | a refused mutation is invisible; one logical change, one write | `unit/test_persistence_invariants.gd` |
| INV-04 | price/weight/payout tables cover the catalogue; no zero price, no zero weight | `unit/test_economy_tables.gd` |
| INV-05 | the diary vocabulary is id-shaped, namespaced, live, and `msg` never carries prose | `unit/test_telemetry_vocabulary.gd`, `helpers/source_scanner.gd` |
| INV-06 | every `LEGAL_EDGES` table is closed; no undeclared target, no dead state | `unit/test_fsm_tables.gd` |
| INV-07 | every scene is a Control root filling the canvas, background covered, no word on screen, built by a tool | `unit/test_scene_contracts.gd` |
| INV-07b | every `res://` literal resolves; every texture decodes; every stream loads | `unit/test_asset_integrity.gd` |
| INV-08 | each oracle/auditor rejects a deliberately broken input | `integration/test_gate_can_fail.gd` |
| MBT-01 | seeded 500-step walk: economy bounds, care FSM legality, save reload every 25 steps | `integration/test_mbt_walk.gd` |
| FZ-01..03 | deterministic 3-finger stream; hub and step room survive 500/200 events | `integration/test_monkey_fuzz.gd`, `helpers/monkey_stream.gd` |

**What it found on its first run (all fixed, BUG-055..BUG-059):** a save loader that
crashed on `null` scalars, placements for furniture she never bought unlocking the party,
`NaN` ratios surviving `clampf`, an unpriced catalogue piece being free, and the bath voice
line pointing at `banho_…` while the shipped clip is `bath_…`.

**Two readings this gate deliberately does NOT take** (recorded so a review does not
"align" them upward): Labels may carry **numerals** (the store prices) but never words, and
`anchors_preset = 0` with explicit `anchor_right/bottom = 1.0` is accepted as FULL_RECT —
what matters is the rect the scene packs to, which `GeometryOracle` asserts at boot.
