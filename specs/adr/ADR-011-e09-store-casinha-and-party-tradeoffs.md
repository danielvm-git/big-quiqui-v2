# ADR-011: Store, Casinha, and House Party Scenes — Deliberate Trade-offs

<!-- story: e09s01 -->
<!-- story: e09s02 -->
<!-- story: e09s03 -->
<!-- story: e09s04 -->

- **Status:** Accepted
- **Date:** 2026-11-07
- **Recorded by:** e09 post-epic review (BUG-050)
- **Relates to:** ADR-004, ADR-005, ADR-008, ADR-010, `specs/security/epics/e09/THREAT_MODEL.md`

## Context

Epic e09 introduces the first store purchase sink (coins -> owned furniture), free furniture placement
with canvas-independent ratios (`0..1`), and an unlock gate for the village party scene based on placed pieces.

## Decisions

1. **Pricing via EconomyData (FIX-05):**
   Furniture pricing is owned by `EconomyData.furniture_prices` with a floored `0`. The exported `price_coins` field on `FurnitureData` is preserved for schema compatibility but the runtime source of truth is always `EconomyData`. A price of 0 still requires the explicit purchase flow (never granted automatically).

2. **Atomic Purchase Guard:**
   `ProgressManager.buy_furniture` refuses prior to any mutation if the piece is already owned, coins are insufficient, or the ID is malformed. A successful purchase writes atomically to disk and emits one `progress_changed` event.

3. **Normalized 0..1 Room Ratios:**
   `TouchDraggable.Mode.FREE_PLACEMENT` reports drops as ratios relative to `placement_area` bounding rect (`0.0..1.0`). No raw pixel values are persisted. Saved coordinates are restored accurately across 16:9 and 4:3 iPad canvases within a 2% ratio tolerance (`PlacementOracle`).

4. **Placement Deduplication and Ownership Integrity:**
   `SaveData._clean_placement` deduplicates placed furniture entries by item ID. Placements on disk must belong to owned pieces, preventing tampered saves from spoofing placement counts.

5. **Single Owner for Party Unlock Threshold:**
   `PARTY_MIN_PLACED = 5` is defined centrally in `HousePartyScene`. Both the scene itself and the village door component (`DoorBadge`) check `ProgressManager.placed_count() >= 5`, guaranteeing visual and behavioral consistency without hardcoding party state in `vila.gd`.

## Consequences

- Review suggestions asking for pixel-based coordinates, unauthenticated free placements, or bypass of the `ProgressManager` atomic write pipeline are rejected.
- Village scenes retain zero line-count bloat by encapsulating door status into `DoorBadge`.
