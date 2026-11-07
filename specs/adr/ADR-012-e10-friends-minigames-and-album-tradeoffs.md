# ADR-012: Friends Minigames and Sticker Album — Deliberate Trade-offs

<!-- story: e10s01 -->
<!-- story: e10s02 -->
<!-- story: e10s03 -->
<!-- story: e10s04 -->

- **Status:** Accepted
- **Date:** 2026-11-07
- **Recorded by:** e10 implementation
- **Relates to:** ADR-004, ADR-005, ADR-006, ADR-008, ADR-011

## Context

Epic e10 introduces three friend minigames (Pato pose matching, Urso magnetic puzzle, Pinguim catch) and the sticker & star album scene, completing playable scenes 14 through 17.

## Decisions

1. **Return-to-Origin Navigation Architecture:**
   - Minigames are entered from the Party (`Festa`) and return to the Party upon completion or when tapping `HomeButton`.
   - The Album is entered from the Village (`Vila`) and returns to the Village upon tapping `HomeButton`.
   - Direct cross-jumps between minigames and the album from reward screens are intentionally deferred (future nicety, not an MVP gap).

2. **TouchDraggable Mode Extensions:**
   - `SNAP_TO_SLOT`: Puzzle pieces track designated target slots with a snap radius, auto-locking on match and snapping back home on invalid release.
   - `CONTINUOUS_SCRUB`: Lane-constrained catching on 1D horizontal axes, preserving mouse-echo protection and clamping within lane margins.

3. **PoiTable Registry Extraction:**
   - Village POI constants and scene dictionaries are extracted from `VilaScene` into `PoiTable` (`res://scripts/core/poi_table.gd`).
   - `VilaScene` preserves aliases (`const POI_SCENES = PoiTable.SCENES`, etc.) to prevent churn in existing callers and tests.
   - This keeps `vila.gd` strictly below the 300-line bar (finishing at 294 lines, down from 299 lines).

4. **DoorBadge Rule Injection:**
   - `DoorBadge` supports both `"placed"` (default, reading placed furniture count) and `"stars"` (reading total stars across friends).
   - Component remains self-contained, reading `ProgressManager` directly with zero logic added to `VilaScene`.
   - Art texture swapping occurs strictly when state changes to prevent frame churn on unrelated progress events.

5. **Clamped Read Protection for Stars:**
   - Friend stars are capped at 5 per friend (`0..5`).
   - Tampered save files reading out-of-bounds values are clamped at read time via `lit_stars(id) = clampi(stars, 0, 5)`.

## Consequences

- Navigation flow remains predictable and children are never trapped in unescapable loops.
- All minigames and album scenes meet strict F.I.R.S.T. unit and integration test standards with zero real-time flakiness via `manual_step` and `advance()`.
