# Threat Model — e07 (Bedroom Sleep + Celebration, closing the care cycle)

<!-- story: e07s01 -->
**Skill:** `security-review` (build-epic Step 0) · **Date:** 2026-11-06
**Surface:** Godot 4.7 client, 100 % offline, no accounts, no network.
**Delta over e06:** the first epic that **closes a care cycle** — the reward path becomes reachable for the
first time — and the first that can be entered by **detour** from another room, so a child can leave
`CELEBRATE` down a side door.

## Assets

| Asset | Why it matters | Where |
|---|---|---|
| Coin / ticket counters | the cycle reward lands here; a double pay is a real economy bug | `user://progress.json` |
| `completed_cycles` | drives the day counter and the celebration eligibility | same file |
| Care cycle state | a cycle that never closes bricks the Casa: every door refuses | runtime |
| Child's diary | two new event families (`sleep.*`, `celebrate.*`) | device only |

## Trust boundaries

1. Engine ↔ filesystem (`user://`): **new risk** — reward *and* counter in one write.
2. Input ↔ logic: lamp toggle, plush tuck, detour doors.
3. Data ↔ runtime: clamps from BUG-007 are the only guards on the reward.
4. Scene table ↔ navigation: `casa.gd` gains two more doors that now navigate.
5. **New: detour ↔ cycle state.** Any scene request made during `CELEBRATE` must not leave the loop
   mid-cycle.

## STRIDE

| Category | Threat | Likelihood | Mitigation required in e07 |
|---|---|---|---|
| **T**ampering | **double reward**: two entries in the same cycle both pay | **high** | `_rewarded_cycle_id` guard already exists; the scene must assert it, not assume it (T-E07-03) |
| **T**ampering | **credit without reward**: `completed_cycles` increments but the reward write fails | medium | one `_apply` for coins+tickets+cycles, then one save (T-E07-04) |
| **T**ampering | **cycle never closes**: leaving `CELEBRATE` by a detour leaves the loop stuck, so no door ever opens again | **high** | `close_celebrate_if_needed()` on any non-Casa request while in `CELEBRATE` (T-E07-05) |
| **T**ampering | SLEEP credited twice by toggling the lamp again | medium | `credited` guard + `fsm.transition_from(SLEEPING, FINISHED)`, and the lamp is inert once `FINISHED` (T-E07-02) |
| **I**nformation disclosure | celebration prints counts; nothing personal | low | numbers and ids only |
| **D**enial of service | night tint applied to the rig makes the character unreadable | medium | tint the background only (T-E07-01) |
| **D**enial of service | zzz particles keep emitting after leaving | low | `HomeButton` stops them; asserted |
| **D**enial of service | confetti loops | low | one-shot burst, restart on entry only |
| **E**levation | none: no ids from disk in these scenes | n/a | unchanged |

## Kids-specific

| Threat | Mitigation |
|---|---|
| Room too dark to see her | tint the background, never the rig; the face keeps contrast |
| Reward is explained by text | voice + coin/ticket art, no `Label` |
| Celebration is scary-loud | one burst, one voice clip, music continues rather than restarting |
| Tucking in twice restarts the animation and startles | idempotent tuck |

## Findings for implementation

| ID | Finding | Severity | Story |
|---|---|---|---|
| T-E07-01 | Night tint must not touch the rig | MED | e07s01 |
| T-E07-02 | SLEEP credited once, only from SLEEP | **HIGH** | e07s01 |
| T-E07-03 | Reward paid once per cycle | **HIGH** | e07s02 |
| T-E07-04 | Reward atomic with `completed_cycles` | MED | e07s02 |
| T-E07-05 | Detour during CELEBRATE never bricks the hub | **HIGH** | e07s03 |
| T-E07-06 | The whole cycle runs once, clean, on both canvases | MED | e07s04 |

## Out of scope

- Network (none; CI grep control).
- Save schema changes: the reward uses existing fields and clamps (BUG-007).
- Sticker album / vila content: they are detour *targets* only, not implemented here.

## Post-epic review addendum (2026-11-06)

Two mitigations in this table were **aspirational when written** and were made true by the e07 post-epic
review, not by the epic itself: the reward being written to disk (it was not, T-E07-04) and the music
continuing instead of restarting (both new scenes restarted it). The scene now asserts the ledger, the
bedroom's lamp is inert once `FINISHED`, and the hub closes a celebration it arrives inside. Details:
`specs/verifications/POSTEPIC-e07-2026-11-06.md`.

**T-E07-03 scope, stated exactly:** once per cycle **per session**. The ledger is in memory
(`CareLoopManager._rewarded_cycle_id`), `ProgressManager` has no per-cycle guard, and `reset()` replays a
cycle — test-only. See [ADR-009](../../adr/ADR-009-care-cycle-money-dwell-and-voice-gaps.md).
