# Threat Model — e05 (Closet & Accessories, DRESS Scene)

<!-- story: e05s01 -->
**Skill:** `security-review` (build-epic Step 0) · **Date:** 2026-11-06
**Surface:** Godot 4.7 client, 100 % offline, iPadOS + desktop, no accounts, no network.
**Delta over e04:** the first **layered character composition** (outfit under the face, accessories
over it), the first **persistent choice** (what she is wearing survives a restart), the first
`SNAP_TO_SLOT` gesture (equip by dropping into a slot), and the first scene whose content is **data**
(an outfit/accessory catalog rather than fixed nodes).

## Assets

| Asset | Why it matters | Where it lives |
|---|---|---|
| `SaveData.outfit_id` + accessory ids | the only durable record of a child's choice; a corrupt id must never break the save load | `user://progress.json` |
| Care cycle state | DRESS must be credited exactly once, or the ladder drifts | runtime |
| Coin / ticket counters | the DRESS reward lands here (BUG-007 clamps) | `user://progress.json` |
| Expression layer | an outfit drawn **above** the face would hide the only feedback a pre-reader has (ADR-003) | runtime |
| Art ids | ids reach `res://` paths, so the id contract is also a path contract | `res://assets/art` |
| Diary | new `dress.equip` events, ids only | device only |

## Trust boundaries

1. Engine ↔ filesystem (`user://` only) — **now with a durable outfit choice**.
2. Input ↔ scene logic — **new `SNAP_TO_SLOT` gesture**: drop into a slot to equip.
3. Data files ↔ runtime (`SaveData`, JSONL) — **new fields**, so the loader now has to be tolerant of
   values written by an older or a tampered build.
4. `res://` art paths ← id catalogue (const data, never user input).
5. **New: layer order ↔ readability.** The rig composes body → outfit → expression → accessories. A
   layer-order regression is invisible in unit tests that only assert "outfit visible".

## STRIDE

| Category | Threat (concrete) | Likelihood | Mitigation required in e05 |
|---|---|---|---|
| **S**poofing | none: no identity, no accounts | n/a | none needed |
| **T**ampering | **layer inversion**: outfit or accessory drawn above the expression hides her face (ADR-003) | **high** | z-order asserted with the expression *visible over* the outfit, and a test that swaps the layers to prove the assertion can fail |
| **T**ampering | **tampered outfit id** in the save (`../`, uppercase, 200 chars) breaks the load or builds a bad path | **high** | every id goes through `Ids` (`\A[a-z0-9_]{1,64}\z`) before `res://` assembly; unknown ids are dropped, not crashed on (T-E05-01) |
| **T**ampering | **double equip / double credit**: the same outfit equipped twice credits DRESS twice | medium | equipping is idempotent; `complete_step(DRESS)` guarded by the care state and a `credited` flag (T-E05-02) |
| **R**epudiation | a parent cannot tell what she is wearing when something looks off | low | `dress.equip` logs the id; ids only, no prose |
| **I**nformation disclosure | accessory ids in the diary reveal nothing personal | low | same writer and redaction as e01–e04 |
| **D**enial of service | **unwritable or corrupt save** loses the outfit and the room looks broken | medium | load failure falls back to the default outfit, the room still plays, one log event |
| **D**enial of service | **freed slot target** mid-drag wedges the shared finger owner (e03/e04 class) | medium | `abort()` on scene exit and on stage reset; the latch release is already proven, re-asserted here |
| **D**enial of service | a missing outfit art file hides the character | low | missing art logs and falls back to the body layer, never to an invisible rig |
| **E**levation of privilege | id → path traversal through the catalog | low | `Ids` is `\A…\z` (BUG-013 fix); catalogue ids are consts |

## Kids-specific threats (delta)

| Threat | Mitigation |
|---|---|
| Changing clothes hides her face, so she stops feeling like a character | expression layer is asserted above the outfit on every canvas, and the face is re-applied after an equip |
| "Did it work?" after a drop that missed the slot | the item animates back AND the rig flashes the new outfit; the pop SFX fires only on success |
| Accessories pile up until the character is a blob | a slot per accessory kind (head, neck, eyes), so a second hat **replaces** the first instead of stacking |
| Losing the look on restart | the choice is persisted and reloaded before the first frame of the room |

## Findings for e05 implementation (must be closed in-story)

| ID | Finding | Severity | Story | Required action |
|---|---|---|---|---|
| T-E05-01 | Ids from the save must be validated and unknown ones dropped, never crashed on | **HIGH** | e05s01 | `SaveData` load drops invalid ids; test with `../`, uppercase, 65 chars |
| T-E05-02 | DRESS credited exactly once, and equipping the same outfit twice is idempotent | **HIGH** | e05s02, e05s03 | `credited` guard + care-state check; replay test |
| T-E05-03 | Expression must stay above outfit and accessories | **HIGH** | e05s01, e05s03 | z-order test plus a mutation that swaps layers and must fail |
| T-E05-04 | A corrupt/unwritable save must not break the room | MED | e05s01 | fall back to the default outfit, log once, keep playing |
| T-E05-05 | One accessory per slot: a second hat replaces the first | MED | e05s02 | slot keyed by kind; test equipping two hats |
| T-E05-06 | Accessories must not cover the mouth zone (it is a drag target in e03) | MED | e05s02 | assert the mouth zone is not fully covered by any accessory art |
| T-E05-07 | No diary line per drag motion, and no art path in the diary | LOW | e05s02 | log on equip only, ids only |

## Out of scope (with reason)

- Network exfiltration: no network stack; the e01 CI grep control gates every PR.
- Economy changes: DRESS pays through the existing counters and clamps (BUG-007).
- `FREE_PLACEMENT` (e09) and furniture placement: the closet equips onto the character, not the room.
- Multi-outfit layering (a hat + a dress + glasses at once is supported; two dresses are not: one outfit
  slot, by design).
