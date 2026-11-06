---
bug_id: BUG-035
status: fixed
severity: low
scope: docs
title: The 300-line file / 20-line function bar that every audit enforces was written down nowhere, and five pre-existing files already break it
---
# BUG-035: a gate that lives only in reviewers' heads

<!-- story: e01s01 -->

**Found by:** e07 post-epic review, fourth pass (checking the whole tree against the bar the e07 audit
quoted).

## Problem

The e07 audit says "File size (300 guideline) PASS … new scripts 92–203 lines" and "Functions ≤ 20 lines
PASS"; `specs/state.yaml`'s e03 handoff says "**0** files > 300 lines, **0** functions > 20 lines". None
of this appears in `CONVENTIONS.md`, and the claim is false for the tree as a whole:

| File | Lines |
|---|---|
| `game/scripts/components/quiqui_rig.gd` | 427 |
| `game/tests/unit/test_quiqui_rig.gd` | 404 |
| `.github/workflows/ci-cd.yml` | 341 |
| `game/scripts/components/touch_draggable.gd` | 331 |
| `game/scripts/scenes/banheiro.gd` | 326 |

Until this pass, `game/tests/integration/test_casa_scene.gd` (349) was a sixth. Because the bar is
unwritten, each audit scoped it differently: e07's "PASS" silently meant "new files only", while the
handoff line reads as an absolute claim about the repository. Two reviewers quoted the bar as a project
rule and neither could point at the rule.

## Root Cause

The bar was introduced in the e01 audit as a reviewer heuristic and never promoted to a convention, so it
has no scope, no exception list and no owner.

## Fix

`CONVENTIONS.md` §5 "Size & Review Bars" now states:

- 300 lines per file / 20 non-comment lines per function, split by subject rather than by deleting
  assertions;
- the scope (**new or changed** files), with the five grandfathered files named as debt and the rule that
  growing one is a violation while shrinking one is welcome;
- the generated-artifact rule (coverage map + hotspots regenerated at every epic close, BUG-034).

The five files are **not** refactored in this pass: `quiqui_rig.gd`'s split is its own story with its own
oracle runs, and it is not on e07's change path. They are recorded, not dismissed.

## Verification

The list was produced with `find … | xargs wc -l` over `game/scripts`, `game/tests`, `game/tools`,
`scripts/` and `.github/` (addons and vendored trees excluded); every count re-checked after the
BUG-033 split.
