# Audit — e03 / e03s02

<!-- story: e03s02 -->
**Skill:** `audit-code` gate mode · **Date:** 2026-11-05
**Target:** working tree of `feat/e03s02-food-catalog` against `epic/e03-kitchen-feed-scene`

VERDICT: PASS

## Summary

| Section | Result |
|---|---|
| Supply Chain & Security | PASS |
| Provenance & Metadata | PASS |
| Law of Demeter | PASS |
| CONVENTIONS compliance | PASS |
| Scope | PASS |
| Boy Scout Rule | PASS |
| Types and Safety | PASS |
| Test Coverage | PASS (one fix made during the audit) |
| SOLID and Heuristics | PASS |
| Code Style | PASS (file length noted) |

## Evidence

- **Security:** no new dependency. Grep for secrets and network classes in the new code returned nothing. Food ids come from a const allowlist, and `get_item` rejects traversal strings before building a path (tested). Untrusted ids are logged as the literal `invalid`. `art_path` is not confined to the items folder by code: the threat model accepts this because it is read only from shipped resources, and a test pins every shipped path.
- **Scope:** the diff touches only files in the brief. No out-of-bounds file changed.
- **State:** one `String`, no boolean flags (ADR-001).
- **Churn:** `scripts/bp-churn-rank.sh` is not in this repo. `git log` was used instead; the rig and its test were reviewed first.

## Fixed during the audit

1. New blink tests poked the private `_next_blink_at` (T8). They now drive the rig through `advance()` only.
2. Mutants M4 and M6 survived; two tests were strengthened (see `e03s02-2026-11-05.md`).

## Accepted, not fixed

| Severity | Item | Reason |
|---|---|---|
| LOW | `mouth_global_center()` errors if called before `_ready` | same as `set_outfit` on the rig; drag input cannot arrive before the scene is ready. Forward note written for e03s03 |
| LOW | if `quiqui_mouth_open.png` were missing, each close `update_food_proximity` call logs `rig.missing_art` again, which could flood the diary (T-E03-06) | the art ships in the package; a guard needs extra state for a case that needs a tampered package |
| LOW | `item.missing_data` branch in `FoodCatalog.get_item` has no test | reaching it needs a shipped file removed; catalog integrity tests fail first in that case |
| NOTE | `quiqui_rig.gd` is 333 lines and `test_quiqui_rig.gd` 316, over the skill's 300-line guide | the rig was already 309 lines; `CONVENTIONS.md` sets no limit and the brief asks for a minimal change, so no split here |
| NOTE | older `test_the_mouth_zone_lives_inside_the_visible_art` only checks that the rects have area | superseded by the new enclosure test; left in place to keep the change minimal |

## F.I.R.S.T.

| Rule | Result |
|---|---|
| Fast | `test_item_data` 0.5 s, `test_quiqui_rig` 0.88 s; full suite about 3.1 s |
| Isolated | `TestReset.reset_all()` in `test_item_data`; a fresh rig per test; private `HOME` per worktree (T-E03-05) |
| Repeatable | fixed seeds, stepped time through `advance()`; full suite gave 173/173 on every run |
| Self-validating | every test asserts; the mutation table shows failures are real |
| Timely | tests written first; red shown at parse level and at assertion level |

## Red flags named

The first pass of the mutation run was optional for a `--fast` build and could have been skipped; it found two real test gaps. The separate `security-review` skill was not run: this was a hand check against the e03 threat model, recorded as a deviation.
