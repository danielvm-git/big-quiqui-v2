# Threat Model — e15 (wave 2: care extensions)

<!-- story: e15s03 -->
**Skill:** `security-review` · **Date:** 2026-11-09 · **Source:** `specs/product/SCOPE_LATEST.yaml` REQ-15
**Surface:** Godot 4.7 client, 100 % offline, one local save, no accounts, no network.
**Capsule:** Agent B owns `specs/epics/` for e15. This model is written from REQ-15 so the security
contract exists even while that capsule is still in draft. It does not edit the e15 stories.

**Scenario map used here** (invented ids; cite them from the capsule):

| Story | Shapes | Why this cut |
|---|---|---|
| e15s01 | `t44_paint` | Rub deposits color. Largest wave-2 template. |
| e15s02 | Pairs, Sequence, `t27_memory`, `t55_find` | e13s02 already points pairs and sequence at e15s02. |
| e15s03 | `t43_color_fill` | The template whose evidence includes `PhotoGallery` in every scene. |
| e15s04 | `t38_peekaboo` | Tap + the e13 Spawner. TutoTOONS calls `DecrementLives`. |

`t43_color_fill` declines `PhotoGallery`. The adaptation rule for that template must say so in writing.
`TakePhoto`, `SaveToFile`, `LoadPhotos` and `DisplayPhotos` have no counterpart, no camera permission,
and no image file under `user://`. No def key may turn the gallery on. The decline is `SC-e15s03-P0-01`.

## Assets

| Asset | Why it matters | Where |
|---|---|---|
| Photos of the child or the screen | `t43` evidence carries `PhotoGallery` on every scene | must not be created |
| Save file | paint and fill must not add a field | `user://progress.json` |
| Spawned peekaboo actors | `t38` uses the shared Spawner | scene tree, then freed |
| Voice keys for "where is…?" | `t55` speaks a key; a path would leave `res://` | `AudioManager` resolver |
| The diary | new template events | device only; `msg` stays an id |

## STRIDE

| Category | Threat | Likelihood | Mitigation (test) |
|---|---|---|---|
| **S**poofing | n/a — no accounts on this client | — | unchanged from e12 |
| **T**ampering | a def bool turns `PhotoGallery` / `TakePhoto` back on inside `t43` | **high** | the adaptation rule declines the gallery, and the template has no such key; `SC-e15s03-P0-01` source-scans for `PhotoGallery`, `TakePhoto`, `SaveToFile`, `LoadPhotos`, `DisplayPhotos` |
| **T**ampering | `t38` regains `DecrementLives` or a def key that adds a life counter | **high** | friends peek and a tap giggles; no life exists to decrement; `SC-e15s04-P0-02` |
| **T**ampering | `t55` `TimeOut` ends the find, or a timer def key can enable that | medium | the clock may display; it cannot end the step; `SC-e15s02-P0-02` |
| **T**ampering | a find voice value is concatenated into a `res://` audio path | medium | voice is a key through `AudioManager`; `Ids.is_valid` before any load; `SC-e15s02-P1-02` |
| **R**epudiation | a rejected paint/fill/find def fails silently | medium | existing `scene.def_rejected`, then L3 audit |
| **I**nformation disclosure | `t43` writes a screenshot or camera frame to `user://` | **high** if the gallery returns | **declined:** `t43` does not capture, save, load, or display photos; `SC-e15s03-P0-01` and `SC-e15s03-P0-02` assert no new image file and no camera type |
| **I**nformation disclosure | `t44` logs stroke coordinates as diary prose | low | `msg` stays an id (BUG-004); `SC-e15s01-P1-01` |
| **D**enial of service | peekaboo actors are spawned and never freed | **high** | the e13 despawn rule; `SC-e15s04-P0-01` orphan count returns to zero |
| **D**enial of service | a paint or fill threshold can never be reached, so the step has no exit | medium | threshold is data and reachable; home stays live (e12s03); `SC-e15s01-P0-01` |
| **E**levation | a template name in a def is loaded as a script path | medium | closed registry const from e12; id only |

## Template-by-template security note

| Template | Mints? | Navigates? | Writes the save? | Note |
|---|---|---|---|---|
| t44_paint | no | no | no | color is step data; no file, no photo |
| t43_color_fill | no | no | no | **declines `PhotoGallery`**; no `TakePhoto`, no `SaveToFile`, no `LoadPhotos`, no `DisplayPhotos` |
| t55_find | no | no | no | timer display cannot end the step; voice is a key |
| t27_memory | no | no | no | 4–6 cards; a mismatch flips back and does not punish |
| t38_peekaboo | no | no | no | no `DecrementLives`; spawned actors despawn |

## Residual risk

| Residual | Reason |
|---|---|
| Defs are not integrity-checked | they ship inside the app; validation catches our mistakes first (same as e12/e13) |
| A huge peekaboo cadence can cost frames | the orphan counter and the release-gate device pass bound it; it is not a separate control |

## Gate

No HIGH finding without a mitigation. The gallery decline is the one new disclosure threat, and it is
closed by the adaptation rule plus `SC-e15s03-P0-01` / `SC-e15s03-P0-02`. Tasks that implement `t43`,
`t38`, or the find voice resolver carry `security: medium` and their verify step includes "no new
security findings in affected paths".

### Scenario index

| ID | Asserts |
|---|---|
| SC-e15s01-P0-01 | paint reaches its def threshold and does not write `user://` |
| SC-e15s01-P1-01 | paint diary events use an id in `msg` |
| SC-e15s02-P0-02 | advancing time does not end `t55_find` |
| SC-e15s02-P1-02 | a path-like voice value is rejected; a valid key plays |
| SC-e15s03-P0-01 | `t43` source has no `PhotoGallery`, `TakePhoto`, `SaveToFile`, `LoadPhotos`, `DisplayPhotos`, and no def key for them |
| SC-e15s03-P0-02 | playing the `t43` scene creates no image file under `user://` |
| SC-e15s04-P0-01 | peekaboo orphans return to zero |
| SC-e15s04-P0-02 | no life counter and no `DecrementLives` |
