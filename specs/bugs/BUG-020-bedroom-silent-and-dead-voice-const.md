---
bug_id: BUG-020
status: fixed
severity: medium
scope: ui
title: The bedroom carried a dead VOICE_PATH constant and was the only care room that made no sound
---
# BUG-020: dead constant, silent bedroom

<!-- story: e07s01 -->

**Found by:** e07 post-epic review (reviewer B should-fix 6). The e07 audit reported "No dead
code / duplication PASS", which this line falsifies.

## Problem

`SleepScene` declared `const VOICE_PATH = "res://assets/audio/voice/pt_BR/celebration_congrats.ogg"` and never
referenced it — and it pointed at the *celebration's* clip, not a bedtime line. Meanwhile the room made
no sound at all: no voice prompt, no SFX, while all four sibling rooms open with a family voice line and
answer touches with SFX.

## Evidence

`game/scripts/scenes/quarto_sono.gd:14` before the fix (`VOICE_PATH` referenced 0 times). The suite had
no audio assertion for the bedroom, so the gate could not see either half.

## Root Cause

The bedroom was written from the celebration's file and the voice line was dropped when no bedtime clip
was found. Dropping the call is defensible; leaving the constant behind is not, and nothing asserted
that the room responds audibly.

## Fix

- Removed `VOICE_PATH`.
- The room now answers with shipped SFX: `tap.ogg` (lamp), `drop.ogg` (tuck), `success.ogg` (step
  credited). No new asset is invented and no TTS is used (standing rule: family-recorded PT-BR).
- The missing bedtime voice line is recorded as accepted debt in [ADR-009](../adr/ADR-009-care-cycle-money-dwell-and-voice-gaps.md).

## Verification

`game/tests/integration/test_quarto_sono_scene.gd::test_the_lamp_and_the_tuck_make_a_sound` — red
before (`sfx_cursor` did not move), green after. Suite 402/402.
