# ADR-009: The care cycle's money, celebration dwell and the missing bedtime voice

<!-- story: e07s01 -->
<!-- story: e07s02 -->
<!-- story: e07s03 -->

- **Status:** Accepted
- **Date:** 2026-11-06
- **Recorded by:** e07 post-epic review (deliberate trade-offs, not silent skips)
- **Relates to:** BUG-019, BUG-020, BUG-027, BUG-031, `specs/security/epics/e07/THREAT_MODEL.md` (T-E07-03/04)

## Context

The e07 post-epic review found behaviours that were either not defects or not documented. Three were
deliberate trade-offs; two (the short celebration and the missing reward reveal) were real defects and
were fixed in the same pass.

## Decision

1. **The ledger stays in `CareLoopManager`; it is per-session and documented as such.** The celebration
   does not read `_rewarded_cycle_id` (it only knows `credited_cycle`, its own once-per-mount latch).
   `celebracao.gd`'s docstring no longer claims that `ProgressManager` refuses a second payment for the
   same cycle — it does not, and the manager's transition-into-`CELEBRATE` is the single owner of money.
   A persisted per-cycle guard is **not** introduced: it would require a `SaveData` schema change
   (ADR-005 amendment + migration) to defend a path that does not exist outside tests.

2. **The short celebration was a defect and is fixed (BUG-031).** `CelebrationScene` closed the cycle
   and called `_leave()` in `_ready`, so the party lasted roughly one 0.4 s fade and
   `celebrate_parabens.ogg` was cut by the transition. It now holds `HOLD_SEC = 1.8` before `_leave()`,
   driven by the scene's own `advance()` clock, and reveals the reward while it holds. The e07s02
   acceptance criteria and frozen contract are updated to say so.

3. **The bedroom has no voice line.** Every other care room opens with a family voice prompt
   (`feed_hora_de_comer`, `bath_hora_do_banho`, `dress_vamos_se_arrumar`, `play_hora_de_brincar`).
   `game/assets/audio/voice/` has no bedtime clip, and inventing one is impossible offline: the
   project's standing rule is family-recorded PT-BR, never TTS. The room answers with shipped SFX —
   `tap.ogg` on the lamp, `drop.ogg` on the tuck, `success.ogg` when the step is credited (BUG-020) —
   and stays silent-but-not-mute until the family records a line.

4. **Rig dressing outside the closet is out of e07's written scope.** `ProgressManager.dress()` has one
   caller (`ClosetScene`), so the bedroom and the celebration show the neutral rig instead of the outfit
   the child chose. Adding it here would change two stories' acceptance criteria; it becomes a story in
   a later epic (the celebration is where she looks at herself, so it belongs with the album/party work).

5. **The per-scene `_play_stream` / `_leave` twins stay.** `SleepScene` and `CelebrationScene` each carry
   their own small audio and navigation helpers, as every room since e03 does. The shared infrastructure
   that *is* genuinely shared was already extracted once (BUG-010); collapsing six rooms' private
   helpers into a base class is a refactor with no user-visible effect and no failing gate, so it is not
   smuggled into a review pass.

6. **The celebration did not display the reward — fixed (BUG-031).** `IMPACT_LATEST.md` planned a
   "reward reveal" and `DESIGN_PLAN_LATEST.md` lists the coin/star art for it; e07s02's acceptance
   criteria and frozen `celebracao.tscn` contract did not include one. BUG-031 now implements it: a
   `Coin` (`moedinha.png`) and a `Ticket` (`roda_fortuna.png`) pop in at the head line during the hold,
   and the frozen spec is updated to match. The planned `estrela.png` became `roda_fortuna.png` because
   the reward is +1 *wheel ticket*, not a star, and `roda_fortuna.png` is what the HUD already shows.

## Consequences

- The threat model's T-E07-03 mitigation is accurate only as "paid once per cycle **per session**".
  `AUDIT-e07-epic.md` and the threat model are corrected to say so.
- The reward reveal and the hold are implemented (BUG-031); a recorded bedtime line and rig dressing
  still have a named home and are not surprises inside e08.
