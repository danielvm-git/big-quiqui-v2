---
bug_id: BUG-052
status: fixed
severity: low
scope: code
title: Dead code and unused symbols in e09: _pending_id, last_bought, PLACE_SFX, ART_ROOT and redundant price_coins
---
# BUG-052: Dead code and unused symbols in e09: _pending_id, last_bought, PLACE_SFX, ART_ROOT and redundant price_coins

<!-- story: e09s01 -->

**Found by:** e09 post-epic review.

## Evidence

1. `_pending_id` in `mercado.gd:42, 115` is assigned but never read.
2. `last_bought` in `mercado.gd:38, 116` is assigned but never read.
3. `PLACE_SFX` in `casinha.gd:11` is defined but never used (the scene uses `POP_SFX`).
4. `ART_ROOT` in `furniture_prop.gd:9` is defined but never used (art loaded via `item.texture()`).
5. `price_coins` in `furniture_data.gd:9` and all 12 `.tres` files is dead data, as all pricing is governed by `EconomyData.furniture_prices` via FIX-05.

## Fix

Remove dead variables/constants and document the single source of truth for pricing in `FurnitureData`.
