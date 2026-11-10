# Threat Model — e16 (wave 3: movement and niche templates)

<!-- story: e16s01 -->
**Skill:** `security-review` · **Date:** 2026-11-09 · **Source:** `specs/product/SCOPE_LATEST.yaml` REQ-16
**Surface:** Godot 4.7 client, 100 % offline, one local save, no accounts, no network.
**Delta over e13/e15:** ten shapes on Tap, Rub, Steer, Spawner and Give→Receive. Steer and the Spawner
already exist (D6). This epic adds no primitive, no care step, no art, no voice, and no save field.

Recorded limits, each with a scenario:

- **No lives.** `t37` and `t26` have no life counter, no `DecreaseLife`, no `ShakeScreen`, and no crash restart. No def key turns one on. `SC-e16s01-P0-01`, `SC-e16s01-P0-02`, `SC-e16s01-P1-01`.
- **No ads.** T39 and T54 stay unbuilt. No wave-3 template calls `ShowAd`, `ShowVideo`, `AddVideoAdReward`, or `OnDoubleCoinsClick`. `SC-e16s01-P1-01`, `SC-e16s02-P1-01`, `SC-e16s04-P1-03`.
- **No network.** No `HTTPRequest`, `HTTPClient`, `WebSocketPeer`, or `OS.shell_open` in the new templates. `SC-e16s01-P1-01`, `SC-e16s02-P1-01`, `SC-e16s03-P1-01`.
- **Spawned nodes cannot accumulate.** Consumers of the e13 Spawner (`t37`, `t26`, `t41`, `t46`) despawn on collect, pop, reveal, or lifetime. `SC-e16s01-P0-04`, `SC-e16s02-P0-04`.
- **Drag-release does not fork `TouchDraggable`.** `t47_drag_release` is a rule on `t20_drag_snap`. There is no `t47` script, no new mode, and `touch_draggable.gd` is not grown. `SC-e16s03-P0-02`, `SC-e16s03-P0-03`.

REQ-16 was confirmed. No acceptance criterion changed.

## Assets

| Asset | Why it matters | Where |
|---|---|---|
| Scene tree | four templates spawn nodes | Spawner output, then freed |
| `TouchDraggable` | the only drag surface; grandfathered at 326 lines | `game/scripts/components/touch_draggable.gd` |
| Scene ids | `t53_outro` sends the child home | `SceneCatalog` |
| Save file | serve and the progress holder must not add a field | `user://progress.json` |
| Template registry | 14 numbers and two ad slots must stay absent | closed `const` map |
| The diary | new template events | device only |

## STRIDE

| Category | Threat | Likelihood | Mitigation (test) |
|---|---|---|---|
| **S**poofing | n/a — no accounts | — | unchanged |
| **T**ampering | a def key enables lives, shake, or a crash restart on `t37` / `t26` | **high** | those keys do not exist; a miss despawns quietly; `SC-e16s01-P0-01`, `SC-e16s01-P0-02`, `SC-e16s01-P1-01` |
| **T**ampering | `t41` or `t42` gains a blade / `Slicer2D` | medium | pop is Tap; cut is Rub along a polyline; `SC-e16s01-P0-03`, `SC-e16s02-P0-01` |
| **T**ampering | `t46` `TimeOut` fails the round | **high** for the child's trust | the object stays findable until its cup is tapped; `SC-e16s02-P0-02` |
| **T**ampering | `t48` writes a payout or a new save field | medium | one guest, no exit, save bytes unchanged under `TestReset`; `SC-e16s02-P0-03` |
| **T**ampering | `t47` becomes a second drag script or a new `TouchDraggable` mode | **high** | fold into `t20`; `SC-e16s03-P0-02`, `SC-e16s03-P0-03`; INV-09 blocks growth of the grandfathered file |
| **T**ampering | `t53` builds a scene path from the def string | medium | destination is the id `home` through `SceneCatalog`; `SC-e16s03-P0-04` |
| **T**ampering | `t49` completes the step or writes progress itself | medium | the holder is a view of the runner ratio; `SC-e16s04-P1-01` |
| **R**epudiation | a rejected outro id or a bad probe def leaves no trace | medium | `scene.def_rejected` / catalog rejection, then L3 |
| **I**nformation disclosure | an ad SDK or a photo call arrives with a ported template | medium | no ads, no `PhotoGallery` on groom or outro; `SC-e16s03-P1-01`, `SC-e16s04-P1-03` |
| **D**enial of service | spawned nodes from `t37`, `t26`, `t41`, `t46` accumulate | **high** | despawn on collect, pop, reveal, and lifetime; `SC-e16s01-P0-04`, `SC-e16s02-P0-04` |
| **D**enial of service | a cut path or a cup round has no exit | medium | path threshold is data; cups end when found; home stays live |
| **E**levation | a template id is loaded from disk by string concat | medium | closed registry; `SC-e16s04-P1-03` fails closed if a reserved number or T39/T54 is registered |
| **E**levation | a network peer is added "for the next title" | medium | no network types in the wave-3 sources; `SC-e16s01-P1-01`, `SC-e16s02-P1-01`, `SC-e16s03-P1-01` |

## Template-by-template security note

| Template | Mints? | Navigates? | Writes the save? | Note |
|---|---|---|---|---|
| t37_tap_moving | no | no | no | no lives, no shake; spawner consumer |
| t26_ride | no | no | no | collect only; nothing to crash into |
| t41_float_pop | no | no | no | pop on tap; no blade |
| t42_slice_cut | no | no | no | dotted path on Rub; no blade |
| t46_cups | no | no | no | no timer; object stays findable; cups despawn |
| t48_serve | no | no | no | one guest who stays; no new payout |
| t52_groom | no | no | no | comb and dry before trim; existing art ids |
| t47_drag_release | no | no | no | **not a script**; rule on `t20`; does not fork `TouchDraggable` |
| t53_outro | no | **yes** | no | one target; scene id `home` via `SceneCatalog` |
| t49_progress_holder | no | no | no | view of runner progress |
| T39, T54 | — | — | — | unbuilt |
| numbers 1, 2, 4, 24, 28, 29, 30, 31, 33, 35, 36, 56, 57, 58 | — | — | — | reserved, unbuilt |

## Residual risk

| Residual | Reason |
|---|---|
| Defs are not integrity-checked | shipped inside the app; same residual as e12 |
| A very high spawn cadence can still cost frames | orphan counter plus the device pass at the release gate |

## Gate

No HIGH finding without a mitigation. Lives, ads, network, spawn accumulation, and the drag fork each
have a scenario above. Tasks that implement those paths are `security: medium` and their verify step
includes "no new security findings in affected paths".

### Scenario index

| ID | Asserts |
|---|---|
| SC-e16s01-P0-01 | moving tap counts once; no life changes |
| SC-e16s01-P0-02 | ride collects; a collision does not restart |
| SC-e16s01-P0-03 | float pop has no blade |
| SC-e16s01-P0-04 | `t37` / `t26` / `t41` orphans return to zero |
| SC-e16s01-P1-01 | no `DecreaseLife`, `ShakeScreen`, `ShowAd`, or network type |
| SC-e16s02-P0-01 | slice follows the polyline; no `Slicer2D` |
| SC-e16s02-P0-02 | cups have no `TimeOut` |
| SC-e16s02-P0-03 | serve writes no save |
| SC-e16s02-P0-04 | cup orphans return to zero |
| SC-e16s02-P1-01 | no ad verb and no network type on cut, cups, serve |
| SC-e16s03-P0-02 | release-right and release-wrong go through `t20` |
| SC-e16s03-P0-03 | no `t47` script; `TouchDraggable` is not forked |
| SC-e16s03-P0-04 | outro uses catalog id `home` |
| SC-e16s03-P1-01 | groom and outro have no ad, network, or photo call |
| SC-e16s04-P1-01 | progress holder does not end the step or write the save |
| SC-e16s04-P1-03 | reserved numbers and T39/T54 stay out of the registry |
