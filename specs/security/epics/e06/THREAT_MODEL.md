# Threat Model — e06 (Sunny Garden, PLAY Scene)

<!-- story: e06s01 -->
**Skill:** `security-review` (build-epic Step 0) · **Date:** 2026-11-06
**Surface:** Godot 4.7 client, 100 % offline, iPadOS + desktop, no accounts, no network.
**Delta over e05:** the first scene whose content is **play, not care** (no single "correct" action),
the first props that **persist a state across the visit** (a ball that keeps bouncing, a pinwheel that
keeps spinning), and the first tickle interaction — a repeated stimulus with no completion condition.

## Assets

| Asset | Why it matters | Where it lives |
|---|---|---|
| Care cycle state | PLAY is the fourth step; a wrong credit skips DRESS or PLAY in the ladder | runtime |
| Coin / ticket counters | the PLAY reward lands here (BUG-007 clamps) | `user://progress.json` |
| Child's play diary | three interactions produce events; a bouncing ball could produce one per frame | device only |
| Expression layer | `pulando`/`rindo` are the feedback; a stuck face is a bug (e04 class) | runtime |
| Scene graph | a garden where nothing responds is worse than no garden | runtime |

## Trust boundaries

1. Engine ↔ filesystem (`user://` only) — unchanged; the garden writes nothing new.
2. Input ↔ scene logic — **new: a repeated stimulus** (tickle) and props that are tapped, not dragged.
3. Data files ↔ runtime — unchanged (`SaveData`, JSONL).
4. `res://` art paths ← const ids (unchanged).
5. **New: scene addition ↔ the hub.** Shipping `jardim.tscn` makes the Casa's PLAY door navigate. This is
   the third time a new scene changed a neighbour (`banheiro` → BATH, `closet` → DRESS); this model names
   it up front instead of rediscovering it in a red test.

## STRIDE

| Category | Threat (concrete) | Likelihood | Mitigation required in e06 |
|---|---|---|---|
| **S**poofing | none: no identity | n/a | none needed |
| **T**ampering | **PLAY credited twice** (three interactions, then a replay) | **high** | `credited` guard + care-state check; replay test (T-E06-01) |
| **T**ampering | **the hub's door table drifts** from the scenes that exist | medium | the door-navigates test is updated with the scene, and only once (T-E06-02) |
| **T**ampering | tampered ids reaching art paths | low | const ids only, `Ids` unchanged |
| **R**epudiation | a parent cannot tell what the child did in the garden | low | one event per interaction, ids only |
| **I**nformation disclosure | a bounce animation writing per-frame events would flood the diary | **medium** | log on interaction only, never per frame (T-E06-03) |
| **D**enial of service | **a prop that never settles**: the ball bounces forever, the pinwheel never stops, and a child cannot leave with a calm screen | medium | each prop has a bounded motion with a rest state; `abort()` on scene exit |
| **D**enial of service | a missing art/audio file stops the scene | low | degrade with a log event, keep playing |
| **D**enial of service | a child is trapped | medium | `HomeButton` → `abandon_step` if uncredited, once |
| **E**levation of privilege | id → path traversal | low | `Ids` is `\A…\z`; consts only |

## Kids-specific threats (delta)

| Threat | Mitigation |
|---|---|
| Nothing signals "you did it" in a sandbox | each of the three interactions fires its own cue (sound + expression + particle), and the third adds the celebration |
| Tickle becomes the only thing the child does, forever | tickle is repeatable **by design** (it is play, not a task) but it neither advances nor blocks the step; the other two props carry the progress |
| A prop moves under the finger and the child loses it | props return to their place with a bounded animation, and remain hit-targets ≥120×120 |
| Play has no goal, so the step never completes | three distinct interactions complete it; the same one repeated does not count twice |

## Findings for e06 implementation (must be closed in-story)

| ID | Finding | Severity | Story | Required action |
|---|---|---|---|---|
| T-E06-01 | PLAY credited exactly once; a repeated interaction does not count twice | **HIGH** | e06s02, e06s03 | distinct-interaction set + `credited` guard; replay test |
| T-E06-02 | Shipping `jardim.tscn` changes the hub's door behaviour | **MED** | e06s02 | update the door test with the scene, assert one request |
| T-E06-03 | No diary line per frame or per bounce | **MED** | e06s01 | events on discrete interactions only |
| T-E06-04 | Every prop settles: a bounce ends, a spin stops | MED | e06s01 | bounded motion with a rest state; test that the prop is idle after `advance` |
| T-E06-05 | Three *distinct* interactions complete the step; the same one thrice does not | **HIGH** | e06s02 | interaction set, not a counter |
| T-E06-06 | Abandon leaves the garden in a calm state (motions stopped, no loop playing) | MED | e06s02 | `abort()`/`reset` on exit; assertion on the props |

## Out of scope (with reason)

- Network: none; the e01 CI grep control gates every PR.
- Economy: PLAY credits through the existing clamps (BUG-007).
- `FREE_PLACEMENT` and furniture: e09.
- Friends/mini-games (duck dance, bear puzzle): e10 — the garden stays a solo sandbox here.
