# Threat Model — e04 (Bathroom BATH Scene)

<!-- story: e04s01 -->
**Skill:** `security-review` (build-epic Step 0) · **Date:** 2026-11-05
**Surface:** Godot 4.7 client, 100 % offline, iPadOS + desktop, no accounts, no network.
**Delta over e03:** the first **continuous** gesture (`CONTINUOUS_SCRUB`, many events per second),
the first **region** target (a `ScrubHull` polygon in rig-local space rather than a point or a box),
the first **three-stage** sequence inside one scene (SOAP → RINSE → DRY), and the first **continuous
audio** loop (a scrub sound that can outlive the gesture).

## Assets

| Asset | Why it matters | Where it lives |
|---|---|---|
| Care cycle state | BATH must complete exactly once, or the ladder and the reward drift | runtime |
| Coin / ticket counters | the BATH reward lands here; a double award breaks the economy | `user://progress.json` |
| Child's play diary | a per-motion scrub event would flood it with coordinates | device only |
| The 8-channel SFX pool | a continuous scrub loop can starve voice ducking and every other cue | runtime |
| Scene graph | a stage machine stuck between SOAP and RINSE is a dead end for a child who cannot read | runtime |

## Trust boundaries (unchanged from e03, plus one)

1. Engine ↔ filesystem (`user://` only).
2. Input ↔ game logic — **now including a continuous gesture**, and a gesture that can be interrupted
   at any point.
3. Data files ↔ runtime (`SaveData`, JSONL).
4. Scene table ↔ navigation (`banheiro.gd` uses one const path).
5. **New: rig-local geometry ↔ global screen.** `ScrubHull` is authored in rig-local coordinates and
   the rig resizes per aspect (ADR-008, and BUG-013 made the box follow the *opaque* art). Every hull
   check is therefore a coordinate transform, and a wrong transform is invisible at 16:9.

## STRIDE

| Category | Threat (concrete) | Likelihood | Mitigation required in e04 |
|---|---|---|---|
| **S**poofing | none: no identity, no accounts | n/a | none needed |
| **T**ampering | **hull drift on resize**: `ScrubHull` is local-space, the rig box now changes with the canvas (BUG-013). A stale hull either lets foam escape her body on 4:3 or rejects valid scrubs on 16:9 | **high** | hull derived from the rig's **opaque** rect every layout pass; containment asserted by `GeometryOracle` on both aspects (T-E04-01) |
| **T**ampering | **stage skipping / double advance**: RINSE before SOAP, DRY twice, BATH completing twice | medium | one `Fsm` for the stage machine with legal edges only; `complete_step` once; second-visit test with a clean `FsmProbe` (T-E04-02) |
| **T**ampering | tampered art or `.tres` in a repackaged build | low | same trust level as the code; ids validated by `Ids.is_valid` before any path is built |
| **R**epudiation | a parent cannot tell whether BATH happened | low | `care.begin` / `care.complete` / `care.abandon` already logged; stage transitions log stage names only |
| **I**nformation disclosure | a per-motion scrub event would put high-frequency input coordinates in the diary | **medium** | log on scrub start, stage change and completion only — never per motion (T-E04-03) |
| **D**enial of service | **gesture wedge**: `CONTINUOUS_SCRUB` shares the single-finger owner latch with `CONSUME_ON_DROP`; a scrub whose release is missed blocks every later drag in the scene | **high** | owner released on release, `_exit_tree`, and on stage change; release tracked by touch index (T-E04-04) |
| **D**enial of service | **SFX pool starvation**: a looping scrub sound holds a channel for the whole gesture, and the pool is 8 channels with voice ducking | medium | scrub loop is a single owned player that stops on release; voice ducking wins over it (T-E04-05) |
| **D**enial of service | a missing art/audio file stops the stage | low | same degradation pattern as e03: log and keep the scene playable |
| **D**enial of service | a child is trapped in the bathroom | medium | `HomeButton` → `abandon_step`, guarded to fire once, and it resets the stage FSM and stops particles/loops (T-E04-06) |
| **E**levation of privilege | art id → `res://` path traversal via a tampered save | low | `Ids` is `\A…\z` (BUG-013 fix); hall paths are consts, never built from input |

## Kids-specific threats (delta)

| Threat | Mitigation |
|---|---|
| Scrubbing feels unresponsive: the child rubs and nothing happens | foam blob disappears on the first crossing of its own hit area, not at the end of the gesture |
| The scrub region is smaller than it looks (hull inside the art) | hull derived from the opaque art rect, with a margin grown outward, asserted by the oracle on both aspects |
| A towelling gesture leaves her face stuck (BUG-005 class) | DRY restores the previous expression on release, not only on completion |
| Three stages read as three chores | one visible goal (foam on body → foam gone) carried by art and voice, no text |
| Water particles + scrub loop overload a 4-year-old's attention | one particle emitter per stage, one loop at a time |

## Findings for e04 implementation (must be closed in-story)

| ID | Finding | Severity | Story | Required action |
|---|---|---|---|---|
| T-E04-01 | `ScrubHull` must be derived from the rig's opaque rect each layout pass, or containment drifts per aspect | **HIGH** | e04s01, e04s02 | hull recomputed on `NOTIFICATION_RESIZED`; containment asserted at 1920×1080 and 2048×1536 |
| T-E04-02 | Stage machine must not skip, repeat or double-complete BATH | **HIGH** | e04s02, e04s03, e04s04 | legal edges only; `complete_step("BATH")` exactly once; second-visit test |
| T-E04-03 | No diary line per scrub motion | **MED** | e04s01 | events on scrub start / stage change / completion only |
| T-E04-04 | Scrub and drop must not wedge the shared finger owner | **HIGH** | e04s01 | release on release, `_exit_tree`, stage change; free-mid-gesture test |
| T-E04-05 | Continuous scrub sound must not hold a channel past the gesture or beat voice ducking | MED | e04s01, e04s02 | one owned loop player, stopped on release; ducking priority |
| T-E04-06 | Abandon mid-stage must reset the stage FSM, stop particles and the loop | MED | e04s03 | `HomeButton` path tested with the FSM probe attached |
| T-E04-07 | Foam blobs must stay inside the hull across a resize mid-stage | MED | e04s02, e04s04 | blobs re-solved against the new hull, or the stage restarts cleanly; oracle asserts containment |

## Out of scope (with reason)

- Network exfiltration: no network stack; the e01 CI grep control still applies and gates every PR.
- Save-schema changes: e04 awards through the existing counters (`MAX_COINS`/`MAX_TICKETS` clamps from BUG-007).
- `SNAP_TO_SLOT` and `FREE_PLACEMENT`: e06 and e09.
- Multi-touch arcs beyond the existing single-owner contract: two simultaneous scrubs are out of
  scope for a 4–7-year-old target; the owner latch makes the second a no-op, which is the safe failure.
