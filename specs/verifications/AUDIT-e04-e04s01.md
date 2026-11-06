# Verify + Audit — e04s01 (CONTINUOUS_SCRUB & derived ScrubHull)

<!-- story: e04s01 -->
**Flow:** `build-epic` steps 5 (`verify-work`) and 6 (`audit-code`) · **Date:** 2026-11-06
**Diff:** `23dfef9` (+ the step-5/6 cleanups in this commit) on `epic/e04-bathroom-bath-scene`
**Gate:** `bash scripts/preflight.sh` → **PREFLIGHT GREEN** — 26 scripts, **320 tests, 1479 asserts**

## 1. Verify (step 5)

### 1.1 Cold start

`godot --headless --path game --quit-after 3` → no error, no warning, no script error. The project boots
with the new rig hull code and the new `SCRUBBING`/`ABORTED` FSM edges.

### 1.2 Mechanical gates

| Gate | Command | Result |
|---|---|---|
| Lint | `gdlint game/` | PASS |
| Format | `gdformat --check game/` | PASS |
| Typing | `type_gate` | PASS |
| Unit + integration | GUT | PASS — 320/320, 1479 asserts |
| PII / trace / specs / release | preflight L3–L5b | PASS |

### 1.3 Behavioural UAT — the hull against the character, measured

Mounting the rig the way the scenes pin it (centre column, height ratio, feet 0.78) and reading the
probe output — this is the check T-E04-01 exists for, and it is invisible at 16:9:

```
1920x1080  vertices=12 painted=294x620 hull=270x596 painted_h_ratio=0.574 centre_inside=true above_head_inside=false
1920x1440  vertices=12 painted=392x827 hull=368x803 painted_h_ratio=0.574 centre_inside=true above_head_inside=false
2048x1536  vertices=12 painted=419x882 hull=395x858 painted_h_ratio=0.574 centre_inside=true above_head_inside=false
```

Reading it: the hull is exactly `painted − 2 × 12 px` on every canvas (294−24=270, 620−24=596), the
painted height ratio is the design 0.574 at all three sizes, her centre is inside the hull, and a point
20 px **above her head is outside** it — so a scrub on the wallpaper does nothing. Before the fix the
hull would have been authored once, at 16:9, and this row would have been wrong on the iPad.

### 1.4 Acceptance criteria, evidence per AC

| AC | Evidence |
|---|---|
| 1 lint / 2 Fsm | preflight L0/L0b; `FsmProbe` in the fixture, `test_a_scrub_inside_the_hull_emits_per_move_and_never_consumes` |
| 3 echo | `_gui_input` device filter unchanged; the scrub tests deliver through `TouchSim.gui_event` |
| 4 dual aspect | `test_the_hull_follows_the_opaque_rect_on_every_canvas` (3 canvases) |
| 5 observability | preflight L3/L4 |
| 6 scrub semantics | `…emits_per_move_and_never_consumes`, `…stays_scrubbing` |
| 7 hull derived | the probe above + `test_the_hull_contains_the_body_and_not_the_transparent_margin` |
| 8 outside = silence | `test_a_move_outside_the_hull_emits_nothing_and_keeps_scrubbing` |
| 9 interruption | `test_freeing_a_scrubbing_node_releases_the_owner`, `test_abort_stops_the_loop_and_releases_the_owner` |
| 10 one channel | `test_the_scrub_loop_is_one_player_and_stops_on_release` |
| 11 no diary flood | `test_a_long_scrub_writes_as_much_as_a_short_one` (40 motions == 2 motions) |
| 12 coordinates | every test delivers via `TouchSim.gui_event` |

## 2. Audit (step 6) — `audit-code --gate`

| Section | Result | Note |
|---|---|---|
| Strict typing | **PASS** | every new var/param/return annotated; `type_gate` clean |
| Fsm discipline | **PASS** | `SCRUBBING`/`ABORTED` are declared edges; no boolean flag clusters added |
| Touch / echo | **PASS** | `device == -1` filter untouched; one `_holder` latch |
| Layout contract | **PASS** | hull derives from `get_visual_global_rect()`; no new pixel constants |
| Tests (F.I.R.S.T.) | **PASS** | 12 new tests, each fails a plausible broken implementation; the diary test compares two gesture lengths rather than a magic total |
| Boy Scout | **PASS with note 1** | two functions over 20 lines were split during this gate |
| No dead code | **PASS** | `scrub_points_seen` was added for debugging and removed before the gate closed |
| No duplication | **PASS** | the scrub end path is one `_end_scrub()` shared by drop and abort |
| Network / PII | **PASS** | no HTTP/WebSocket/OS.shell in `game/scripts`, `game/tools`; L3 green |
| Story tags | **PASS** | every new file carries `# story: e04s01` |

**Verdict: PASS** — no must-fix findings. Two notes and one accepted debt.

### Notes

1. **Two functions were over 20 lines and were split in this gate** (both discovered here, not
   pre-existing): `_drop` (24 → 12 + `_end_scrub`) and `set_outfit` (22 → 8 + `_take_outfit_off`).
   The e03 audit held the same 20-line bar, so shipping 22–24 lines would have been a regression
   against our own standard.
2. **`scrub_target` is duck-typed on purpose** (`has_method("scrub_hull_global")`): making it
   `QuiQuiRig` would give a generic component a dependency on the character rig, and the same component
   must serve the e06 garden and e09 store. The cost is that a mistyped target is silence — which is
   exactly what `test_a_missing_scrub_target_emits_nothing` pins, and what the eval `EV-E04-02`
   documents as a deliberate trade.

### Accepted debt

- **`quiqui_rig.gd` is 341 lines** (300 guideline; it was 393 before the e03 refactor and this story
  added the hull API). Splitting the rig would give the layout, the hull and the animation two owners,
  which is worse than 14 % over. Recorded with the same revisit trigger as before: when e10 adds
  separate body/outfit layers, the layout half moves out.
- `_start_loop`/`_stop_loop` own a player rather than going through `AudioManager`: the manager has no
  loop channel API and adding one for a single consumer would be speculative. If e05–e10 need looping
  SFX, promote it then.

## 3. Traceability

`bash scripts/trace-stories.sh --strict` → PASS. `e04s01` is now implemented and referenced from
`e04s01.md`, `e04s01-tasks.yaml` and `specs/benchmarks/e04.yaml` (`EV-E04-01..04`).
