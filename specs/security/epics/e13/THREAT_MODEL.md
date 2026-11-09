# Threat Model — e13 (wave 1b: four primitives and twelve templates)

<!-- story: e13s01 -->
**Skill:** `security-review` · **Date:** 2026-11-08 · **Review:** `specs/security/CODEBASE_REVIEW_2026-11-08.md`
**Surface:** Godot 4.7 client, 100 % offline, one local save, no accounts, no network.
**Delta over e12:** thirteen templates now read their parameters from a def, and two of them can *mint*
(reward, prize pick) or *navigate* (map). The e12 controls still hold the perimeter (grammar per kind,
closed registry, no path from data); this epic's job is to make sure none of the thirteen re-opens it,
and that every mint stays once-per-cause.

## Assets

| Asset | Why it matters | Where |
|---|---|---|
| Coin / ticket counter | three new writers (`t32_reward`, `t51_prize_pick`) | `user://progress.json` |
| Equipped look + placed furniture | written by `t45_dress_decorate` | `user://progress.json` |
| Scene ids reachable from a map | `t25_map` opens other rooms by id | `SceneCatalog` + def |
| Prize table and reward amounts | hand-editable data; the only "pricing" in the game | `EconomyData`, def |
| The diary | new event families per template | device only |

## STRIDE

| Category | Threat | Likelihood | Mitigation (test) |
|---|---|---|---|
| **T**ampering | `t32_reward` pays twice on re-entry (back button, double tap, echo) | **high** | the existing once-per-cycle guard in `CareLoopManager`/`ProgressManager`; `SC-e13s05-P1-04` enters twice and asserts one payment |
| **T**ampering | `t51_prize_pick` allows a second pick, or an ad branch returns (`AddVideoAdReward`) | medium | pay-once lock + a source scan for ad verbs; `SC-e13s09-P1-02` |
| **T**ampering | a map destination built as a path from the def string traverses out of `res://scenes` (F-3) | medium | destinations resolve **through `SceneCatalog`**, never a concatenation; `SC-e13s03-P0-05` rejects a value that is not in the catalog and logs it |
| **T**ampering | `t45` writes an item id the child does not own, or an id that is not id-valid | medium | `Ids.is_valid` + `owns_furniture` before any save call; `SC-e13s05-P1-02` |
| **T**ampering | a completed cleaning step is un-completed (erase takes back credited work) | **high** for the child's trust, medium for integrity | completion is one-way per step; `SC-e13s04-P0-03` |
| **T**ampering | the tap primitive counts one target twice, finishing a step nobody finished | **high** | distinct-target counting; `SC-e13s02-P1-02` |
| **T**ampering | a lane game becomes a fail state (lives, restart) by a def value | medium | no life and no shake exist in the template and no def key can switch them on; `SC-e13s08-P1-01` source scan |
| **R**epudiation | a rejected def or destination leaves no trace | medium | rejection events (`scene.def_rejected`, `map.destination_rejected`) then L3 audit |
| **I**nformation disclosure | `t43_color_fill` (wave 2) brings `PhotoGallery` with it — photo capture and file storage | low now, **real in e15** | the scope declines the gallery; the decline must be written into the template's adaptation rule so the verbs cannot return with the code |
| **D**enial of service | a spawned object is never despawned and the room accumulates nodes | **high** | the despawn rule plus the orphan counter in the standard run; `SC-e13s08-P0-04` |
| **D**enial of service | a step with no exit is introduced by a new template (a rub that can never reach the threshold) | **high** | the threshold is data and completable by design; home is live in every state (e12s03); `SC-e13s04-P0-01` asserts completion at the def value |
| **D**enial of service | a `wait` reaction with no deadline stalls a step | medium | `wait` is a bounded duration in the def and the step machine has no deadline of its own, so a wait cannot hold input hostage |
| **E**levation | a template name in a def reaches the filesystem | medium | the registry stays a closed `const` map (e12 F-2); templates are loaded by id only |

## Template-by-template security note

| Template | Mints? | Navigates? | Writes the save? | Note |
|---|---|---|---|---|
| t34_rub_reveal | no | no | no | reveal is one-way inside the step |
| t21_touch_each | no | no | no | spent targets still answer |
| t25_map | no | **yes** | no | destinations resolve through the catalog; locks read the care loop, never the wallet |
| t40_draw_fill / t23_erase | no | no | no | completion at a data threshold, one-way once done |
| t45_dress_decorate | no | no | **yes** | ids validated, ownership checked, bin saves the empty slot |
| t0_title | no | **yes** | no | exactly one interactive target |
| t32_reward | **yes** | no | **yes** | once per cycle; the ad-gated gift is free |
| t22_play_beat / t3_skip_beat | no | no | no | skip preserves a declared reward |
| t50_lanes | no | no | no | catch only, no loss |
| t51_prize_pick | **yes** | no | **yes** | one pick, no ad, prize set from the def |

## Residual risk

| Residual | Reason |
|---|---|
| Defs are not integrity-checked (same as e12) | ships inside the app; validation exists for our own mistakes first |
| A def with a very large spawn cadence can cost frames | bounded by the orphan counter and the device test at the release gate, not by a security control |

## Gate

No HIGH finding without a mitigation. Three findings from the codebase review touch this epic (F-3 twice:
map destinations and node references). All are `medium`, all have a scenario and a capsule criterion.
Tasks in the touched paths carry `security: medium` and their verify step asserts
"no new security findings in affected paths".
