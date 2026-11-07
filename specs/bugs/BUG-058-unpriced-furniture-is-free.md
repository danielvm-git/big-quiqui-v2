# BUG-058 — an unpriced piece is a free piece

<!-- story: e11s01 -->
- **Severity:** medium · **Priority:** P1 · **Scope:** code · **Status:** fixed
- **Found by:** e11s01 `INV-04` (`unit/test_economy_tables.gd`)

## Symptom

`FurnitureCatalog.price_of` returns `0` for an id with no entry in
`EconomyData.furniture_prices`. `MercadoScene.try_buy` only refuses a negative price, so
`ProgressManager.buy_furniture(id, 0)` hands the piece over for free. Adding a thirteenth
catalogue piece and forgetting its price is a one-line mistake that silently gifts it.

## Root cause

The docstring says "a missing or negative entry is 0, never a gift that mints coins" — it
confused *not minting coins* (negative price) with *not being free* (zero price). `-1` is the
"do not charge" sentinel the store already understands.

## Failing test

`test_a_missing_price_is_refused_not_free`: `price_of("tapete", economy_without_it) == 0`.

## Fix

`price_of` returns `-1` when the table has no entry (or a negative one); `MercadoScene`
already treats `< 0` as "not buyable". `INV-04` additionally asserts the table covers the
catalogue exactly, so the sentinel is a safety net, not the normal path.

## Verification

`test_economy_tables.gd` 10/10 green; `test_mercado_scene.gd` still green (a priced piece
still costs coins).
