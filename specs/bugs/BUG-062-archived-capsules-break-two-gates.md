# BUG-062 — two pre-build gates assumed every epic capsule sits at the top of `specs/epics/`

<!-- story: e12s01 -->
- **Severity:** low · **Priority:** P2 · **Scope:** tooling · **Status:** fixed (2026-11-08)
- **Found by:** scope-work for the Builder restart — `bash scripts/compliance-pre-build.sh` ran
  2/22 red on a clean tree

## Symptom

Two independent checks in `scripts/compliance-pre-build.sh` encoded the same assumption: that all
eleven epic capsules live directly under `specs/epics/`. After e01–e09 closed they were moved to
`specs/epics/archive/`, and both checks broke without anyone noticing, because the script is not
part of `scripts/preflight.sh` and nothing runs it on a schedule.

1. `slice-tasks → epic capsules` asserted `test -d specs/epics/e01-tracer-title-and-foundation`.
   The directory exists — one level down. The check failed on a true statement.
2. `story verify extractor sees all tasks` counts records from
   `scripts/lib/extract-story-verify.py` and requires at least 129. The extractor globbed
   `specs/epics/*/`, so it silently returned **33** of the **154** records that exist on disk.
   The tripwire fired, which is the good outcome: it is the only reason the loss was visible.

Neither failure is visible from the game, the tests or Preflight. Both are why this is a bug and
not a tidy-up: a gate that fails on a true statement gets allowlisted, and a gate that silently
returns a quarter of its input gets trusted.

## Fix

- `extract-story-verify.py`: capsules are discovered recursively (`_capsule_dirs`), so archived
  epics still contribute their verify directives. The count went 33 → 154.
- `compliance-pre-build.sh`: the capsule check accepts either location, with the reason written
  above it.

## Why the threshold stays

The `-ge 129` tripwire is deliberate and must not be relaxed to whatever the current count is —
then it would pass while the extractor returned nothing. It stays a floor, and it will be raised
again when e12–e16 add their capsules.

## Evidence

- `bash scripts/compliance-pre-build.sh` → `22/22 checks pass`.
- `python3 scripts/lib/extract-story-verify.py . | wc -l` → `154` (was `33`).
- `bash scripts/preflight.sh --fast` stays green; nothing under `game/` changed.
