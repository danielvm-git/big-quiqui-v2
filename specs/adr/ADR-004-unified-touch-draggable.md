# ADR-004: Unified `TouchDraggable` & Mouse-Echo Filtering (`device == -1`)

<!-- story: e03s01 -->
- **Status:** Accepted
- **Retroactive:** yes — recorded after the decision was already in force in code
- **Date:** 2026-11-04

## Context
In the legacy codebase, drag logic was duplicated across 4 scripts (`drag_item.gd`, `bath_scene.gd`, `puzzle_piece.gd`, `casinha_scene.gd`), and Godot's `emulate_touch_from_mouse = true` caused every tap/drop to fire twice (`InputEventScreenTouch` + synthesized `InputEventMouseButton` with `device == -1`).

## Decision
All touch buttons (`TapButton`) and draggable props (`TouchDraggable`) filter out `event is InputEventMouse and event.device == -1` when touch events are active, claim a single `_owner_touch_index: int`, and support 4 configurable behavior modes (`CONSUME_ON_DROP`, `CONTINUOUS_SCRUB`, `SNAP_TO_SLOT`, `FREE_PLACEMENT`).

## Consequences
Zero duplicated drag code across scenes and guaranteed single-fire execution under `TouchSim` double-tap/mouse-echo tests.
