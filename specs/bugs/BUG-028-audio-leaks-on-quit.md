---
bug_id: BUG-028
status: wontfix
severity: low
scope: core
title: With music playing, the engine reports four leaked audio objects and two resources at exit; no game-side change removes it
---
# BUG-028 (wontfix): the exit report from the audio teardown

<!-- story: e01s02 -->

**Found by:** e07 post-epic review, `verify-work` cold start (no gate can see it).

## Problem

`godot --headless --path game --quit-after 3` prints, identically on `main` and on any branch:

```
WARNING: 4 ObjectDB instances were leaked at exit
ERROR: 2 resources still in use at exit
Leaked instance: AudioStreamPlaybackOggVorbis / OggPacketSequence / OggPacketSequencePlayback / AudioStreamOggVorbis
Resource still in use: res://assets/audio/music/tema_principal.ogg
```

`AUDIT-e07-epic.md` recorded the cold start as "**0** errors or warnings", which this falsifies.
`AudioManager` had no teardown at all, so the first hypothesis (the node is holding the stream) was worth
testing properly.

## What was actually tried (three experiments, reverted one by one)

| # | Change | Result |
|---|---|---|
| 1 | `_exit_tree()` → stop every player and set `stream = null` | **4 leaked / 2 resources — unchanged** |
| 2 | also `free()` the players and clear the pools in `_exit_tree()` | **unchanged** |
| 3 | title scene never calls `play_music` (the only Ogg playback in the boot path) | **0 leaks, 0 resources** |
| 4 | debug probe inside `_exit_tree()` | all 11 players report `playing == false` **before** the release runs |

So: the playback is real and it is the cause (3), but by the time application teardown runs the audio
server has already stopped it (4) and the reference that keeps the `OggPacketSequence` alive is **held
outside the scene tree** (1 and 2 change nothing).

## Decision

**wontfix at the application layer.** The leaked instances are engine audio-teardown internals released
after the resource cache in a `--quit-after` shutdown; no GDScript can drop them. Two things were kept
because they are correct regardless:

- `release_streams()` (stop + drop stream + reset volume) extracted from `reset()`, used by `reset()` and
  by a best-effort `_exit_tree()` — a real quit should not leave the audio session open;
- two tests pinning it (`test_release_streams_stops_every_player_and_drops_its_stream`,
  `test_exit_tree_is_safe_twice_and_without_players`).

The ledger is not "silenced": the report is documented here, the audit claim is corrected in
`POSTEPIC-e07-2026-11-06.md`, and the comment on `release_streams()` says explicitly that it does not fix
this symptom.

## Verification

- The four experiments above, each reproducible with `godot --headless --path game --quit-after 3`
  (and `--verbose` for the instance names).
- Exit code is `0` in every case; the game itself is unaffected.
- If a future Godot version changes this, the report will disappear on its own — the two tests and the
  documented experiment table are how we will notice without re-deriving it.
