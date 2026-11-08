---
bug_id: BUG-019
status: fixed
severity: medium
scope: ui
title: Both new scenes restart the shared theme under the celebration voice, against the threat model's own mitigation
---
# BUG-019: the bedroom and the celebration restart the theme they arrive on

<!-- story: e07s01 -->
<!-- story: e07s02 -->

**Found by:** e07 post-epic review (reviewer B should-fix 5).

## Problem

`SleepScene._ready()` and `CelebrationScene._ready()` both called
`AudioManager.play_music(main_theme.ogg)` unconditionally. That is the track the hub is already
playing, and `play_music` **always** starts a crossfade from a new player — the seam the manager
documents itself (`audio_manager.gd:152`: "`play_music` always restarts, so a scene that must not
restart a theme asks first", which is exactly what `casa.gd:_restore_music()` does).

Effect: the theme restarts from 0 s twice per cycle, and the celebration's restart lands directly
under `celebration_congrats.ogg`. The e07 threat model promises the opposite in its kids-specific table:
"Celebration is scary-loud → one burst, one voice clip, **music continues rather than restarting**".

## Evidence

Red tests before the fix (`_active_music` swapped on mount, 4 assertion failures):
`test_the_bedroom_does_not_restart_the_theme_it_arrives_on`,
`test_the_celebration_does_not_restart_the_theme_it_arrives_on` — both assert the active player is
unchanged and that the theme is still playing.

## Root Cause

The two new scenes copied the room pattern (`_play_stream("play_music", …)`) from e03–e06, where each
room has its own theme; these two rooms share the hub's, so "start my theme" was the wrong contract.

## Fix

`_play_music_once()` in both scenes: absent art is logged, and the theme is only started when
`AudioManager.is_music_playing(stream)` is false.

## Verification

Both tests red before, green after; suite 401/401.
