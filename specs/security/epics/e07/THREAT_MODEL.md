# Threat Model — e07 (Sleep & Celebration scenes) — DRAFT, closes at step 0 of the epic

<!-- story: e07s01 -->
**Skill:** `security-review` (build-epic Step 0) · **Status:** draft written by the adoption audit so the
surface is not unmodelled; **to be completed before e07s01 code**.
**Surface:** Godot 4.7 client, 100 % offline, no accounts, no network.

## Delta over e06

The first epic that **closes a care cycle**, so the reward path becomes reachable for the first time:
`CareLoopManager` walks `SLEEP → CELEBRATE → IDLE` and `ProgressManager.complete_cycle` pays coins,
tickets and increments `completed_cycles`.

## Threats to model

| Category | Threat | Required mitigation |
|---|---|---|
| **T**ampering | **double reward**: `complete_cycle` runs twice for one cycle (scene re-entry, replay, two scenes) | `_rewarded_cycle_id` guard already exists; assert once from the celebration scene |
| **T**ampering | **cycle never closes**: `CELEBRATE` has no `→ IDLE` path in practice, so the next day never starts | explicit closing-edge test; `Fsm` declares it |
| **T**ampering | save written mid-reward, crash between write and increment | atomic `.tmp` rename (ADR-005); reward and counter in one `_apply` |
| **I**nformation disclosure | celebration reveals counts only; no new PII surface | ids and numbers only in the diary |
| **D**enial of service | a celebration that never ends traps the child | bounded animation + `HomeButton` → `abandon_step` semantics (no step to abandon here) |
| **D**enial of service | lamp toggle stuck off in SLEEP so the room reads as broken | toggle is idempotent; test both states |
| **E**levation | none: no ids from disk feed a path in these scenes | unchanged `Ids` contract |

## Kids-specific

| Threat | Mitigation |
|---|---|
| Night room too dark to see the character | `night_slumber_tint` on the canvas only, never on the rig |
| Reward explained by text | art + PT-BR voice only; sticker/coin art carries it |
| Celebration noise startles | one confetti burst, one voice clip, music crossfades rather than cutting |
