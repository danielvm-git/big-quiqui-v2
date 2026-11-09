# Threat Model — e12 (Builder player and the first loop)

<!-- story: e12s01 -->
**Skill:** `security-review` · **Date:** 2026-11-08 · **Review:** `specs/security/CODEBASE_REVIEW_2026-11-08.md`
**Surface:** Godot 4.7 client, 100 % offline, one local save, no accounts, no network.
**Delta over e11:** the game gains a **data → behaviour** boundary for the first time. Until now every
room was code; from e12 a room is a file that names a template, a background, a voice key and node
references. That boundary is the whole security story of this epic, and it has three shapes: a key that
becomes a path (F-1), a def that could name a script (F-2), and a node reference that becomes a
`get_node` path (F-3).

## Assets

| Asset | Why it matters | Where |
|---|---|---|
| Save (`coins`, `tickets`, `friend_stars`, owned/placed furniture, equipped look) | the only persisted state; tampering is the only economy attack that exists here | `user://progress.json` |
| The 17 legacy scenes | must stay playable through the rename and the new navigation (D1a) | `res://scenes/*.tscn` |
| The diary | only data the child generates; PII policy is a legal boundary | `user://logs/*.jsonl` |
| Scene defs | **new**: the thing that decides what a room does | `res://data/scenes/*.tres` |
| The template registry | **new**: the closed set of things a def may run | `res://scripts/templates/` |

## Trust boundaries

| Boundary | Trusted side | Untrusted side | Control |
|---|---|---|---|
| def → player | the player and the registry | a `.tres` file | validation on load: id grammar, known template, non-empty steps, background present (`scene.def_rejected`) |
| key → path | the resolver | a voice key, a scene id, a node id | a grammar per kind, per-segment validation, path assembled from validated segments |
| save → model | `SaveData` | `progress.json` | clean-on-read: clamp, id filter, ownership, NaN guard |
| value → log | the diary writer | any value the game emits | flatten + id-check + redact; `msg` is an id |

## STRIDE

| Category | Threat | Likelihood | Mitigation (test) |
|---|---|---|---|
| **T**ampering | a voice key such as `vo.kitchen../../x` resolves outside `assets/audio/voice` (F-1) | **high** — it is the natural implementation | `VO_KEY` grammar validated per segment; path built only from validated segments; `SC-e12s01-P0-01` rejects `..`, `../`, `a/../b`, `vo..kitchen` and logs `audio.missing_key` |
| **T**ampering | a def names a script or a resource path and the registry loads it (F-2) | medium | `StepDef` has no path-shaped field; the registry is a closed `const` map id→script; `SC-e12s02-P0-08` scans both |
| **T**ampering | a def gives a node reference that walks out of the room (`../../root/...`) (F-3) | medium | node ids resolve through a table the player registers; a `../` value is rejected and logged; `SC-e12s05-P1-04` |
| **T**ampering | `repeat: 3` credits FEED twice (double tap, echo, re-entry) | **high** | idempotent `complete_step(expected_state)` + the mouse-echo filter; `SC-e12s06-P0-04` counts the calls; re-entry is free play (`SC-e12s06-P0-05`) |
| **T**ampering | a tampered save inflates the reward the kitchen grants | low | the grant comes from `CareLoopManager`, not from the save; `SaveData` clamps on read |
| **T**ampering | a scene id from a def opens a room the player did not intend | medium | `Ids.is_valid` before `res://data/scenes/<id>.tres`; unknown id is a rejection (`SC-e12s02-P0-03`) |
| **R**epudiation | a rejected def leaves no trace, so a broken build looks fine | medium | `scene.def_rejected` with a reason id, then L3 audit |
| **I**nformation disclosure | the rename moves assets and someone pastes a private path into a builder constant | low | the diary audit rejects absolute paths; `SC-e12s01-P2-01` scans for stale strings |
| **I**nformation disclosure | prose or PII reaches the diary through a new event family | low | writer is stricter than the auditor; `SC-e12s03-P2-01` + L3 |
| **D**enial of service | a def with a huge or cyclic `steps` list wedges the player | medium | validation bounds the step count and each step's parameters; no def may reference itself (`next` is a scene id, not a def chain) |
| **D**enial of service | a step with no exit (no progress possible, home unreachable) | **high** | home exits from every state with no penalty (`SC-e12s03-P0-03`); `max_dwell_sec` on render states; the hint layer answers silence |
| **E**levation | a def escalates to code execution (the F-2 path, taken to its end) | medium | same control as F-2: the registry is the only door and it is a constant |

## Abuse cases that are *not* threats here

- **A child mashing the screen** is the design target, not an attacker: `MonkeyStream` and `TouchSim`
  already exercise it, and "no fail state" is a requirement.
- **Editing `progress.json`** is bounded by clamping and is not a boundary this product defends
  (§Residual risk of the codebase review).
- **A network attacker** does not exist: there is no network API in the game binary.

## Residual risk

| Residual | Reason |
|---|---|
| `res://` defs are not integrity-checked inside the IPA | Godot's `.pck` is not signed separately; an attacker who can edit it owns the device. F-1/F-2/F-3 are still fixed because the resolver will later read user-writable sources. |
| The player trusts its own defs at load time | they ship inside the app; validation protects against *our* mistakes (a typo, a stale id) as much as against an attacker, and that is the honest reason it exists |
| The ghost hand is still a placeholder rectangle | cosmetic, recorded in the scope |

## Gate

No HIGH finding without a mitigation. F-1 is `medium` and changes an acceptance criterion of e12s01
(which becomes P0); F-2 and F-3 are `medium` and add one scan and one rejection test respectively.
Tasks in the touched paths carry `security: medium` and their verify step asserts
"no new security findings in affected paths".
