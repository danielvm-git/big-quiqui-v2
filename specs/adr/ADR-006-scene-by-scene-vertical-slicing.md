# ADR-006: Scene-by-Scene Vertical Slicing (`e01`–`e11`)

<!-- story: e01s01 -->
- **Status:** Accepted
- **Date:** 2026-11-04

## Context
Horizontal epics ("build all managers first, then build all components, then build all scenes") delay visual feedback and hide integration defects until late in the project.

## Decision
Every epic (`e01` through `e10`) is a complete vertical slice that ends with at least one bootable, playable, visually verifiable `.tscn` scene tested end-to-end with `TouchSim`, `FsmProbe`, and `GeometryOracle`. Epic `e01` establishes the core harness and immediately delivers playable `TitleScene` (`res://scenes/titulo.tscn`).

## Consequences
After finishing any epic, `godot --path game` launches a playable game where the newly added scene can be played and verified immediately.
