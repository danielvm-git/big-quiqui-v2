# ADR-005: Strongly-Typed `SaveData` Resource & Mandatory `TestReset` Isolation

<!-- story: e01s03 -->
- **Status:** Accepted
- **Retroactive:** yes — recorded after the decision was already in force in code
- **Date:** 2026-11-04

## Context
In PRs #7–#16 (`ab7750f`), `ProgressManager.save_progress()` omitted `"outfits"` from JSON serialization while unit tests passed because RAM was never cleared before `load_progress()`, and 5 test files overwrote the developer's live `user://progress.json`.

## Decision
`ProgressManager` serializes a single typed `SaveData` class (`to_dict()` / `from_dict()`), writes atomically via `user://progress.json.tmp` → rename, and every GUT test inherits `TestReset` which redirects persistence to `user://test_progress.json` and verifies disk round-trips after `reset_in_memory_only()`.

## Consequences
100% round-trip fidelity between RAM and disk, and zero test pollution of real user saves.

## Amendment 2026-11-06 — data compatibility, migration and rollback

The audit (item E24) asked for backward-compatibility and rollback rules for data changes. They are:

| Situation | Rule |
|---|---|
| **Adding a field** | add it with a default in `SaveData`; no version bump; old files load unchanged |
| **Renaming or reshaping a field** | bump `SaveData.version`, add the old field for **one release**, migrate at load, keep the getter working |
| **Removing a field** | only in the release *after* the migration shipped, and only when `version` proves the migration ran |
| **Unknown fields on load** | ignored, not dropped: a downgrade must not destroy data a newer build wrote |
| **Invalid ids on load** | dropped silently with one `save.load_failed`-adjacent log; the room stays playable (T-E05-01) |
| **Rollback** | the save is forward-only: a downgrade reads whatever it understands and preserves the rest. There is no "restore previous save" because there is no server and no backup store — the rollback unit is the **release**, and `big-release`'s tag is the point of return |

`user://progress.json` is written atomically (`.tmp` + rename), so a crash mid-write leaves the previous
file intact — the practical rollback for a single device.
