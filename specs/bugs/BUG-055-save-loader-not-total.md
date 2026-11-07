# BUG-055 — the save loader is not total

<!-- story: e11s01 -->
- **Severity:** high · **Priority:** P0 · **Scope:** persistence · **Status:** fixed
- **Found by:** e11s01 `INV-01` adversarial save corpus (`unit/test_save_fuzz.gd`)

## Symptom

A `progress.json` whose scalar field holds `null`, an array or a dictionary makes
`SaveData.from_dictionary` raise `Invalid call. Nonexistent 'int' constructor`. The call
returns `null`, `ProgressManager.data` becomes `null`, and the first money path that reads
`data.coins` (`_apply`, `buy_furniture`, `place_furniture`) dereferences null.

A child never produces this file, but a kill during a partial write, a restore from an old
backup, or a tampered save all can. ADR-005 promises the loader is the *only* place an
untrusted file becomes game state; it must therefore be total.

## Root cause

`int(raw.get("coins", 0))` and `float(entry.get("x", 0.5))` are called on `Variant` values
taken straight from the parsed JSON. `int(null)` is a runtime error in GDScript, not `0`.

## Failing test (red first)

`game/tests/unit/test_save_fuzz.gd::test_every_corpus_entry_loads_into_a_clean_save`
with corpus entry 5 `{"coins": null, "tickets": null, "completed_cycles": null}`:
`Expected [<null>] to be anything but NULL: entry 5 produced no save`.

## Fix

`SaveData` gained `_int_of` / `_float_of` coercers: `int`, `float` (finite only), `String`
(via `to_int`/`to_float`), `bool`, everything else → the declared default. Every scalar in
`from_dictionary`, `clamp_to_rules` and `_clean_stars` goes through them.

## Verification

`test_save_fuzz.gd` 8/8 green; `test_random_dictionaries_never_break_the_invariants`
walks 200 seeded hostile dictionaries with zero violations.
