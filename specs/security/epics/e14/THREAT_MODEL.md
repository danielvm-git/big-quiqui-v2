# Threat Model — e14 (all 17 rooms as data, one removal of the old scene layer)

<!-- story: e14s01 -->
**Skill:** `security-review` (threat model only) · **Date:** 2026-11-09 · **Review:** `specs/security/epics/e13/THREAT_MODEL.md`
**Surface:** Godot 4.7 client, 100 % offline, one local save, no accounts, no network.
**Delta over e13:** every remaining room is now a def on a wave-1 template, plus two registry slots
(`t_rhythm_pose`, `t_album`) that are ids, not paths. e14s05 then deletes the path-based scene layer
in one commit. The e12 and e13 controls still hold the perimeter: closed template registry, catalog
resolution, atomic save, no ads. This epic's job is to keep those controls true while seventeen rooms
start writing and navigating, and to make sure the removal does not leave a second resolver behind.

## Assets

| Asset | Why it matters | Where |
|---|---|---|
| Save file | closet equips, market buys, playhouse places, celebration / wheel / bear / duck / penguin pay | `user://progress.json` via `ProgressManager` `.tmp` rename |
| Scene ids | title, home, village and party open other rooms | `SceneCatalog`, defs, `PoiTable`, `FriendCatalog` |
| Coin, ticket and star counters | celebration, market, wheel, bear, duck, penguin | `EconomyData` amounts, `ProgressManager` writes |
| Equipped look and placed furniture | closet and playhouse | `user://progress.json` |
| Party lock | five placed pieces open `party` | `ProgressManager` placement count, `party.tres` |
| Album stars | displayed, never captured | `ProgressManager` stars; no image file |
| The diary | rejected ids and rejected destinations must be visible | device only, `user://logs/` |
| The single player scene | after e14s05 it is the only `.tscn` | `res://scenes/scene_player.tscn` |

## STRIDE

| Category | Threat | Likelihood | Mitigation (test) |
|---|---|---|---|
| **T**ampering | closet or playhouse writes an id that fails `Ids.is_valid`, or a piece the child does not own | **high** | validate, then `owns` / `equip` / `place_furniture`; `SC-e14s01-P0-02`, `SC-e14s03-P0-02` |
| **T**ampering | market debits coins the child does not have, or buys the same piece twice | **high** | price stays in `EconomyData`; short wallet does not save; owned stays owned; `SC-e14s03-P0-01` |
| **T**ampering | celebration, wheel, bear, duck or penguin pays twice on re-entry or a mouse echo | **high** | existing once-per-cycle / once-per-visit guards; `SC-e14s02-P0-04`, `SC-e14s04-P0-01`, `SC-e14s03-P0-03`, `SC-e14s03-P0-04` |
| **T**ampering | wheel grows an ad branch or a second pick (`AddVideoAdReward`) | medium | pay-once lock and a source scan; `SC-e14s04-P0-01`, `SC-e14s04-P1-01` |
| **T**ampering | a map, party or album target is built by joining a def string onto `res://scenes` (F-3) | medium | resolve through `SceneCatalog` only; `SC-e14s02-P0-02`, `SC-e14s03-P1-01`, `SC-e14s05-P0-03` |
| **T**ampering | e14s05 leaves one legacy path in `SceneCatalog`, `PoiTable` or `FriendCatalog`, so two navigations ship | **high** | one commit; resolvers return ids; `SC-e14s05-P0-03` |
| **T**ampering | penguin def turns on lives, shake, or a fail clock the template forbids | medium | no def key can switch them on; a miss stays in play; `SC-e14s04-P0-02`, `SC-e14s04-P1-01` |
| **R**epudiation | a rejected destination, a rejected item id or a D3 skip of `t22` leaves no trace | medium | `scene.def_rejected` / `map.destination_rejected`, and the party skip is named in the def check; `SC-e14s02-P0-02`, `SC-e14s03-P1-01` |
| **I**nformation disclosure | `t_album` grows `PhotoGallery` (camera, image file under `user://`) | medium | album reads stars and writes no image; source scan has no photo verb; `SC-e14s03-P0-05` |
| **I**nformation disclosure | a diary line or a def gains prose or a device identifier | low | `msg` stays an id; no new network client; story acceptance bars name the forbidden APIs |
| **D**enial of service | penguin spawns are never despawned | **high** | despawn rule and the orphan counter; `SC-e14s04-P0-03` |
| **D**enial of service | a hub destination or a party door points at an id with no def and the player wedges | medium | unknown ids are rejected and logged; home stays available; legacy scenes still boot until e14s05; `SC-e14s02-P0-02` |
| **E**levation | `t_rhythm_pose` or `t_album` is loaded from a path taken out of the def | medium | closed registry const map; load by id only; `SC-e14s03-P1-02` |
| **E**levation | after removal, a def path escapes `res://data/scenes/` | medium | ids match `Ids.PATTERN`; `SceneCatalog` is the only join site, and it is code, not def text; `SC-e14s05-P0-03` |

## Room-by-room security note

| Room / slot | Mints? | Navigates? | Writes the save? | Note |
|---|---|---|---|---|
| bathroom, playroom, bedroom | no | home exit only | care flag only | one `complete_step` per visit |
| closet | no | home exit only | **yes** (equip) | `Ids.is_valid` before save |
| title | no | **yes** (`home`) | no | one target |
| home, village | no | **yes** | recycling pays once per session | destinations through the catalog; locks read the care loop, never the wallet |
| celebration | **yes** | no | **yes** | once per cycle; gift is free |
| market | no | no | **yes** | `EconomyData` price; short wallet does not write |
| playhouse | no | no | **yes** | ratios, ownership check |
| bear_puzzle, duck_dance | **yes** | no | **yes** | one payout from `EconomyData` |
| t_album | no | **yes** (`village`) | no | no camera, no image file |
| party | no | **yes** (friend ids) | no | `t22` as shipped, or the D3 skip; lock is the placement count |
| wheel | **yes** | no | **yes** | one pick, ticket in, no ad |
| penguin_lanes | **yes** | no | **yes** | catch only, no fail, spawns despawn |

## Residual risk

| Residual | Reason |
|---|---|
| Defs are not integrity-checked (same as e12 and e13) | they ship inside the app; validation catches our mistakes, not a remote attacker. There is no network. |
| From e14s01 through e14s04 the tree still contains the legacy `.tscn` paths | D1 accepts that window. e14s05 is the commit that closes it. A release cut from the middle of the epic would still have two mechanisms; that cut is outside this epic's done_when. |
| A very large penguin spawn cadence can cost frames | bounded by the orphan counter and the release-gate device pass, not by a new security control |

## Gate

No HIGH finding without a mitigation and a scenario id. Offline, no network, the save stays atomic,
and scene ids resolve through the catalog. Tasks on save, navigation, minting and the removal carry
`security: medium` and their verify step includes "no new security findings in affected paths".
