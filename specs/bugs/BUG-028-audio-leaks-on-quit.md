---
bug_id: BUG-028
status: fixed
severity: low
scope: core
title: AudioManager never releases its streams, so every quit leaked four objects and two resources and the Ogg file stayed "in use"
---
# BUG-028: the music outlives the process

<!-- story: e01s02 -->

**Found by:** e07 post-epic review, `verify-work` cold start (not by a test — no gate could see it).

## Problem

`godot --headless --path game --quit-after 3` printed, on `main` and on the fix branch alike:

```
WARNING: 4 ObjectDB instances were leaked at exit
ERROR: 2 resources still in use at exit
Leaked instance: AudioStreamPlaybackOggVorbis / OggPacketSequence / OggPacketSequencePlayback / AudioStreamOggVorbis
Resource still in use: res://assets/audio/music/tema_principal.ogg
```

Godot frees the tree, then the resource cache; the music player was still playing when its
`AudioStreamPlayer` was destroyed, so the playback and the Ogg sequence survived the cache clear.
`AudioManager` had no teardown at all.

`AUDIT-e07-epic.md` recorded the cold start as "**0** errors or warnings", which this run falsifies.

## Evidence

The warning reproduced identically on `main` (`git worktree add /tmp/wt-main main`) and on
`fix/e07-postepic-review`, so it is not a regression from this pass — it is a defect the epic audit
reported as clean.

## Root Cause

`reset()` (the test seam) stopped the players and nulled their streams, but nothing called that logic on
the quit path, and the behaviour of "quit while playing" was never asserted anywhere.

## Fix

- Extracted `release_streams()` (stop + drop stream + reset volume) out of `reset()`.
- `_exit_tree()` releases them, so the players are silent and empty before the engine collects resources.
- Two tests pin it: every player stopped with a null stream, and `_exit_tree()` is safe when called twice
  or with no players.

## Verification

- `test_audio_manager.gd::test_release_streams_stops_every_player_and_drops_its_stream`,
  `test_exit_tree_is_safe_twice_and_without_players` — 408/408 green.
- The actual smoke: `godot --headless --path game --quit-after 3` now prints **no** leak warning and
  **no** "resources still in use" error (was 4 + 2 before).
