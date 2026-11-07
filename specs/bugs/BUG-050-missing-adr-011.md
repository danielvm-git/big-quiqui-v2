---
bug_id: BUG-050
status: fixed
severity: medium
scope: docs
title: ADR-011 registered in state.yaml is missing from specs/adr/
---
# BUG-050: ADR-011 registered in state.yaml is missing from specs/adr/

<!-- story: e09s01 -->

**Found by:** e09 post-epic review.

## Evidence

In `specs/state.yaml:372-377`, `ADR-011` is registered in `decisions`:
```yaml
- id: ADR-011
  summary: >-
    Store and casinha trade-offs: prices are EconomyData (FIX-05) with a floored zero...
```
However, the actual file `specs/adr/ADR-011-store-casinha-and-party-tradeoffs.md` was never created on disk.

## Fix

Write and commit `specs/adr/ADR-011-store-casinha-and-party-tradeoffs.md` documenting the architecture and trade-offs of the store, casinha, and house party scenes.
