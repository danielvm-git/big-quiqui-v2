# Grill — e01 assumptions (stress test of the plan before the first line of code)

<!-- story: e01s01 -->
**Skill:** `grill-me` (plain-language) · **Date:** 2026-11-04
**Method:** every load-bearing assumption in the e01 plan was challenged until it was
either *proven by a command that ran*, or turned into a decision. Nothing below is
resolved by opinion.

## Round 1 — "the gates are green, so the house is safe"

| Challenge | Evidence gathered | Verdict |
|---|---|---|
| "Preflight green means tested code." | Phase 1 gate ran with **0** `.gd` files: `trace-stories.sh` checks 0 files, `gdlint` lints 0 files | **FALSE.** Green was vacuous. Resolved by SC-E01-P0-08 (control test) + the Zero-Test Guard |
| "GUT fails when there are no tests." | `gut_cmdln.gd` with 0 scripts prints "Nothing was run" and **exits 0** | **FALSE.** Guard is string-matching — brittle by construction, documented in PRIOR_ART §5.1 |
| "`godot --headless --path game --quit` is a smoke test." | it **hung** (killed at 180 s) with no main scene | **FALSE.** Only `--import` is a valid smoke until e01s05 sets `run/main_scene` |
| "gdlint enforces strict typing." | `var x = 1` → `Success: no problems found` | **FALSE.** gdlint has no type rules. Fixed by `untyped_declaration=2` + `type_gate` |
| "CI proves the release works." | `big-release` no-ops silently off a configured branch | **FALSE.** Release step now fails when a releasable commit yields no tag |

## Round 2 — versioning

| Challenge | Evidence | Verdict |
|---|---|---|
| "`initialVersion` gives us 0.1.0 for the first epic." | first `feat` with no tag produced **0.0.1** (not 0.1.0) | **FALSE.** Baseline tag `v0.1.0` is mandatory, pushed before any feature work |
| "A `chore:` merge will release a patch." | `chore` → "No relevant changes, skipping release" | **FALSE.** Only feat/fix/perf/`!` release |
| "One release per epic happens automatically." | it requires exactly one squash-merge per epic onto `main` | **TRUE only with the epic-train rule** (now in CONVENTIONS §2) |
| "The Godot publisher bumps our version." | `godot.Prepare()` rewrites `project.godot` but plugins run first, so nothing commits it; `Publish()` POSTs a duplicate release and ignores the status | **FALSE.** Publisher disabled; CI syncs the version from the tag |

## Round 3 — the game itself

| Challenge | Evidence | Verdict |
|---|---|---|
| "`expand` gives the iPad a bigger canvas, not bars." | documented Godot behaviour; **not yet proven in this project** | **UNPROVEN** → SC-E01-P1-08 (GeometryOracle at both aspects) is the proof, scheduled e01s05 |
| "The 135 assets are the final art." | `specs/art/TODO_GERACAO_IMAGENS.md` lists outstanding generations | **FALSE for some assets** → e01s05 must not assume a complete art set |
| "43 stories / 128 BCPs." | counted from capsules: **43 / 138** | **FALSE**; corrected in `release-plan.yaml` |
| "Family voice acting is ready for the title theme." | 35 `.ogg` present under `assets/audio/voice/pt_BR` + `music` | **TRUE** (audition before e01s05 acceptance) |
| "Kids cannot reach the save file." | iOS sandbox; no export entitlements yet | **TRUE for iOS; unverified for desktop** → T-E01-02 covers debug-only `TestReset` |

## Round 4 — process

| Challenge | Evidence | Verdict |
|---|---|---|
| "`bigpowers init` provisions the harness." | it symlinks `scripts/` and every script derives `REPO_ROOT=dirname $0/..` | **FALSE** here; vendored the 8 needed files instead |
| "Branch protection enforces PR-only." | GitHub API returns **403** for private repos without Pro | **FALSE.** Enforcement is the harness guard + discipline, recorded in `state.yaml handoff.open_decisions` |
| "`plan-work` can be skipped because tasks exist." | `plan-consistency-check.sh` returned **CRITICAL=5 HIGH=5** | **FALSE.** All 11 capsules were non-conformant; fixed (now PASS) |

## Unresolved decisions handed to the user (not resolvable by evidence)

1. **`specs/state.yaml → version: 0.1.0-dev`** — keep as "the tagged house, in dev", or bump
   to `0.2.0-dev` (next expected). No gate reads it; choice is cosmetic.
2. **Epic branch naming** — `epic/eNN-slug` proposed; not yet exercised by a real merge.
3. **iOS export timing** — export preset arrives at e11; until then `package-ios` is inert.
   Confirm that no TestFlight build is wanted before e11.

## What this changed in the plan before implementation

- Added SC-E01-P0-08 (control test) as a **P0** for e01s01 — otherwise every later "green"
  is suspect.
- `plan-work` is now a real gate for every capsule (plan-consistency PASS), not a claim.
- Baseline tag + option-squash train documented in CONVENTIONS §2.
- The release pipeline's "prove it released" assertion added to CI.
