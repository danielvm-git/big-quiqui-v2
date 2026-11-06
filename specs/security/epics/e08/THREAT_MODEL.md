# Threat Model — e08 (Vila hub, recycling drag, Wheel of Fortune)

<!-- story: e08s01 -->
<!-- story: e08s02 -->
<!-- story: e08s03 -->
<!-- story: e08s04 -->
**Skill:** `security-review` (written retroactively by the e08 post-epic review, BUG-043) · **Date:** 2026-11-07
**Surface:** Godot 4.7 client, 100 % offline, no accounts, no network.
**Delta over e07:** the first **earn paths outside the care cycle** (recycle coin, wheel prize) and the
first **ticket sink** (the wheel). Money now moves in three places, so the invariant is "no path mints or
loses currency".

## Assets

| Asset | Why it matters | Where |
|---|---|---|
| Coin / ticket counters | three writers now: cycle reward, recycle, wheel | `user://progress.json` |
| `EconomyData` tuning table | prize weights, payouts and the ticket cost are data | resource, hand-editable |
| Diary | new event families `vila.*`, `wheel.*` | device only |

## STRIDE

| Category | Threat | Likelihood | Mitigation (test) |
|---|---|---|---|
| **T**ampering | recycle coin farmed by re-entering the Vila | **high** | session ledger `VilaScene.recycled_this_session` (BUG-039; `test_second_visit_to_the_vila_pays_and_teaches_nothing`) |
| **T**ampering | double-tap on SPIN spends two tickets | high | `Fsm` single-spin lock (`test_double_tap_does_not_spend_twice`) |
| **T**ampering | ticket spent, prize never paid (Home mid-spin) | **high** | Home inert unless IDLE (BUG-038; `test_home_is_inert_while_spinning`) |
| **T**ampering | zero or negative cost in a hand-edited table mints or frees spins | medium | cost floored to 1 (BUG-044; `test_zero_or_negative_cost_still_spends_one_ticket`) |
| **T**ampering | balances driven negative | medium | `_apply` clamps; property tests (`test_economy_properties.gd`) |
| **I**nformation disclosure | `wheel.prize` / `vila.recycle_earn` carry ids and counts only | low | PII audit in preflight L3 |
| **D**enial of service | wheel stuck in SPINNING | low | `MAX_DWELL` on SPINNING and REWARD, `FsmProbe` |
| **D**enial of service | flying coin sprite leaks on scene exit | low | tween killed in `_exit_tree` |
| **E**levation | no ids from disk, no network, no `res://` paths built from data | n/a | unchanged |

## Residual risk

The wheel's prize table is not persisted; losing it costs nothing. The recycle ledger is in-memory, so a
relaunch offers one more coin: accepted and recorded in ADR-010 (a persisted guard needs a `SaveData`
version bump, ADR-005).
