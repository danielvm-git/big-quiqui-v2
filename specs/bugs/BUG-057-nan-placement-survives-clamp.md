# BUG-057 — NaN survives the placement clamp

<!-- story: e11s01 -->
- **Severity:** medium · **Priority:** P1 · **Scope:** persistence · **Status:** fixed
- **Found by:** e11s01 `INV-01` (`unit/test_save_fuzz.gd`)

## Symptom

A placement with `"x": NaN` reaches the room as `NAN`. `clampf(NAN, 0.0, 1.0)` returns
`NAN` (comparisons against NaN are false, so neither bound applies), and a `NAN` assigned to
a `Control.position` produces an undefined transform — the piece vanishes, and the placement
oracle reports a ratio outside the room forever after.

## Root cause

`clampf` bounds but does not sanitise. Infinity has the same shape.

## Failing test

`test_every_corpus_entry_loads_into_a_clean_save` — corpus entry
`{"placed_furniture": [{"id": "mesa", "x": NAN, "y": INF}]}`:
`placement mesa out of range on x: nan`.

## Fix

`_clamp_ratio` returns the declared default (`0.5`) when the value is not finite, then
clamps. Used by `_clean_placement` and `clamp_to_rules`.

## Verification

`SaveCorpus.violations` asserts `not is_nan(value)` and `0 <= value <= 1` for every axis.
