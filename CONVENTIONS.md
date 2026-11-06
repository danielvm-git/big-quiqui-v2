# Coelinha QuiQui — Engineering Conventions (`CONVENTIONS.md`)

<!-- story: e01s01 -->

All human and AI contributors MUST follow these rules without exception.

---

## 1. Always Green / Shift Left Doctrine

- **1-10-100 Rule:** Catching a defect during TDD costs $1\times$; during epic review costs $10\times$; during child playtesting on iPad costs $100\times$.
- **Preflight Gate:** Before starting any story and before every commit, the full Preflight command MUST exit `0`:
  ```bash
  bash scripts/preflight.sh
  ```
  It runs every stage and prints PASS/FAIL per stage: `L0` `gdlint` + `gdformat --check` (addons excluded), `L0b` strict-typing type gate (`game/tools/type_gate.gd`), `L1` GUT unit + integration, `L3` PII log audit, `L4` story traceability, `L5` bigpowers spec schema.
- **Zero-Test Guard:** A test run that executes `0` scripts or `0` assertions is a HARD FAILURE (`preflight.sh` greps GUT's `Nothing was run` and exits non-zero).
- **CI is centralized:** `.github/workflows/ci-cd.yml` is a copy of the portfolio template `danielvm-git/.github` → `test-build-release-godot.yml` (Option B, ADR-007), with inputs inlined. Pipeline logic belongs upstream — never invent a local stage; project-specific gates belong in `scripts/preflight.sh`, which the workflow calls. Re-sync the copy when the template version bumps.
- **Bootstrap Exception:** `bash scripts/preflight.sh --bootstrap` is the ONLY sanctioned way to pass Preflight with `0` test scripts. It may be used exactly once, before the first story lands, and is recorded as `lifecycle_phase` in `specs/state.yaml`. It never suppresses a real failure — only the zero-test verdict. CI selects it automatically **only** while `game/tests/**/test_*.gd` is empty; the first test file disables it permanently.

### Discovered Defects & Banned Dismissive Phrases
When any gate fails, you MUST either fix it immediately (`quick-fix` if data-only, or separate `fix:` commit) or log a structured blocker in `specs/bugs/registry.yaml`.

| Banned Phrase | Required Action |
|---|---|
| *"This failure is pre-existing"* | Fix it now in a separate `fix:` commit or halt and run `fix-bug`. |
| *"Unrelated to my changes"* | The tree is shared. Restore green before proceeding. |
| *"Not introduced by this session"* | Irrelevant. Never build on a broken baseline. |
| *"Out of scope for this story"* | Gate failures are always in scope. |

---

## 2. Git, Branching & Commit Hygiene

- **Conventional Commits:** Every commit title MUST match `^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9_-]+\))?!?: .+`.
- **Story Traceability:** Include the story ID in commit scopes or bodies (e.g., `feat(e01s02): implement table-driven Fsm and FsmProbe`).
- **No AI Attribution:** NEVER include `Co-authored-by`, `Co-Authored-By`, or any AI footer in commits.
- **Branch Protection:** Work on feature branches (`feat/eNNsYY-slug`); merge only when Preflight is green. Direct commits to `main` are blocked by the agent harness and by branch protection.
- **Hooks:** `git config core.hooksPath .githooks` (done by `scripts/setup.sh`). `pre-commit` runs `bash scripts/preflight.sh --fast`; `commit-msg` enforces Conventional Commits, the 72-char subject limit, and bans AI attribution.
- **Epic release train (version ladder):** `main` takes **exactly one squash-merge per epic** — `feat(eNN): <scene>` — which is what makes `big-release` cut one version per epic: `v0.1.0` (house) → `v0.2.0` (e01) → … → `v0.11.0` (e10) → `v1.0.0` (e11, via `feat(e11)!:`). Story commits (`feat(eNNsYY): …`) land on `epic/eNN-slug` and produce **no** release, because `big-release` only releases from `main`. Hotfixes land as `fix(...)`: patch bump (`v0.5.1`), ladder intact. `chore`/`docs`/`test`/`refactor`/`ci` never release. `specs/release-plan.yaml` → `release.versions` is the source of truth for the ladder.

---

## 3. GDScript & Godot 4.7 Architecture Rules

### 3.1 Strict Static Typing
- MUST annotate every variable (`var count: int = 0`), array (`var items: Array[String] = []`), parameter, and return type (`-> void`, `-> bool`).
- MUST NOT rely on untyped variant inference (`:=` on Variant return values is forbidden; use explicit `: Type = ...`).
- This is machine-enforced: `game/project.godot` sets `debug/gdscript/warnings/untyped_declaration=2` (warning treated as error) and Preflight `L0b` compiles every script through `game/tools/type_gate.gd`.

### 3.2 Explicit State Machines (`Fsm`)
- Every stateful manager, component, or multi-stage scene MUST instantiate `Fsm` (`res://scripts/core/fsm.gd`).
- MUST define `legal_edges: Dictionary` and `max_dwell_sec: Dictionary` upfront.
- MUST use `transition_from(expected_state, next_state)` whenever transitioning after an `await` or timer.
- NEVER encode multi-step modes with 2+ boolean flags (`_is_dragging`, `_is_consumed`, `_is_busy`).

### 3.3 Responsive Viewport & Scene Hierarchy
- Base viewport is `1920×1080` with `window/stretch/mode="canvas_items"` and `window/stretch/aspect="expand"`.
- Every `.tscn` scene in `game/scenes/` MUST have a `Control` root with `anchors_preset = PRESET_FULL_RECT`.
- Background `TextureRect` nodes MUST use `expand_mode = EXPAND_IGNORE_SIZE` and `stretch_mode = STRETCH_KEEP_ASPECT_COVERED`.
- Interactive character attachment zones (`mouth_zone`, `scrub_hull`, `headwear_anchor`) MUST live inside `QuiQuiRig` local coordinates—NEVER hardcoded screen pixels.

### 3.4 Touch-First Input & Mouse-Echo Filtering
- Godot's `emulate_touch_from_mouse = true` synthesizes `InputEventMouse` with `device == -1` for every touch.
- Every input handler (`_input`, `_gui_input`, `TouchDraggable`, `TapButton`) MUST ignore synthesized mouse events when handling touch or deduplicate via `TouchDraggable`/`TapButton`.
- The `device == -1` filter covers both echo directions: the mouse synthesized from a touch and the touch synthesized from a real mouse (`emulate_touch_from_mouse`), so handlers ignore any event with that device.
- Minimum interactive hit target for ages 4–7 is **`120×120 px`**.

---

## 4. Defensive Code Categories

| Category | Project Standard |
|---|---|
| **Timeout / Watchdog** | `SceneManager` enforces a `2.0 s` watchdog on transitions; `Fsm` enforces `max_dwell_sec` on non-terminal states. |
| **Idempotency** | `Fsm.transition_to(S)` when already in `S` is a silent no-op returning `false`; purchases and ticket spins lock immediately on first press. |
| **Graceful Degradation** | Missing audio streams or invalid item IDs log `Log.event(...)` and fall back cleanly without crashing or locking input. |
| **Atomic Persistence** | `ProgressManager` writes to `user://progress.json.tmp`, flushes, and renames atomically to `user://progress.json`. |
| **Input Validation** | Resource IDs are validated against `\A[a-z0-9_]{1,64}\z` before constructing `res://` paths. |

---

## Tests (F.I.R.S.T. + 9-Layer Pyramid)

- **Fast, Isolated, Repeatable, Self-Validating, Timely (TDD Red → Green → Refactor).**
- Every test script MUST extend `GutTest` (or `QuiQuiTestCase` which runs `TestReset.reset_all()` in `before_each`).
- NEVER read or write production `user://progress.json` in tests; `TestReset` redirects `ProgressManager` to `user://test_progress.json`.
- Every scene vertical slice MUST include:
  1. **Unit tests** for its FSM / data logic (`game/tests/unit/test_*.gd`).
  2. **Integration / E2E scene test** using `TouchSim`, `FsmProbe`, and `GeometryOracle` at both `1920×1080` (16:9) and `2048×1536` (4:3 iPad) (`game/tests/integration/test_*.gd`).
  3. **`# story: eNNsYY` header comment** linking code and test to `specs/release-plan.yaml`.
