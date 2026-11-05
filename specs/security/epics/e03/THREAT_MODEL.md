# Threat Model — e03 (Kitchen FEED Scene)

<!-- story: e03s01 -->
**Skill:** `security-review` (build-epic Step 0) · **Date:** 2026-11-05
**Surface:** Godot 4.7 client, 100% offline, iPadOS + desktop, no accounts, no network.
**Delta over e02:** the first drag input (`TouchDraggable`), the first data-driven resources (`ItemData` `.tres`), the first care room that advances `CareLoopManager`, and a second production scene route.

## Assets

| Asset | Why it matters | Where it lives |
|---|---|---|
| Care cycle state | a wrong or repeated `complete_step` skews the cycle and, at its end, the reward | runtime |
| Save file (`user://progress.json`) | unchanged; e03 writes nothing new to it | device only |
| Child's play diary | new `drag`, `kitchen` and `care` events pass through the same writer | device only |
| Scene graph | a stuck kitchen is a dead end for a child who cannot read | runtime |

## Trust boundaries (unchanged from e02, plus one)

1. Engine <-> filesystem (`user://` only).
2. Input <-> game logic, now including continuous drag events and multiple fingers.
3. Data files <-> runtime (`SaveData`, JSONL).
4. Scene table <-> navigation (`cozinha.gd` uses one const path).
5. **New: item data <-> `res://` paths.** Food ids come from a const list and `.tres` files shipped in the package; no user input ever feeds a path.

## STRIDE

| Category | Threat (concrete) | Likelihood | Mitigation (specified for e03) |
|---|---|---|---|
| **S**poofing | none: no identity, no accounts | n/a | none needed |
| **T**ampering | **double drop** counts a bite twice or completes FEED early (state-machine bug class, not an attacker) | medium | `CONSUMED` is terminal; `transition_from(READY, CHEWING)`; `bites` rises only when the transition succeeds; E2E test replays the events |
| **T**ampering | **repeat visit** credits FEED again or walks the loop illegally | medium | `begin_step` only from `IDLE`, `complete_step` only from `FEED`; second-visit test with a clean `FsmProbe` |
| **T**ampering | modified `.tres` in a tampered package | low | same trust level as the code; ids validated by `Ids.is_valid` before art paths are used |
| **R**epudiation | a parent cannot tell whether the step happened | low | `care.begin`, `care.complete`, `care.abandon` already logged; scene logs ids only |
| **I**nformation disclosure | drag coordinates or food ids in the diary reveal nothing personal, but high-frequency events could flood it | low | no event per drag motion; events on start, drop and consume only; `Log.event` remains the only writer |
| **D**enial of service | **soft lock**: a finger lifted outside the control, or a node freed mid-drag, leaves the static owner held so nothing can be dragged | medium | owner released on `_exit_tree`; release is tracked by touch index; `RETURNING` has a 1.0 s dwell; test frees a held food and drags another |
| **D**enial of service | a missing art or audio file stops the scene | low | `ItemData.texture()` and audio loading degrade with a log event; the scene stays playable |
| **D**enial of service | a child is trapped in the room | medium | `HomeButton` with `abandon_step`; the request is guarded so it fires once |
| **E**levation of privilege | item id -> `res://` path traversal | low | ids are checked against `^[a-z0-9_]{1,64}$`; `art_path` is only read from shipped resources |

## Kids-specific threats (delta)

| Threat | Mitigation |
|---|---|
| Frustration from a small drop target | `drop_margin = 120` around the mouth, and a missed food returns on its own |
| Food looks like a trap: the character reacts to nothing | anticipation is immediate under 220 px and restores the previous face |
| Prompts needing to be read | no `Label`s in the scene; voice, wish bubble and art carry the prompt |
| Particles or SFX overload | fixed one-shot bursts per bite, through the shared voice-ducking mix |

## Findings for e03 implementation (must be closed in-story)

| ID | Finding | Severity | Story | Required action |
|---|---|---|---|---|
| T-E03-01 | The static single-finger owner can wedge all dragging if not released | HIGH | e03s01 | release on `_exit_tree`; SC-E03-P1-06 |
| T-E03-02 | Bite and FEED completion must be exactly-once under echo and replay | HIGH | e03s01, e03s03, e03s04 | SC-E03-P0-01, SC-E03-P0-23 |
| T-E03-03 | The FEED door stays tappable after FEED, so re-entry must be clean | HIGH | e03s03, e03s04 | SC-E03-P0-15, SC-E03-P1-26 |
| T-E03-04 | Production scene swap must never fire under GUT | MED | e03s03 | keep `SceneManager.set_test_mode(true)` through `TestReset` |
| T-E03-05 | Parallel worktree test runs share `user://` | MED | all | run each worktree's Godot with its own `HOME`; no repo change |
| T-E03-06 | The diary must not get one line per drag motion | LOW | e03s01 | log on start, drop and consume only |

## Out of scope (with reason)

- Network exfiltration: no network stack; the CI grep control from e01 still applies.
- `CONTINUOUS_SCRUB`, `SNAP_TO_SLOT`, `FREE_PLACEMENT`: built with e04, e06 and e09.
- Multi-user: single-player local app.
