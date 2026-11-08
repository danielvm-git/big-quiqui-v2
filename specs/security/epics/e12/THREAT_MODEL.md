# Threat Model — e12 (Builder player, scene data, wave 1a)

<!-- story: e12s01 -->
<!-- story: e12s02 -->
**Skill:** `security-review` (build-epic Step 0) · **Date:** 2026-11-08
**Surface:** Godot 4.7 client, 100 % offline, no accounts, no network.
**Delta over e11:** first navigation by **scene id** (not path), first `SceneDef` `.tres` under
`res://data/scenes/`, voice resolved by **key** (`vo.<scene>.<line>`), template id → preloaded script
registry, and the English asset rename (mechanical; no new trust boundary).

## Assets

| Asset | Why it matters | Where |
|---|---|---|
| Scene id → `res://data/scenes/<id>.tres` | a crafted id could reach path traversal (CWE-22) if validation is skipped | runtime loader |
| Voice key segments | each segment becomes a path under `voice/<locale>/` | `AudioManager` |
| `SceneDef` fields (background, music) | ids in data must not become arbitrary `res://` strings | `ScenePlayer` |
| Template registry | template id must not dynamic-load script paths from data | const map only |
| Save file | unchanged in e12 (kitchen credits FEED via existing `CareLoopManager`) | `user://progress.json` |
| Diary | new `scene.*` / `step.*` families; ids only, no prose | device only |

## Trust boundaries

1. Engine ↔ filesystem (`user://` only) — unchanged.
2. Input ↔ game logic — unchanged; Give primitive reuses `TouchDraggable`.
3. **New: scene id ↔ shipped `res://` paths.** Only ids passing `Ids.is_valid` (`\A[a-z0-9_]{1,64}\z`, CONVENTIONS § input validation) may build `res://data/scenes/<id>.tres` or voice file paths.
4. **New: scene data ↔ runtime.** `SceneDef` holds ids and numbers only — no script paths, no expressions (frozen contract: a def cannot run code).
5. Template id ↔ script — **registry only**: known ids map to preloaded scripts; unknown template rejected at load with `scene.def_rejected`.

## STRIDE

| Category | Threat | Likelihood | Mitigation (test) |
|---|---|---|---|
| **T**ampering | crafted scene id reaches `../` in a path | **medium** | `Ids.is_valid` before every `res://data/scenes/<id>.tres` (`test_an_id_failing_Ids_PATTERN_is_rejected`) |
| **T**ampering | tampered `.tres` in repackaged build | low | same trust as code; reject unknown template, missing background, empty steps |
| **T**ampering | voice key injects path segments | **medium** | split key; every segment `Ids.is_valid`; unknown → `audio.missing_key`, no crash |
| **T**ampering | template id loads arbitrary script | **medium** | const `TEMPLATE_SCRIPTS`; never `load("res://.../%s" % id)` (`test_unknown_template_rejected`) |
| **T**ampering | stale def shown after deferred swap | medium | `consume_def()` single-use; second read empty (`test_consume_def_clears`) |
| **I**nformation disclosure | diary carries paths not ids | low | events use `scene.kitchen` slugs; PII audit unchanged |
| **D**enial of service | rejected def leaves child on blank player | medium | fail closed with `scene.def_rejected`; no swap on rejection |
| **D**enial of service | step hangs forever | low | hint layer (e12s05); no step timer (by design) |
| **E**levation | ResourceLoader on `user://` for defs | n/a | defs live only under `res://data/scenes/` |

## Kids-specific

| Threat | Mitigation |
|---|---|
| Wrong room after a tap | same FSM, curtain, watchdog as `request_scene` |
| Scary double music restart | reuse `AudioManager.is_music_playing` pattern from e07 |
| Miss feels punishing | Give primitive returns item + soft SFX; no save change |

## Residual risk

- Hand-edited `kitchen.tres` in a dev tree is out of scope; shipped package trusts the build.
- English rename is voluminous but not a new attack surface; grammar tests gate filenames.

## Task security tags (sourced here)

| Story | `security: medium` tasks | Rationale |
|---|---|---|
| e12s01 | t05 (voice key resolver) | path building from key segments |
| e12s02 | t01–t05 | def loader + `request_def` + catalog paths |
| e12s03 | t03 | `ScenePlayer` loads def assets |
| e12s04 | t04 | reaction voice keys |
| e12s06 | t02, t04 | template registry + `kitchen.tres` load |

All other e12 tasks: `security: none`.
