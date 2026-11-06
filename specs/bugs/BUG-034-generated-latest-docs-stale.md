---
bug_id: BUG-034
status: fixed
severity: low
scope: docs
title: The generated "LATEST" architecture docs were left at e06, so the coverage map did not contain the two new scenes
---
# BUG-034: generated docs drifted two epics behind

<!-- story: e06s03 -->

**Found by:** e07 post-epic review, third pass (`maintain-wiki`: are the "latest" artifacts actually
latest?).

## Problem

Two artifacts advertise themselves as generated and current:

| File | Generator | State found |
|---|---|---|
| `specs/tech-architecture/COVERAGE_MAP_LATEST.md` | `bash scripts/coverage-map.sh --write` | generated at e06: **no** `quarto_sono.gd`, `celebracao.gd` or either builder |
| `specs/tech-architecture/HOTSPOTS_LATEST.md` | `bash scripts/churn-rank.sh 0 --write` | generated at e06: ranked files that no longer exist in that shape |

They are the only spot where "which tests exercise this module" exists (there is no GDScript line
coverage), so a stale copy actively misleads: the coverage map said the two new scenes had no tests.

## Root Cause

Generation is manual and the generator is not part of any gate; the epic-close ritual never mentions it.

## Fix

Regenerated both with the project's own scripts and committed the output. The coverage map now lists
`quarto_sono.gd` (2 tests), `celebracao.gd` (1), and both builders; the hotspots list reflects `HEAD`
(and now ranks the 277-line `test_casa_scene.gd` after BUG-033 rather than the 349-line one).

## Verification

`bash scripts/coverage-map.sh --write` and `bash scripts/churn-rank.sh 0 --write` are deterministic;
`grep quarto_sono` in the coverage map returns the scene, its builder and their test references.
*Recommendation recorded for the next epic's close:* run both generators as part of the epic-close
ritual (they are cheap and already ship in `scripts/`).
