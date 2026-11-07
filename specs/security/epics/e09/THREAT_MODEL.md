# Threat Model — e09 (Furniture store, casinha free placement, house party)

<!-- story: e09s01 -->
<!-- story: e09s02 -->
<!-- story: e09s03 -->
<!-- story: e09s04 -->
**Skill:** `security-review` · **Date:** 2026-11-07
**Surface:** Godot 4.7 client, 100 % offline, no accounts, no network.
**Delta over e08:** the first **purchase sink** (coins → owned furniture) and the first **player-authored
layout** (a normalized coordinate from a finger reaches the save file). The invariant is unchanged — no
path mints currency — but there is a new class of persisted input: two floats per placed piece.

## Assets

| Asset | Why it matters | Where |
|---|---|---|
| Coin counter | a fourth writer: the store debits | `user://progress.json` |
| `owned_furniture` | what she already paid for; a duplicated entry would double-charge | `user://progress.json` |
| `placed_furniture` (`id, x, y`) | the first **finger-authored** data on disk | `user://progress.json` |
| `EconomyData.furniture_prices` | hand-editable price table | resource |
| Diary | new event families `store.*`, `furniture.*`, `casinha.place`, `party.*` | device only |

## STRIDE

| Category | Threat | Likelihood | Mitigation (test) |
|---|---|---|---|
| **T**ampering | a tap charges twice (echo, double tap) | **high** | `StoreScene` takes a purchase only from `IDLE`; `buy_furniture` refuses an owned id (`test_buying_the_same_piece_twice_is_refused_and_free`, `test_one_tap_buys_once_and_shows_the_sold_badge`) |
| **T**ampering | a tap debits and hands back nothing, or hands back without debiting | **high** | every refusal returns before the first mutation (`test_short_coins_change_nothing`) |
| **T**ampering | negative or zero price mints coins / grants for free | medium | price floored at 0 and a 0-price item is still a purchase (`test_a_negative_price_is_refused`, `test_a_free_price_is_still_a_purchase`) |
| **T**ampering | a crafted id reaches `res://` (`../../etc`) | medium | ids come only from `FurnitureCatalog.FURNITURE_IDS` + `Ids` (`test_unknown_and_unsafe_ids_are_rejected`) |
| **T**ampering | a tampered save places an unowned or out-of-room piece | medium | `SaveData._clean_placement` drops bad ids and clamps `0..1`; `place_furniture` requires ownership (`test_a_tampered_save_cannot_place_outside_the_room`, `test_a_tampered_coordinate_is_clamped_not_crashed`) |
| **T**ampering | the party threshold is bypassed | low | one owner for `PARTY_MIN_PLACED`; `party_unlocked()` reads the save, not a scene flag |
| **I**nformation disclosure | placements are two floats; events carry ids and counts only | low | PII audit in preflight L3 |
| **D**enial of service | a purchase wedges the store (no second tap forever) | low | `MAX_DWELL` on PAYING/SOLD and the `IDLE`-only entry (`_settle_store` in the epic walk) |
| **D**enial of service | a locked party traps the child | medium | home + casinha doors are always live, both ≥120 px (`test_home_and_the_casinha_door_both_navigate_once`) |
| **D**enial of service | a freed drag target crashes a gesture | low | `_rect_of` accepts `Variant` and treats a freed target as a miss (e03 regression suite) |
| **E**levation | no network, no accounts, no `res://` path from data | n/a | unchanged |

## Residual risk

- `placed_furniture` grows by one entry per piece (12 max), so the save cannot be inflated by replays.
- The price table is data, not code: a hand-edited `0` price is a gift, not a mint, and is recorded here
  rather than defended against (an adult wielding a hex editor is outside the threat model of an offline
  child's game).
- The party badge is cosmetic; skipping it on a hand-built hub scene changes no rule, because
  `HousePartyScene.party_unlocked()` is the gate.
