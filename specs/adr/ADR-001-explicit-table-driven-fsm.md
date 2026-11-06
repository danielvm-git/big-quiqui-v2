# ADR-001: Table-Driven Finite State Machine (`Fsm`) for All Stateful Subsystems

<!-- story: e01s02 -->
- **Status:** Accepted
- **Retroactive:** yes — recorded after the decision was already in force in code
- **Date:** 2026-11-04

## Context
In v0.1–v1.x of `big-quiqui`, implicit state machines encoded via boolean flags (`_is_transitioning`, `_is_dragging`, `_is_reacting`) and unguarded transition methods (`step_completed()` with no `expected_state`) caused double-advances (`44fa150`), soft-locked celebrations (`BUG-2026-11-02T120000`), and frozen scene transitions.

## Decision
We mandate a single reusable `Fsm` class (`res://scripts/core/fsm.gd`) defined by an explicit `legal_edges: Dictionary` and `max_dwell_sec: Dictionary`. Calling `transition_to(current_state)` is an idempotent no-op returning `false`. All async/timer transitions MUST call `transition_from(expected_state, next_state)`. Every transition emits a structured `Log.event("fsm.transition", ...)`.

## Consequences
Illegal transitions and double-tap race conditions are prevented by construction and immediately observable via `FsmProbe` in GUT tests.
