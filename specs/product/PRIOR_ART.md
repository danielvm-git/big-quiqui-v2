# Prior Art — what already exists and what we deliberately reuse

<!-- story: e01s01 -->
**Skill:** `research-first` · **Date:** 2026-11-04 · **Scope:** e01 (foundation + TitleScene)

This file is the `research-first` record. It exists so e01 never invents what it can
inherit, and never copies what the project bans.

## 1. Product prior art (what "TutoTOONS-grade" concretely means)

| Reference | What we take | What we refuse |
|---|---|---|
| *Kiki & Fifi Pet Friends* | One activity per screen, giant character (55–65% viewport height), prop trays with ≥120 px hit targets, zero reading | Ad breaks, energy timers, "watch video to continue" |
| *My Baby Unicorn / Moy* | Character reacts within one frame to touch; squash-and-stretch tap feedback; contextual expressions before the action completes | Currencies that gate the core loop behind waiting |
| *Sago Mini* (village/exploration) | Free-roam village as the reward layer after the care loop | Narration text bubbles the child must read |

Consequence captured in `specs/product/VISION_LATEST.yaml` P1–P4 and `DESIGN.md` §4:
breathing sinusoid, natural blink 2.8–5.2 s, mouth anticipation at <220 px, 3-keyframe
jelly squash. These are specifications copied from observed behaviour, not invented.

## 2. Engine / test prior art

| Source | Reuse |
|---|---|
| Godot 4.7 docs — *Version control systems* | Ignore only `.godot/` and `*.translation`; commit `.import`, `.uid`, `export_presets.cfg` (already applied in `.gitignore`) |
| Godot 4.7 docs — `window/stretch/*` | `canvas_items` + `expand` is the documented zero-letterbox mode for non-matching aspect ratios (ADR-002) |
| Godot 4.7 docs — `input_devices/pointing/emulate_touch_from_mouse` | Documents that synthesized mouse events carry `device == -1` — the exact filter in ADR-004 |
| GUT 9.6.0 (vendored `game/addons/gut`) | `gut_cmdln.gd` headless runner, `.gutconfig.json` `dirs`, per-test `GutTest` base. Known trap verified locally: 0 discovered scripts prints "Nothing was run" and **exits 0** → our Zero-Test Guard greps for it |
| Table-driven FSM (statecharts, Harel) | `legal_edges` + `max_dwell_sec` tables rather than boolean flags (ADR-001). Precedent: Godot's own `AnimationNodeStateMachine` declares transitions as data |

## 3. Tooling prior art

| Source | Reuse |
|---|---|
| `semantic-release` | Conventional-commit → version algorithm; we use its Go port instead of the Node plugin stack |
| `danielvm-git/big-release` v2.7.0 | Auto-detects publishers, `tagFormat`, `initialVersion`, github plugin. Verified locally: first `feat` on a baseline tag bumps minor; a `chore` produces no release; the `godot` publisher is unreliable (cannot commit its bump, hides HTTP errors) → disabled in `.big-release.yml` |
| `bigpowers` 2.93.x | Skill lifecycle, `plan-consistency-check.sh`, `extract-story-verify.py`, `bp-timing.sh` (vendored where the gate script lives in `scripts/`) |

## 4. Rejected prior art (and why)

- **semantic-release + husky + commitlint** (as used in `big-quiqui` v1): requires Node in
  CI for a GDScript project and pushes release commits to a protected branch. Replaced by
  big-release (Go binary) + `.githooks` (no npm).
- **`bigpowers init`**: symlinks its `scripts/` over the project's, and every bigpowers
  script derives `REPO_ROOT=dirname $0/..` — a symlink resolves to the package root and
  writes to the wrong tree. Vendored the 8 files we need instead (`scripts/VENDORED.md`).
- **Kenney / placeholder art, painterly v0.2, pure-black outlines**: banned by
  `DESIGN.md` §1 and `AGENTS.md` §Never.
- **AI TTS for voice**: banned; family-recorded PT-BR only.

## 5. Open questions carried into e01

1. GUT's 0-script exit code is 0 — mitigated by the guard, but the guard is string matching
   on GUT output. If GUT renames the message, the guard silently stops guarding.
   *Mitigation:* e01s01's test task must assert the guard by running `preflight.sh` against a
   deliberately empty tests dir (a control test).
2. `type_gate` compiles scripts by `GDScript.reload()`; scripts depending on autoloads that
   do not exist yet will fail for the wrong reason. *Mitigation:* autoloads land in e01s01
   before any script that references them.
