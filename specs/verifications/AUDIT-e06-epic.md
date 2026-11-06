# Epic Audit — e06 (Sunny Garden, PLAY scene)

<!-- story: e06s01 -->
<!-- story: e06s02 -->
<!-- story: e06s03 -->
**Flow:** `build-epic` steps 0–8 · **Date:** 2026-11-06 · **Branch:** `epic/e06-garden-play-scene`
**Gate:** **PREFLIGHT GREEN** — 34 scripts, **378 tests, 1969 asserts** (epic start: 361 / 1880)

## Verdict

**PASS.** Three stories, six threat findings closed, one new class of bug found and recorded.

## Per story

| Story | Delivered | Tests |
|---|---|---|
| e06s01 | `GardenProp` (BOUNCE/SPIN/SQUEEZE) with bounded motion, rest state, echo filter | 6 |
| e06s02 | `GardenScene`, `jardim.tscn` (14 nodes), interaction *set*, credit once, tickle zone | 7 |
| e06s03 | journey on both canvases, free-play replay, calm exit | 4 |

## Threat findings

| ID | Status | Evidence |
|---|---|---|
| T-E06-01 PLAY credited once | **closed** | `test_three_distinct_toys_finish_play_and_credit_once`, `test_replaying_the_garden_after_play_is_free_play` |
| T-E06-02 hub PLAY door changes | **closed** | `test_the_play_door_asks_for_the_garden_once`; the "doors stay pending" test is down to SLEEP |
| T-E06-03 no diary line per frame | **closed by design** | one `garden.play` per distinct interaction, one `garden.tickle` per tap; the motion writes nothing |
| T-E06-04 every prop settles | **closed** | `test_every_motion_settles_within_its_budget`, `test_a_resting_prop_does_not_drift_when_advanced` |
| T-E06-05 distinct interactions | **closed** | `test_replaying_one_toy_never_finishes_play` (four taps = one interaction) |
| T-E06-06 calm exit | **closed** | `test_leaving_mid_play_stops_the_toys_and_abandons` |

## The bug of this epic

**`PackedScene.pack` drops properties set on a scripted node before it enters the tree.** The first
builder assigned `kind` and `interaction` with `set()` right after `set_script()`, packed the scene, and the
`.tscn` came out with neither: all three toys loaded as the default `ball`/`BOUNCE`, so only one distinct
interaction could ever be recorded and PLAY could never be finished by three toys.

It surfaced as `played.size() == 1` with the loop stuck in PLAY — not as a crash, and not at build time.

The fix is also the better design: the catalogue lives in `GardenScene.PROPS` and is wired in `_ready`,
the way `ClosetScene` already wires its items. The scene file carries art and layout; behaviour lives in
the scene script. Recorded in the story spec and in the builder's comment so the next scene does not
repeat it.

### Findings fixed in this pass

- **`_add_props` was 21 lines**; split into `_add_props` + `_prop_node`.
- **The garden never asked for the Casa.** `_finish()` credited PLAY and stopped there, so the child was
  left in a finished sandbox with no way out except the home button. Caught by the E2E (`requested` missing
  `casa.tscn`); the bath had solved it and the garden had not copied it.

### Accepted debt

- No new accepted debt this epic. `quiqui_rig` (423) and `touch_draggable` (331) are unchanged and their
  triggers (e10, e09) still stand.

### Notes

1. **Fourth time a new scene changed its neighbour.** `jardim.tscn` made the hub's PLAY door navigate, and
   the "doors stay pending" test shrank to `SLEEP` — the last one. This was predicted in the threat model
   (T-E06-02) and still needed the test run to confirm, which is the right order: name it, then verify it.
2. **Tickle is repeatable by design.** It fires its own cue and never advances the step: play is not a
   chore, and the other two toys carry the progress.

## Traceability

`bash scripts/trace-stories.sh --strict` → PASS. `e06s01..s03` referenced from their specs and task files.
