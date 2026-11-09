# QuiQui 2 ↔ TutoTOONS parity backlog

<!-- story: e01s01 -->
<!-- story: e03s01 -->
**Source:** `specs/product/TUTOTOONS_ENGINE_REPORT.md` (REA deep pass, 24 titles, 2026-11-06)
**Purpose:** turn "I want QuiQui 2 to feel like the TutoTOONS games my daughter loves" into a concrete,
file-mapped list of fixes, ordered by how much each one moves the *feel* for a 4–7-year-old.

> **Status:** planning input, not code. Every item below becomes a story via `plan-work` before it is
> built. Nothing here licenses copying pixels, audio or data — only mechanics (see
> `TUTOTOONS_REFERENCE.md` § *What this does NOT license*).

## The parity gap in one sentence

Our **loop and its plumbing** are already at or above TutoTOONS grade (table-driven FSM, mouse-echo
filtering, no-text UI, atomic save). What a child actually *feels* — the want escalating before a care
step, a hand teaching the first drag, a "NEW!" badge when she earns something — is missing, and that is
the whole difference between "a clean engine" and "a game she asks to open again".

---

## P0 — care-loop feel (do first; these are the emotional core)

### FIX-01 · Wish escalation: quarter → half → full
- **Evidence:** `HungerTimer.ReachedQuarter / ReachedHalf` fires milestone events as the need decays, so
  the child sees urgency build before the care step opens.
- **Today:** `wish_bubble.gd` is binary (`HIDDEN`/`SHOWN`); `care_loop_manager.gd` has no need timer at
  all — the bubble shows the next-step icon with a constant pulse.
- **Change:**
  1. Add a per-cycle need timer to `care_loop_manager.gd` (a `Fsm`-driven `NEED_FRESH → NEED_QUARTER →
     NEED_HALF → NEED_FULL` sub-machine, or a data field consumed by the bubble).
  2. Extend `wish_bubble.gd` with a third visual state (or a scale/pulse-speed ramp) keyed to the level;
     keep the existing `HIDDEN`/`SHOWN` contract for old tests and add `urgency()` as a test observable.
  3. On `NEED_FULL`, play a soft sound and pulse faster (never a timer that blocks — a child may take as
     long as she likes inside a step, per the existing comment).
- **Files:** `game/scripts/autoloads/care_loop_manager.gd`, `game/scripts/components/wish_bubble.gd`
- **Epic:** e08s01 (Casa/Vila hub revisits the wish bubble) or a dedicated hardening slice.
- **BCP:** ~2 (small, testable, high feel-per-line).

### FIX-02 · Hint/tutorial layer (the ghost hand, finally)
- **Evidence:** `HintManager` (a *queue*: `TryShowCurrentHintOrShowEnqueued`, `BeginCoolDown` throttle) +
  a taxonomy — `Utility.HintHand`, `PulsatingHint`, `DragWorldToWorldHint`, `PictureHints`,
  `MergeTutorialHints.ShowTapHint/ShowCircleHint/ShowDragHint`, `HoverFeedback`.
- **Today:** nothing. This is the exact "ghost-hand affordance" `TUTOTOONS_REFERENCE.md` deferred to e04
  and that e04 did not land.
- **Change:**
  1. New `HintManager` component (`game/scripts/components/hint_manager.gd`): enqueue hints, show one at
     a time, `BeginCoolDown` throttle, `StopHint`, test seam for manual stepping (same pattern as
     `wish_bubble.gd`'s `manual_step`).
  2. New `PulsatingHint` (pulse a target's outline/scale) and `DragHint` (a drawn hand that slides from a
     source to a target) — art needed: a hand + glow ring under `res://assets/art/ui/`.
  3. Wire the **first** teaching moment into the first drag the child meets: e08's recycling drag-to-bin
     (`saquinho_lixo`) is the natural debut; then reuse in every later drag scene.
- **Files:** `game/scripts/components/hint_manager.gd` (new), `game/scripts/components/pulsating_hint.gd`
  (new), `game/scripts/components/drag_hint.gd` (new), builder + scene wiring.
- **Epic:** e08 (debut in e08s02), reused in e09/e10.
- **BCP:** ~3–4 (one new manager + two hint components + art + wiring).

### FIX-03 · Reward juice on every earn (not only the cycle reward)
- **Evidence:** `CoinSystem.CoinPulsate / GatherCoin / ShowAddedCoins` — the coin visually *travels* and
  the counter pulses on every increment, not just at cycle end.
- **Today:** `coin_ticket_hud.gd` only re-reads the number on `progress_changed`; the celebration
  (`celebracao.gd`) pops the reward, but an e08 recycling +1 Coin would just tick the numeral.
- **Change:** add a `pulse()`/`fly_coin()` hook to `coin_ticket_hud.gd` (scale pop on the numeral, a
  coin sprite tween from the earn point to the HUD chip) and call it from every earn site.
- **Files:** `game/scripts/components/coin_ticket_hud.gd`, earn sites (e08s02 bin, e08s03 wheel, e09 store).
- **Epic:** e08s02 (first non-cycle earn).
- **BCP:** ~1–2.

---

## P1 — reward & collection feel

### FIX-04 · Badge/indicator layer ("NEW!", unlock dots)
- **Evidence:** `TutoTOONS.Indicators.IndicatorManager / IndicatorController / IndicatorType` — a badge
  system for unlocks, present in the shared engine.
- **Today:** none; `coin.png` / `star.png` ship but there is no "you unlocked X" badge.
- **Change:** new `indicator_manager.gd` + `indicator_badge.gd`; a badge appears above the wheel, the
  sticker album and the party door when their unlock condition first becomes true, then clears.
- **Files:** `game/scripts/components/indicator_manager.gd` (new), HUD/POI wiring.
- **Epic:** e08 (wheel unlock badge) → e10 (album sticker badges).
- **BCP:** ~2.

### FIX-05 · Tuning tables as first-class data (no magic numbers in code)
- **Evidence:** `LevelUpSystem.SetSettingsValues` (XP curve is a table), `KitchenFoodsData` with
  `FoodType / FoodTier / ReactionType`, `StatusBar.AddRule` — tuning lives in data, not code.
- **Today:** `food_catalog.gd` is already data (good); but cycle rewards are `const CYCLE_COINS_REWARD: int = 5`
  in `progress_manager.gd`, and future prize/furniture tables would be inline.
- **Change:** centralize economy constants (rewards, wheel prize weights, store prices) into one typed
  `EconomyData` resource (mirroring `food_catalog.gd`) consumed by `progress_manager.gd` and the scenes;
  keep the consts as documented defaults for tests.
- **Files:** `game/scripts/core/economy_data.gd` (new), `game/scripts/autoloads/progress_manager.gd`,
  wheel/store scenes as they land.
- **Epic:** e08s03 (wheel prize table) — establishes the pattern before e09's store.
- **BCP:** ~2.

---

## P2 — production scaffolding (the "raw" areas the engine pass exposed)

### FIX-06 · Save backup + repair path
- **Evidence:** `TutoTOONS.SavedData` + `FileWrapper` writes `saved_data.json` **plus**
  `saved_data_backup.json` and `saved_data_temp.json`, with AES encryption.
- **Today:** `progress_manager.gd` does atomic `.tmp` rename (already validated) but has **no backup** —
  a corrupt `progress.json` silently resets to defaults (`_fail_load("corrupt")`).
- **Change:** keep a `.bak` of the last-known-good save: on successful load, copy `progress.json →
  progress.json.bak`; on `corrupt` load, attempt the `.bak` before falling back to defaults, and emit
  `save.recovered_from_backup`. (Skip AES — offline local file, no PII.)
- **Files:** `game/scripts/autoloads/progress_manager.gd`, `SaveData` version bump per ADR-005 amendment.
- **Epic:** e11 hardening slice (or the first bug that smells like data loss).
- **BCP:** ~1.

### FIX-07 · Dev-only debug console + FPS overlay
- **Evidence:** `TutoTOONS.Utils.Debug.Console.DebugConsole` + `TutoTOONS.PerformanceMonitor` (on-device
  FPS graph + draggable overlay), beside their `TutoLogger`.
- **Today:** observability is CLI-only (`scripts/logs.sh`); no on-device view.
- **Change:** a dev-only autoload (compiled out of release, or toggled by a three-finger long-press) that
  shows FPS, scene, FSM state and the last `Log` lines on the tablet — mirroring our `Log` JSONL, never
  writing anything new.
- **Files:** `game/scripts/autoloads/dev_console.gd` (new), gated behind `OS.is_debug_build()`.
- **Epic:** e11 (release gate is the honest home for dev scaffolding).
- **BCP:** ~2.

### FIX-08 · Haptics — DECLINE on iPad, note for parity
- **Evidence:** `CandyCoded.HapticFeedback` in one title (Dopples-era).
- **Decision:** **decline** — the target is iPadOS (no vibration) + desktop; `Input.vibrate_handheld`
  would be dead code. Recorded so nobody re-opens it.

---

## P3 — content approach (confirm, do not rework)

### FIX-09 · Scene = data + one controller + separable content
- **Evidence:** Dopples ships 52 `split_scene_*` Play-Asset-Delivery packs; Fluvsies ships
  `split_music_tracks / split_sfx / split_room_shared`. Their "engine" is thin and content streams.
- **Today:** our `build_*_scene.gd` builders + `.tscn` per epic already separate content from logic.
- **Change:** none required. Keep `build_*_scene.gd` as the single source of truth for `.tscn`; do **not**
  adopt Spine or their asset pipeline — Godot scenes are the equivalent.
- **Epic:** — (standing convention, already enforced).

---

## Priority summary for planning

| Order | Fix | Epic | BCP | Feels like TutoTOONS because… |
|---|---|---|---|---|
| 1 | FIX-01 wish escalation | e08s01 | 2 | want builds before the care step |
| 2 | FIX-02 hint layer | e08s02 | 3–4 | a hand teaches the first drag |
| 3 | FIX-03 reward juice | e08s02 | 1–2 | every coin *travels* to the HUD |
| 4 | FIX-04 badges | e08/e10 | 2 | "NEW!" reward the moment she earns it |
| 5 | FIX-05 tuning tables | e08s03 | 2 | tuning is data, prices/prizes live outside code |
| 6 | FIX-06 save backup | e11 | 1 | never lose her coins |
| 7 | FIX-07 dev console | e11 | 2 | (invisible to her; keeps us honest) |
| — | FIX-08 haptics | — | — | decline (iPad) |
| — | FIX-09 content shape | — | — | already correct |

Net new BCP to fold into the remaining plan: **~14–15 across e08–e11**, front-loaded into e08 because
that is where the outdoor world first introduces the drag-and-earn verbs a child meets alone.
