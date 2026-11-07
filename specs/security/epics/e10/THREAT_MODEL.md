# Threat Model — e10 (Friends minigames: duck dance, bear puzzle, penguin catch; sticker album)

<!-- story: e10s01 -->
<!-- story: e10s02 -->
<!-- story: e10s03 -->
<!-- story: e10s04 -->
**Skill:** `security-review` · **Date:** 2026-11-07
**Surface:** Godot 4.7 client, 100 % offline, no accounts, no network.
**Delta over e09:** the first scenes whose **job is to mint** — a minigame win pays coins and a
star by design, so the e09 invariant "no path mints currency" becomes "every mint is bounded and
priced in time". New persisted reads: `friend_stars` (already in `SaveData`, cleaned to 0..5 per
friend). New runtime-only state: the album's origin path (never persisted). New drag abuse surface:
SNAP_TO_SLOT pieces that lock into slots on `snapped`.

## Assets

| Asset | Why it matters | Where |
|---|---|---|
| Coin counter | three new writers (duck, bear, penguin payouts) | `user://progress.json` |
| `friend_stars` | mastery per friend (0..5); drives album stickers + badge unlocks | `user://progress.json` |
| `EconomyData` minigame tables | hand-editable payout/prize tables | resource |
| Album origin path | return-to-origin navigation target | runtime only, never on disk |
| Diary | new event families `duck.*`, `puzzle.*`, `catch.*`, `album.*` | device only |

## STRIDE

| Category | Threat | Likelihood | Mitigation (test) |
|---|---|---|---|
| **T**ampering | a win tap pays twice (echo, double tap, re-entry mid-round) | **high** | payouts only from the Fsm REWARD state; `Fsm.transition_to` idempotence + `IDLE`-only round entry; mouse echo filtered (`device == -1`); one payout per `advance` settle |
| **T**ampering | replay farming mints unbounded coins | **high** | payouts live in an `EconomyData` table (data, not code); the star is once per threshold (`friend_stars` capped 0..5); coin mint per win is the priced-by-time residual (recorded below, same doctrine as the care cycle and the wheel) |
| **T**ampering | a tampered save inflates `friend_stars` (unearned stickers/badges) | medium | `SaveData._clean_stars` clamps ids and 0..5 at read time; stickers/badges are cosmetic — no currency gate reads stars |
| **T**ampering | a crafted friend id reaches `res://` (`../../etc`) | medium | ids come only from the frozen friend table (`pato`, `urso`, `pinguim`) + `Ids` validation, never from save data |
| **T**ampering | a puzzle piece double-locks (snapped twice → duplicate/ghost piece) | medium | the scene's lock is idempotent per piece id; a locked piece is disabled before reposition |
| **I**nformation disclosure | rounds, scores and payouts are counts and ids only | low | PII audit in preflight L3; no free text exists anywhere in a minigame |
| **D**enial of service | a minigame wedges mid-round (no exit forever) | medium | `MAX_DWELL` on every non-terminal Fsm state; Home always live except during a guarded settle (e08 wheel precedent: inert only while spinning, tested) |
| **D**enial of service | the album's return-to-origin has no origin (deep entry) | medium | origin defaults to the vila hub when absent/invalid; the origin is a validated `res://scenes/*.tscn` path held in memory, not persisted input |
| **D**enial of service | catch loop floods input/audio (per-frame SFX spam) | low | spawn/pop cadence floored in the tuning table; pop SFX pooled by `AudioManager` |
| **E**levation | no network, no accounts, no `res://` path from persisted data | n/a | unchanged |

## Residual risk

- Minigame coins are a mint by design and replays pay again. This is priced in time (a round takes
  seconds and the payouts are tuned small, exactly like care-cycle coins) rather than guarded by a
  persisted ledger — ADR-009 1 records why per-session guards were chosen before, and BUG-048's
  lesson (dedupe at read time) is applied to every new persisted read.
- A hand-edited `friend_stars` shows stickers she did not earn — cosmetic only; no currency, unlock
  or gate reads stars. An adult with a hex editor is outside this threat model.
- The album badge predicate reads `ProgressManager` live; a stale badge on mount self-corrects on
  the first `progress_changed` (DoorBadge pattern).
