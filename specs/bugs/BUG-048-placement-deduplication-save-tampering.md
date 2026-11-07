---
bug_id: BUG-048
status: fixed
severity: medium
scope: security
title: SaveData._clean_placement does not deduplicate IDs, allowing tampered saves to bypass party lock
---
# BUG-048: SaveData._clean_placement does not deduplicate IDs, allowing tampered saves to bypass party lock

<!-- story: e09s02 -->

**Found by:** e09 post-epic review.

## Evidence

In `game/scripts/resources/save_data.gd:103-116`, `_clean_placement` cleans coordinates and valid IDs from an untrusted Array, but does not deduplicate IDs like `_clean_id_array` does. A tampered save with repeated entries of the same ID causes `placed_furniture` to contain multiple duplicates. This inflates `placed_count()`, allowing a tampered save with 1 piece placed 5 times to unlock `HousePartyScene` (`PARTY_MIN_PLACED = 5`), violating the threat model ("placed_furniture grows by one entry per piece (12 max), so the save cannot be inflated by replays", `specs/security/epics/e09/THREAT_MODEL.md:41`).

## Fix

Deduplicate IDs in `SaveData._clean_placement` so each furniture ID appears at most once in `placed_furniture`.
