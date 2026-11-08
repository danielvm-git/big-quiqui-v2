# BUG-059 — the bath voice line points at a file that does not exist

<!-- story: e11s01 -->
- **Severity:** medium · **Priority:** P1 · **Scope:** audio · **Status:** fixed
- **Found by:** e11s01 `INV-07b` (`unit/test_asset_integrity.gd`)

## Symptom

`BanheiroScene.VOICE_PATH` is `res://assets/audio/voice/pt_BR/banho_hora_do_bath.ogg`. The
family's recorded clip ships as `bathroom_intro.ogg`. `_play_stream` degrades silently
(CONVENTIONS §4), so the bath — the one care step the family voiced in Portuguese — is the
only silent room, and nothing reported it.

## Root cause

The constant was written from the event name rather than from the file on disk, and no gate
checked that a `res://` literal written in a script resolves.

## Failing test

`test_every_referenced_res_path_exists`:
`["res://assets/audio/voice/pt_BR/banho_hora_do_bath.ogg"] != []`.

## Fix

`VOICE_PATH` corrected to `bathroom_intro.ogg`. A scene-level assertion pins the
contract (the constant must resolve) so the next rename is a red test, not a silent room.

## Verification

`test_asset_integrity.gd` 6/6 green; `test_banheiro_scene.gd` green.
