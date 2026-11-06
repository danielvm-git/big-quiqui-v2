# Epic Audit — e04 (Bathroom BATH scene)

<!-- story: e04s01 -->
<!-- story: e04s02 -->
<!-- story: e04s03 -->
<!-- story: e04s04 -->
**Flow:** `build-epic` steps 5–6 per story, plus an epic pass · **Date:** 2026-11-06
**Diff:** `epic/e04-bathroom-bath-scene` vs `main` (`23dfef9`, `bcb67bb`, `36f86c0`, `bd4fae5`, + this
cleanup commit)
**Gate:** **PREFLIGHT GREEN** — 30 scripts, **340 tests, 1773 asserts** (epic start: 26 / 311 / 1441)

## Verdict

**PASS.** Four stories, four threat findings closed (T-E04-01, T-E04-02, T-E04-06, T-E04-07), one
refused (T-E04-05 as specified — see note 3), and the epic-level cleanup done in this pass.

## Per story

| Story | Delivered | Tests added |
|---|---|---|
| e04s01 | `CONTINUOUS_SCRUB` mode, `scrub_hull_local/global` derived from the opaque art, abort path, one owned loop | 12 |
| e04s02 | `banheiro.tscn`, `FoamBlob`, `BathScene` stage machine, 8 patches solved from the hull, 3 scented soaps | 9 |
| e04s03 | RINSE (showerhead + gota burst) and DRY (towel → `brilhando`), BATH credited once, abandon mid-stage | 5 |
| e04s04 | touch-driven journey on three canvases, containment before/after resize, no resurrection | 6 |

## Threat findings

| ID | Status | Evidence |
|---|---|---|
| T-E04-01 hull drift on resize | **closed** | probe: hull = painted − 2×12 px on `1920x1080`, `1920x1440`, `2048x1536`; `test_the_hull_follows_the_opaque_rect_on_every_canvas` |
| T-E04-02 skip / double credit | **closed** | `test_finishing_the_bath_credits_the_step_once`, `test_replaying_the_bath_after_the_step_is_free_play` |
| T-E04-03 diary flood | **closed** | `test_a_long_scrub_writes_as_much_as_a_short_one` (40 motions == 2 motions) |
| T-E04-04 gesture wedge | **closed** | `test_freeing_a_scrubbing_node_releases_the_owner`, `test_abort_stops_the_loop_and_releases_the_owner` |
| T-E04-05 SFX channel | **closed as designed** | one owned player, stopped on release/abort/`_exit_tree` (see note 3) |
| T-E04-06 abandon mid-stage | **closed** | `test_leaving_during_rinse_abandons_the_step_and_releases_the_devices`, `test_leaving_mid_journey_abandons_and_never_credits` |
| T-E04-07 resize mid-stage | **closed** | `test_a_resize_keeps_the_patches_inside_the_hull`, `test_a_resize_does_not_resurrect_soaked_patches` |

## Epic-level checks

| Section | Result | Note |
|---|---|---|
| Strict typing / type gate | **PASS** | 62 files, 0 failures |
| Fsm discipline | **PASS** | one stage machine; three machines watched by `FsmProbe` in the E2E |
| Touch / echo | **PASS** | every gesture in the E2E goes through `TouchSim.gui_event` |
| Layout contract | **PASS** | `STEP_ROOM_SPEC` on both aspects; patches asserted on three canvases |
| Tests (F.I.R.S.T.) | **PASS** | 32 new tests, no vacuous assertion: each was mutated or observed RED first |
| Network / PII | **PASS** | no HTTP/WebSocket/`OS.shell`; L3 green |
| Story tags | **PASS** | every new `.gd` carries `# story: e04sNN` |
| Functions ≤ 20 lines | **PASS for this epic's files** | `build_banheiro_scene.gd` had `_init` 27, `_add_device` 31, `_add_sponge` 23 — all split here |

### Findings fixed in this pass

1. **`build_banheiro_scene.gd` had three functions over the 20-line bar** (`_init` 27, `_add_device` 31,
   `_add_sponge` 23). Split into `_make_root`, `_add_background`, `_add_particles`, `_pin_device`,
   `_framed_art`. 247 → 246 lines but six functions where three were.
2. **`banheiro.gd` was 357 lines.** The geometry half moved to `BathRoomView` (slots, projection,
   containment, device arming, tint) as pure static functions — testable without a scene. Now 326.

### Accepted debt

- **`banheiro.gd` 326 lines** (300 guideline). The remaining half is a stage machine: SOAP/RINSE/DRY
  wiring, devices, audio, home. Splitting it further would give one room two owners. Trigger: e07 adds
  the SLEEP stages to this pattern, so the stage machine becomes shared and should move out then.
- **`quiqui_rig.gd` 343 lines**, unchanged position from e04s01's audit: layout + hull + animation in
  one Control, trigger still e10 (separate body/outfit layers).
- **Pre-existing long functions outside this epic** (`save_data.gd clamp_to_rules` 64,
  `to_dictionary` 26, `log.gd _build_line` 21, `build_casa_scene.gd _add_bubble` 22 / `_add_dots` 21,
  `build_cozinha_scene.gd _add_bubble` 21). Not introduced here and not touched here; recorded so the
  next audit does not re-discover them as new.

### Notes

1. **The bath room is a STEP room**, so its oracle spec is `STEP_ROOM_SPEC`: no dots bar, no HUD, like
   the kitchen. The first run failed on `CARE_ROOM_SPEC` wanting `ui_bottom`, which is the gate doing
   its job.
2. **Shipping `banheiro.tscn` changed the hub's behaviour**: the BATH door navigates now. The e03-era
   test was narrowed to `DRESS`/`PLAY`/`SLEEP` and a new test asserts the bath door fires once.
3. **T-E04-05 deliberately did not add a loop-channel API to `AudioManager`.** The scrub owns one
   player on the SFX bus; promoting that to the manager for a single consumer would be speculative. If
   e05–e10 need looping SFX, promote it then — recorded in the threat model's mitigation column.
4. **Two test-side facts worth keeping**: a single drag pass starts on the device, so only its last
   steps are on her body (the sweep is three alternating passes); and the `Fsm` logs its own
   transitions, so "no diary flood" is asserted as motion-independence, not as a magic line count.

## Traceability

`bash scripts/trace-stories.sh --strict` → PASS. `e04s01..s04` are referenced from their spec, their
task file and `specs/benchmarks/e04.yaml` (`EV-E04-01..04`).
