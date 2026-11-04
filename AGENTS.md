# Coelinha QuiQui — AI Agents

Read CONVENTIONS.md before any GitHub or git operation.

<!-- BEGIN bigpowers:project -->
## Project
Coelinha QuiQui is an ad-free, 100% offline TutoTOONS-grade care and village game for pre-reading children (ages 4–7) with family voice acting in Brazilian Portuguese.
Stack: GDScript / Godot 4.7 / GUT 9.x / iPadOS (4:3) & 16:9 Responsive Canvas

## Commands
| Action | Command |
|--------|---------|
| Run | `godot --path game` |
| Test | `godot --headless --path game -s addons/gut/gut_cmdln.gd -gexit` |
| Lint | `gdlint game/ && gdformat --check game/` |
| Build | `godot --headless --path game --export-release "iOS" build/ios/quiqui.ipa` |
| Preflight | `bash scripts/preflight.sh` (single entry point; `--bootstrap` only before the first story) |
| Setup | `bash scripts/setup.sh` |
| Logs | `bash scripts/logs.sh summary --sessions 3` |
| CI | `gh pr checks` — runs the portfolio reusable `test-build-release-godot.yml` (ADR-007) |
| Release | `big-release release --dry-run --verbose` (real releases run in CI on `main` via the central workflow) |

## Architecture
Five autoload singletons coordinate the game: `Log` (schema-validated JSONL local diary with PII redaction), `SceneManager` (table-driven FSM transitions with 1-slot pending queue and 2.0s watchdog), `CareLoopManager` (table-driven FSM `IDLE -> FEED -> BATH -> DRESS -> PLAY -> SLEEP -> CELEBRATE`), `AudioManager` (music crossfade, 8-channel SFX pool, `-9 dB` voice ducking), and `ProgressManager` (typed `SaveData` resource with atomic `.tmp` rename). Every scene uses a `Control` root (`PRESET_FULL_RECT`) under `stretch/aspect="expand"` and composes `QuiQuiRig` (layered body + outfit + facial expression + accessories) and `TouchDraggable` (4 interaction modes with `device == -1` mouse-echo filtering).

## Conventions
- MUST use strict GDScript static typing on every variable, parameter, and return value.
- MUST use `Control` roots (`PRESET_FULL_RECT`) for all scenes; NEVER use `Node2D` scene roots.
- MUST model every state machine with `Fsm` (`res://scripts/core/fsm.gd`); NEVER use boolean flag clusters.
- MUST filter synthesized mouse events (`event is InputEventMouse and event.device == -1`) in touch handlers.
- MUST isolate save paths in tests via `TestReset` (`user://test_progress.json`).
- MUST tag every script and test with `# story: eNNsYY` for `trace-stories.sh --strict`.

## Never
- NEVER dismiss reproducible gate failures as pre-existing or out of scope.
- NEVER proceed on red Preflight or red CI — invoke `quick-fix` or `fix-bug` first.
- NEVER make network calls (`HTTPRequest`, `HTTPClient`, `WebSocketPeer`), ads, or telemetry.
- NEVER include `Co-authored-by` or AI agent attribution in git commits.
- NEVER require reading text to play; every prompt MUST be visual + PT-BR voice/SFX.
- NEVER use Kenney placeholders, painterly v0.2 assets, or pure black (`#000000`) outlines.

## Agent Rules
- **Workflow Mandate:** You MUST use the bigpowers skills (`plan-work`, `develop-tdd`, `build-epic`, `verify-work`, `audit-code`) to perform tasks. DO NOT write code directly without active epic/story specs.
- **Vertical Slices Only:** Every epic and story MUST deliver a bootable, playable, end-to-end verifiable scene or user-facing behavior.
- **Always Green:** Preflight and CI MUST be green before forward work.
- Read `specs/` before writing code.
- Write the minimum code that solves the stated problem. Nothing extra.
- Run tests after every change. Show evidence before declaring done.
<!-- END bigpowers:project -->

<!-- BEGIN bigpowers:context-routing -->
## Context Routing

| Path pattern | Context to load |
|---|---|
| `specs/` | `specs/state.yaml`, `specs/product/SCOPE_LATEST.yaml`, `specs/release-plan.yaml` |
| `game/scripts/` | `CONVENTIONS.md`, `specs/tech-architecture/EXPLICIT_STATE_MACHINES.md` |
| `game/scenes/` | `DESIGN.md`, `specs/adr/ADR-002-expand-viewport-control-roots.md` |
| `game/tests/` | `CONVENTIONS.md` §Testing, `specs/tech-architecture/TEST_PLAN_LATEST.md` |
| `.github/workflows/` | `specs/state.yaml`, `CONVENTIONS.md` §CI/CD |
<!-- END bigpowers:context-routing -->

<!-- BEGIN bigpowers:learned-preferences -->
## Learned User Preferences
- Voice acting recorded by the family in Brazilian Portuguese (never AI-generated TTS in final release).
- Glossy candy-colored 3D-shaded 2D cartoon style (TutoTOONS benchmark) for 100% of art.
- Vertical scene-by-scene slicing: finishing each epic yields a complete, playable, testable scene on top of the foundation.
- iPad-first (`2048×1536` 4:3 + `1920×1080` 16:9 zero-letterbox `expand` viewport).

## Workspace Facts
- Godot 4.7, GDScript strict typing, GUT 9.x for testing, `gdtoolkit` (`gdlint` + `gdformat`).
- 5 autoloads: `Log`, `SceneManager`, `CareLoopManager`, `AudioManager`, `ProgressManager`.
- 98 glossy art assets in `game/assets/art/` + 35 `.ogg` audio files in `game/assets/audio/`.
<!-- END bigpowers:learned-preferences -->
