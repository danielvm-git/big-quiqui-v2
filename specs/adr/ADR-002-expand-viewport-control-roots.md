# ADR-002: `expand` Aspect Viewport & 100% `Control` Scene Roots

<!-- story: e01s01 -->
- **Status:** Accepted — the **composition clause is superseded by ADR-008**; the viewport contract below still stands
- **Date:** 2026-11-04

## Context
iPad screens have a `4:3` aspect ratio (`2048×1536`), whereas the base canvas is `1920×1080` (`16:9`). Using `stretch/aspect="keep"` left 25% black letterbox bars on iPad, and mixing `Node2D` roots with `Control` roots caused bath foam and mouth drop targets to drift off-character on iPad (`BUG-2026-11-02T210000`).

## Decision
Configure `window/stretch/mode="canvas_items"` and `window/stretch/aspect="expand"` from Commit 1. Every `.tscn` scene MUST use a `Control` root (`PRESET_FULL_RECT`) with a full-bleed background `TextureRect` (`EXPAND_IGNORE_SIZE` + `STRETCH_KEEP_ASPECT_COVERED`).

Composition is **not** fixed here: the former MUST for a centered `SafeStage` container is superseded by [ADR-008](ADR-008-edge-anchored-responsive-composition.md), which composes with anchors expressed as ratios of the canvas and introduces no `SafeStage` node.

## Consequences
Zero letterbox bars on both 16:9 and 4:3 iPad; verified automatically in CI by `GeometryOracle`.
Composition conformance (rig height ratio, feet line, 36 px insets) is verified by the same oracle
against a per-scene spec — see ADR-008.
