---
bug_id: BUG-031
status: fixed
severity: low
scope: ui
title: The celebration paid +5/+1 but never showed it, and it lasted a single fade
---
# BUG-031: the party is the payoff, so it now shows what she earned

<!-- story: e07s02 -->

**Found by:** e07 post-epic review (comparing the epic against `specs/IMPACT_LATEST.md` and
`specs/tech-architecture/DESIGN_PLAN_LATEST.md`, both of which planned a "reward reveal").

## Problem

`IMPACT_LATEST.md` described `celebracao.gd` as "CELEBRATE scene: confetti, **reward reveal**,
`complete_cycle`", and `DESIGN_PLAN_LATEST.md`'s e07 row lists `coin.png` / `star.png` for the
celebration. What shipped was confetti + voice + an immediate return to the hub: the reward was paid
(+5 coins, +1 ticket) but **shown nowhere in the party**, and the party lasted roughly one 0.4 s fade
(closed and `_leave()`d in `_ready`). For a pre-reading child the reward was therefore disconnected from
the celebration — the coins appeared one fade later, on a different scene, in a corner.

## Root Cause

The frozen e07s02 contract (`celebracao.tscn`: background, rig, `HomeButton`, `Confetti`) had no reward
icon and no hold, and the acceptance criteria said only "the Casa is requested exactly once", which the
immediate return satisfied. The plan wanted more than the spec froze; nothing connected the two.

## Fix

- `CelebrationScene` now holds `HOLD_SEC = 1.8` before `_leave()`, driven by the scene's own
  `advance(delta)` clock (no timers, so tests step it exactly).
- `_reveal_progress()` pops in one `Coin` (`coin.png`) and one `Ticket` (`fortune_wheel.png`) at the
  head line after `REVEAL_LEAD_SEC`, cubic-eased, fading and scaling in over `REVEAL_POP_SEC`.
- `build_celebracao_scene.gd` adds the two `TextureRect`s: anchored to the rig's head line, one each
  side, `MOUSE_FILTER_IGNORE`, **not** in `hit_target` — they are art, not buttons. The `.tscn` is
  regenerated (8 nodes).
- The same two icons are already what `CoinTicketHud` uses, so the party and the counter tell one story.
- `test_cycle_e2e.gd`'s loader steps every stage's `advance()` so the party ends during the journey
  (previously only `SceneManager` was stepped).

## Verification

- `test_the_party_holds_then_shows_what_she_earned` — hidden at start, `revealed` after the lead, full
  opacity/scale, no Casa request while the party is on.
- `test_the_reward_icons_are_art_not_buttons` — both icons ignore the mouse and never join
  `hit_target`.
- `test_the_party_leaves_by_itself_after_the_hold` — halfway: still on; after `HOLD_SEC`: one Casa
  request.
- `test_entering_pays_once_and_moves_the_loop_to_idle` updated: the Casa is requested **after** the
  hold, not in `_ready`.
- Full gate: **411 tests / 2174 asserts** green (was 408 / 2154); the celebration suite has 11 tests.
