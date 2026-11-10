# BUG-063 — leaving a data room to a legacy room only worked through `request_def`

<!-- story: e12s04 -->
- **Severity:** medium · **Priority:** P1 · **Scope:** navigation · **Status:** fixed
- **Found by:** e13 review round 1, while mounting `home_map` (a map door names a legacy scene id)

## Symptom

A map door whose scene id was a legacy room (`kitchen` is data, `bathroom` is not yet) did nothing:
the player asked `SceneManager.request_def` for an id that has no def.

## Root cause

`ScenePlayer._exit_room` knew one door. The scene catalog already knows which ids are legacy
scenes, and `SceneManager.request_scene` is the door for them.

## Failing test

`unit/test_scene_nav.gd`: opening a legacy id recorded no request.

## Fix

`SceneNav.open(manager, scene_id)` picks `request_def` for a data room and `request_scene` for a
legacy room, and does nothing for an unknown id (it logs). `ScenePlayer._exit_room` and `t25_map`
use it, so the 17-room migration in e14 changes one table, not every caller.

## Verification

`test_scene_nav` and `test_map_player_e2e` pass.
