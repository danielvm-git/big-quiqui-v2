# BUG-056 — a placement she never bought survives the loader

<!-- story: e11s01 -->
- **Severity:** high · **Priority:** P0 · **Scope:** security · **Status:** fixed
- **Found by:** e11s01 `INV-01` (`unit/test_save_fuzz.gd`)

## Symptom

`SaveData.from_dictionary` keeps every syntactically valid placement, whether or not the id
appears in `owned_furniture`. `ProgressManager.placed_count()` counts them, and
`FestaScene` opens the party at `PARTY_MIN_PLACED = 5`. An edited save therefore unlocks the
party while `CasinhaScene` (correctly) renders none of those pieces: the room is empty and
the door is open.

## Root cause

`_clean_placement` validated the id shape and deduplicated, but never cross-checked
ownership. BUG-048 fixed the duplicate half of this bypass and left the ownership half.

## Failing test

`test_a_placement_the_child_never_bought_is_dropped`: expected 1 placement, got 2
(`cama` survived alongside the owned `mesa`).

## Fix

`_clean_placement(raw, owned)` now drops any entry whose id is not in the cleaned
`owned_furniture`; `clamp_to_rules` cleans ownership first so the RAM-side repair agrees
with the loader.

## Verification

`test_save_fuzz.gd` green, `test_persistence_invariants.gd` green, and the e09 suites
(`test_casinha_scene`, `test_placement_oracle`, `test_e09_epic_e2e`) still green —
a legitimate purchase is still placeable.
