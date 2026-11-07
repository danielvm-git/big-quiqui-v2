# Coelinha QuiQui

An ad-free, 100 % offline care game for pre-reading children (4–7), built with Godot 4.7 and GDScript.
QuiQui is a little rabbit in a village. The child feeds her, bathes her, dresses her, plays with her,
puts her to bed, and does it again the next day. Prompts are art and Brazilian-Portuguese voice — the
game never asks a child to read.

Target platform: iPad (4:3 `2048×1536`) and desktop/landscape (16:9 `1920×1080`), one build, no letterbox
bars on either.

## Status

| | |
|---|---|
| Latest release | **v0.9.1** (e09 merged on `main`, v0.10.0/v0.11.0 releases to cut) |
| Epics shipped | 9 of 11 (`e01`–`e09`) |
| Stories | 35 of 43 |
| Playable scenes | `titulo` · `casa` · `cozinha` · `banheiro` · `closet` · `jardim` · `quarto_sono` · `celebracao` · `vila` · `roda` · `mercado` · `casinha` · `festa` |
| Gate | `PREFLIGHT GREEN` — 52 scripts / 479 tests / 2885 asserts |

Run `bash scripts/status-counts.sh` for the numbers computed from the plan itself (rather than from a
dashboard that counts keys).

## Run it

```bash
godot --path game                 # play
bash scripts/setup.sh             # first-time: hooks, vendored tooling
```

## Gate

One entry point. It runs lint, format, the strict-typing gate, the full test suite, the PII log audit,
story traceability and the specs schema:

```bash
bash scripts/preflight.sh         # must exit 0 before any commit
bash scripts/preflight.sh --fast  # static stages only; what the pre-commit hook runs
```

Two rules the project holds itself to, mechanically:

- **Zero-Test Guard** — a test run that executes 0 scripts is a hard failure, not a pass.
- **No network** — `HTTPRequest`, `HTTPClient` and `WebSocketPeer` never appear in `game/`. The game is
  offline by construction, not by policy.

## Observability

```bash
bash scripts/health.sh                  # 12 checks: toolchain, gate scripts, hooks, diary, offline invariant
bash scripts/logs.sh tail -n 40         # the game's structured JSONL diary
bash scripts/logs.sh summary            # per session: clean exit vs crash, scenes, care steps, errors
bash scripts/logs.sh audit              # schema + PII validation, exits 1 on a bad line
```

Logs stay on the device (`user://logs/`). Full table in [`AGENTS.md`](AGENTS.md#observability).

## Layout

```
game/
  scenes/        titulo · casa · cozinha · banheiro · closet · vila · mercado · casinha · festa
                 (Control roots, PRESET_FULL_RECT)
  scripts/
    autoloads/   Log · SceneManager · CareLoopManager · AudioManager · ProgressManager
    components/  QuiQuiRig · TouchDraggable · TapButton · WishBubble · FoamBlob …
    core/        Fsm · Ids · CareSteps · FoodCatalog · FurnitureCatalog · LogSink · SquashSpring
    resources/   SaveData (typed save model, ADR-005)
  tests/         479 GUT tests, unit + integration
  tools/         scene builders (the .tscn files are generated, never hand-edited)
  assets/        art · audio (family-recorded PT-BR voice)
specs/           state, release plan, ADRs, threat models, audits, evals, benchmarks
```

`game/scenes/*.tscn` are **generated** by `game/tools/build_*_scene.gd`. Regenerate rather than edit.

## Docs that actually govern the work

| File | What it decides |
|---|---|
| [`AGENTS.md`](AGENTS.md) | how agents work here: the gate, the workflow, the never-rules |
| [`CONVENTIONS.md`](CONVENTIONS.md) | engineering rules: strict typing, `Fsm` for every state machine, `Control` roots, mouse-echo filtering, atomic saves, F.I.R.S.T tests |
| [`DESIGN.md`](DESIGN.md) | art direction, layout contract, motion spec |
| [`specs/tech-architecture/TEST_PLAN_LATEST.md`](specs/tech-architecture/TEST_PLAN_LATEST.md) | the 9-layer test pyramid and the benchmark conformance gate every scene must pass |
| [`specs/release-plan.yaml`](specs/release-plan.yaml) | the 11-epic ladder, `v0.1.0` → `v1.0.0` |
| [`specs/product/TUTOTOONS_REFERENCE.md`](specs/product/TUTOTOONS_REFERENCE.md) | the measured competitor benchmark, and what we deliberately do differently |
| [`specs/adr/`](specs/adr/) | the decisions, with the reasons and the numbers that justified them |

## Non-negotiables

- No ads, no telemetry, no network, no accounts.
- No text required to play; every prompt is visual plus PT-BR voice/SFX.
- Every playable scene passes the dual-aspect layout gate on both canvases, and the **painted character**
  — not its layout box — keeps the design height.
- Assets are original. No borrowed art, audio or level data from the games we benchmark against.

## Releases

`main` takes one squash-merge per epic; `big-release` cuts the version from the commit type, so the
ladder is `v0.2.0` e01 → `v0.11.0` e10 → `v1.0.0` e11. Hotfixes land as `fix(…)` and bump the patch.
