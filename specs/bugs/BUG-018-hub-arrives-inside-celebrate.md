---
bug_id: BUG-018
status: fixed
severity: high
scope: core
title: The Casa is whitelisted from the detour guard but never closes the cycle, so a hub mounted during CELEBRATE has six dead doors
---
# BUG-018: the hub can mount inside a live CELEBRATE cycle

<!-- story: e07s03 -->

**Found by:** e07 post-epic review (reviewer A should-fix 2; reviewer B consider 10 is the same
wiring, ordering half).

## Problem

`SceneManager._close_celebrate_for_detour()` skips the two legitimate `CELEBRATE` targets, the
celebration and the hub (`CASA_PATH`). The exception for the celebration is required — the reward is
paid on entry to `CELEBRATE` and the celebration mounts on purpose. The exception for the hub was not
paired with anything: `CasaScene` never closed the cycle, so a Casa request that landed while the loop
was still in `CELEBRATE` (a parked request arriving during the SLEEP→celebration fade, an album detour
back to the hub, a direct mount) produced a hub where **every** care door refused — the exact brick
T-E07-05 exists to prevent, reachable through the door the guard trusted.

Second half, same function: the guard ran **before** the request was validated, so a duplicate request
for the scene already on stage (`REASON_SAME_SCENE`, refused) also closed the cycle. A request that is
refused is not a detour: the child never left the celebration.

## Evidence

`game/scripts/autoloads/scene_manager.gd:108` (guard first) and `game/scripts/scenes/casa.gd:_ready`
(no cycle check). Red tests before the fix: `state_id()==CELEBRATE` after mounting the hub, FEED door at
`modulate.a == 0.72`, and `IDLE` after a refused duplicate request.

## Root Cause

The guard was attached to *requests*, and the hub is a target the guard deliberately does not intercept.
Nothing owned the arrival side. e07s03's tests covered only the album detour, so both whitelisted paths
were untested — the author's defect #2 (the whitelist) was found by luck, as reviewer A noted.

## Fix

1. `SceneManager.request_scene()` validates first, then runs the guard: a refused request changes nothing.
2. `CasaScene._ready()` calls `CareLoopManager.close_celebrate_if_needed()`, so the hub covers every route
   into it, including direct mounts in tests. The whitelist stays: the hub *is* the cycle's own closure,
   it just closes it on arrival.

## Verification

- `game/tests/integration/test_casa_scene.gd::test_arriving_during_the_celebration_closes_the_cycle`
- `game/tests/unit/test_care_loop_manager.gd::test_a_rejected_request_is_not_a_detour`

Both red before, green after. Suite 399/399.
