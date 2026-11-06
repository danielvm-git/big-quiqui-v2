---
bug_id: BUG-033
status: fixed
severity: low
scope: tests
title: test_casa_scene.gd was 349 lines, over the project's 300-line ceiling, and had regrown after every epic
---
# BUG-033: the hub suite outgrew the house ceiling

<!-- story: e02s03 -->

**Found by:** e07 post-epic review, third pass (file-size sweep while checking the new files against the
300-line guideline).

## Problem

`game/tests/integration/test_casa_scene.gd` was **349 lines**. `HOTSPOTS_LATEST.md` (generated at the end
of e06) already showed it at 333 — the file has been the rank-1 hotspot for two epics and every scene that
added a door added tests to it. e07 added the hub↔cycle coupling and pushed it further: it is the single
largest test file in the project and the one an agent must read first when touching the hub.

The guideline is not enforced by `gdlint` or by a gate, which is exactly why it drifted.

## Root Cause

The hub test file accumulated three unrelated subjects: layout/oracle/inventory, input/navigation, and
care-loop coupling. Nothing required a split, so the cheapest edit was always "append to the file".

## Fix

Split by subject, no test renamed or dropped (408 tests before and after):

- `test_casa_layout.gd` (new, 109 lines): `GeometryOracle` on all three aspects, the node inventory, the
  declared groups, the painted height on iPad, and the wish bubble never covering her face.
- `test_casa_scene.gd` (277 lines): door input, mouse-echo filtering, navigation to each room, music on
  arrival, the idle wish, the dots/highlight coupling, and the e07 celebration-arrival guard.

Both files keep their `# story: e02s03` tag; the new one states in its header where the other half lives.

## Verification

`wc -l` 349 → 277 + 109; `gdlint` + `gdformat --check` clean; GUT **38 scripts / 408 tests / 2154
asserts** green (the script count rose by exactly the new file, and the test count did not change).
