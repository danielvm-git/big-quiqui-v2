# Epic Audit — e05 (Closet & Accessories, DRESS scene)

<!-- story: e05s01 -->
<!-- story: e05s02 -->
<!-- story: e05s03 -->
**Flow:** `build-epic` steps 5–6 per story, plus the epic pass · **Date:** 2026-11-06
**Diff:** `epic/e05-closet-dress-scene` vs `main` (`7c49348`, `+ closet`, `+ e2e`, + this cleanup)
**Gate:** **PREFLIGHT GREEN** — 30 scripts, **361 tests, 1880 asserts** (epic start: 346 / 1807)

## Verdict

**PASS.** Three stories. Five threat findings closed, two of them HIGH (ids from the save; the face above
the clothes). One design bug found by the E2E rather than by the gate — recorded as finding 1 below.

## Per story

| Story | Delivered | Tests |
|---|---|---|
| e05s01 | `set_accessory`/`accessory_id`/`clear_accessories`, `AccessorySlots` maths, `ProgressManager.equip`/`equipped`/`dress`, `SaveData` slot consts | 8 |
| e05s02 | `SNAP_TO_SLOT` mode, `closet.tscn` (27 nodes), 4 outfits + 6 accessories, pop SFX, sparkle burst, DRESS credited once | 10 |
| e05s03 | touch-driven journey per canvas, expression invariant, disk round-trip, replay, abandon | 5 |

## Threat findings

| ID | Status | Evidence |
|---|---|---|
| T-E05-01 ids from the save | **closed** | `test_an_invalid_accessory_is_refused_and_changes_nothing`, `test_an_invalid_equip_is_refused`, and the pre-existing load-drop test with `"head": "../../etc"` |
| T-E05-02 DRESS credited once | **closed** | `test_equipping_credits_dress_once_and_moves_on`, `test_replaying_the_same_outfit_credits_nothing_more` |
| T-E05-03 face above the clothes | **closed** | `test_the_expression_layer_sits_above_outfit_and_accessories` + the invariant asserted on `2048x1536` in the E2E |
| T-E05-04 corrupt save | **closed** | load drops invalid slots/ids; the room mounts with the default look |
| T-E05-05 one item per slot | **closed** | `test_a_second_accessory_replaces_the_first_in_its_slot` |
| T-E05-06 mouth zone stays clear | **closed by construction** | placement is derived from the mouth zone plus each item's own half-height, so the invariant is arithmetic, not tuning; asserted in the same test as T-E05-03 |
| T-E05-07 log on equip only | **closed** | `dress.equip` fires once per successful drop; no per-motion event exists in this gesture |

## Epic-level checks

| Section | Result | Note |
|---|---|---|
| Strict typing / type gate | **PASS** | 63 files |
| Fsm discipline | **PASS** | one `DRESSING -> FINISHED` machine; loop and scene machines watched in the E2E |
| Touch / echo | **PASS** | all three modes are now live; `_drop` split into `_consume`/`_snap` for the fourth |
| Layout contract | **PASS** | `STEP_ROOM_SPEC` on both canvases |
| Tests (F.I.R.S.T.) | **PASS** | 23 new tests; two of them exist because the first draft failed |
| Network / PII | **PASS** | no HTTP/WebSocket/`OS.shell`; L3 green |
| Story tags | **PASS** | every new `.gd` tagged |
| Functions ≤ 20 lines | **PASS for this epic's files** | `set_accessory` 25 → 20 + `_equip_accessory`; `_place_accessory` 21 → 12; `_drop` 28 → 11 + `_consume`/`_snap` |

### Findings fixed in this pass

1. **The closet refused every equip after DRESS was credited.** `_on_snapped` gated on
   `fsm.state == DRESSING`, and `_credit_dress` moves the machine to `FINISHED` — so the second item in the
   same visit silently did nothing. A child who dresses her and then adds a hat got nothing, with no error.
   Found by the E2E (`accessory_id("head") == ""`), not by the gate: the unit tests each equipped one item.
2. **Three functions over the 20-line bar** introduced by the accessory work, all split.
3. **`AccessorySlots` extracted** from `QuiQuiRig` (vocabulary, sizes, clearance maths): pure functions of
   the mouth zone and the art, testable without a scene. That is also what makes T-E05-06 arithmetic.

### Accepted debt

- **`quiqui_rig.gd` 423 lines** (300 guideline; 343 before this epic). The accessory API and its docs live
  there now. Trigger unchanged and now overdue-adjacent: **e10** splits body/outfit layers — and if a
  fourth consumer arrives before that, the hull maths moves to `ScrubHull` the way the accessory maths
  moved to `AccessorySlots`.
- **`touch_draggable.gd` 331 lines** (296 before this epic): four modes in one component. The split that
  will be right is one strategy object per mode, but with `FREE_PLACEMENT` still unimplemented (e09) the
  interface would be speculative. Trigger: e09, when the fourth mode lands.
- Pre-existing long functions outside this epic (log `_build_line` 21, save_data `to_dictionary` 26 /
  `clamp_to_rules` 64, two builders' `_add_bubble`/`_add_dots` 21–22) — unchanged, recorded.

### Notes

1. **Shipping `closet.tscn` made the hub's DRESS door navigate**, the third time a new scene changed its
   neighbour. The e03-era test shrank to `PLAY`/`SLEEP` and a new test asserts the dress door fires once.
   This is now a pattern worth naming: *adding a scene is an integration change*.
2. **One canvas per E2E test.** The loop and the SceneManager are singletons; a `for canvas` loop carried
   state between mounts and the second canvas was silently testing the first. Split into two tests.
3. **`bg_quarto` stands in for a closet background** — the art set has no `bg_closet.jpg`. Recorded so the
   art pass knows this is a placeholder rather than the intended composition.

## Traceability

`bash scripts/trace-stories.sh --strict` → PASS. `e05s01..s03` referenced from their specs, task files and
`specs/benchmarks/e05.yaml`.
