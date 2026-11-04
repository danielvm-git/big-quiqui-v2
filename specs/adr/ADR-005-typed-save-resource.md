# ADR-005: Strongly-Typed `SaveData` Resource & Mandatory `TestReset` Isolation

<!-- story: e01s03 -->
- **Status:** Accepted
- **Date:** 2026-11-04

## Context
In PRs #7–#16 (`ab7750f`), `ProgressManager.save_progress()` omitted `"outfits"` from JSON serialization while unit tests passed because RAM was never cleared before `load_progress()`, and 5 test files overwrote the developer's live `user://progress.json`.

## Decision
`ProgressManager` serializes a single typed `SaveData` class (`to_dict()` / `from_dict()`), writes atomically via `user://progress.json.tmp` → rename, and every GUT test inherits `TestReset` which redirects persistence to `user://test_progress.json` and verifies disk round-trips after `reset_in_memory_only()`.

## Consequences
100% round-trip fidelity between RAM and disk, and zero test pollution of real user saves.
