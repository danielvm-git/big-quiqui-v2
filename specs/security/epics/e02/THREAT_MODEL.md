# Threat Model — e02 (Casa da QuiQui Care Hub)

<!-- story: e02s01 -->
**Skill:** `security-review` (build-epic Step 0) · **Date:** 2026-11-04
**Surface:** Godot 4.7 client, 100% offline, iPadOS + desktop, no accounts, no network.
**Delta over e01:** a 5th autoload (`CareLoopManager`) grants economy rewards (`+5 coins / +1 ticket`
per care cycle), three new UI components read `ProgressManager` state, `casa.tscn` becomes the first
production `change_scene_to_file` destination, and six doors route navigation.

## Assets

| Asset | Why it matters | Where it lives |
|---|---|---|
| Save file (`user://progress.json`) | coins/tickets are granted automatically on cycle completion — economy integrity | device only |
| Child's play diary (`user://logs/quiqui-*.jsonl`) | unchanged chokepoint from e01 | device only |
| Scene graph / autoload state | a wedged `CareLoopManager` FSM soft-locks the whole hub | runtime |

## Trust boundaries (unchanged from e01, plus one)

1. Engine ↔ filesystem (`user://` only).
2. Input ↔ game logic (touch + mouse-echo; doors and bubbles are `Control`s).
3. Data files ↔ runtime (`SaveData` load; JSONL read-back).
4. **New: scene table ↔ navigation.** The only scene paths that may be requested are compile-time
   constants (`titulo.gd CASA_PATH`, the `casa.gd` door table). No user input ever feeds a path.

## STRIDE

| Category | Threat (concrete) | Likelihood | Mitigation (specified for e02) |
|---|---|---|---|
| **S**poofing | none — no identity, no accounts | n/a | — |
| **T**ampering | crafted `progress.json` with inflated coins (pre-existing) | low | `SaveData` clamps on load (e01s03) |
| **T**ampering | **double cycle reward**: re-entering `CELEBRATE` or detouring mid-celebration granting twice | medium (state-machine bug class, not attacker) | reward granted exactly once per `cycle_id` (`_rewarded_cycle_id` ledger); unit test walks a full cycle, a detour, and a second cycle asserting `+5/+1, +0/+0, +5/+1` |
| **R**epudiation | parent cannot tell which care steps happened | low | `care.*` events in the diary (`care.reward`, `care.begin`, `care.complete`, `care.abandon`) |
| **I**nformation disclosure | no new diary writers; components log ids only | low | `Log.event` remains the only writer (T-E01-01 control) |
| **D**enial of service | `CareLoopManager` wedged in a mid-step state locks the hub | medium | every non-IDLE state has a legal edge back to `IDLE` (`abandon_step`); `Fsm` edges reject illegal jumps; `reset()` rebuilds |
| **D**enial of service | production `change_scene_to_file` to a missing scene bricks the app | low | every request is guarded by `ResourceLoader.exists` before `SceneManager.request_scene` |
| **E**levation of privilege | door ids → `res://` paths | low | door table is a const dictionary of literal paths; ids validated by pattern before path construction |

## Kids-specific threats (delta)

| Threat | Mitigation |
|---|---|
| Reward gambling feel | cycle reward is fixed (+5/+1), never random; no wagering UI in e02 |
| Frustration from lost progress mid-cycle | cycle progress is intentionally session-only; `completed_cycles` persists — restarting the app starts a fresh cycle, never a punishment |
| Numerals in HUD misread as text prompts | numerals are decoration next to icons; no interaction requires reading (Zero Text Rule upheld) |

## Findings for e02 implementation (must be closed in-story)

| ID | Finding | Severity | Required action |
|---|---|---|---|
| T-E02-01 | Reward idempotency is the single economy invariant of the epic | HIGH | `test_care_loop_manager.gd` asserts exactly-once per cycle incl. the CELEBRATE→IDLE detour path |
| T-E02-02 | Production scene swap (`e02s04`) must never fire under GUT | HIGH | `SceneManager.set_test_mode(true)` (called by `TestReset`) skips `change_scene_to_file`; unit test asserts `production_swap_path` stays empty in test mode |
| T-E02-03 | `CareLoopManager` must not crash when `ProgressManager` is absent (unit tests without full autoload set) | MED | lazy `get_node_or_null` + `has_method` guard; reward ledger still advances so the grant is not lost |
| T-E02-04 | Idle wish-bubble timer could fire during scene transitions | LOW | bubble state lives in the scene, freed with it; `WishBubble` FSM is per-instance |

## Out of scope (with reason)

- Network exfiltration: no network stack; CI grep control from e01 still applies.
- Wheel ticket spending (`spend_ticket`): e08 surface, not built here.
- Multi-user: single-player local app.

## Verification

```bash
grep -RInE '\b(HTTPRequest|HTTPClient|WebSocketPeer)\b' game/scripts || echo "no network APIs"
godot --headless --path game -s addons/gut/gut_cmdln.gd -gexit   # includes T-E02-01/02 assertions
test -f specs/security/epics/e02/THREAT_MODEL.md
```
