---
bug_id: BUG-032
status: fixed
severity: medium
scope: docs
title: README claimed v0.6.0 / 5 of 11 epics / 361 tests while main was v0.9.0 / 7 of 11 / 408
---
# BUG-032: the front door of the repo was four epics out of date

<!-- story: e01s01 -->

**Found by:** e07 post-epic review, third pass (`maintain-wiki` sweep: does the repository's own front
page describe the repository?).

## Problem

`README.md`'s status block, which is the first thing any human or agent reads:

| Field | Said | Reality on `main` |
|---|---|---|
| Latest release | `v0.6.0` | `v0.9.0` (tag + `game/project.godot` `config/version`) |
| Epics shipped | 5 of 11 (`e01`–`e05`) | 7 of 11 (`e01`–`e07`) |
| Stories | 20 of 43 | 27 of 43 (`scripts/status-counts.sh`) |
| Playable scenes | 5 | 8 (`jardim`, `quarto_sono`, `celebracao` missing) |
| Gate | 30 scripts / 361 tests / 1880 asserts | 37 / 408 / 2154 |

The tree diagram below it also said "361 GUT tests". `AGENTS.md`'s workspace facts said "98 glossy art
assets" where the tree holds 100 (87 `.png` + 13 `.jpg`).

## Root Cause

The block is hand-maintained and nothing regenerates or checks it. `scripts/status-counts.sh` computes
exactly these numbers — and the README even points at it, one line below the stale block — but no step
runs it against the file.

## Fix

Every field updated to the values `scripts/status-counts.sh`, `git tag` and the gate actually report; the
asset counts in `AGENTS.md` updated and split by type. No new tooling added: the numbers are cheap to
verify by hand and the alternative (a generator) is scope this pass does not need.

## Verification

- `bash scripts/status-counts.sh` → `7/11 done, 27/43 stories`, `next e08`.
- `git describe --tags` → `v0.9.0`; `grep config/version game/project.godot` → `0.9.0`.
- `bash scripts/preflight.sh` → `PREFLIGHT GREEN — 37 scripts / 408 tests / 2154 asserts`.
